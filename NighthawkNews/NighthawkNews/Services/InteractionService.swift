import Foundation
import UIKit
import Combine

/// Batches user interaction signals and flushes them to the backend.
///
/// Signals are queued in-memory and persisted to disk (crash resilience).
/// The queue flushes automatically:
///   - Every 60 seconds while the app is active
///   - When the app moves to background
///
/// Explicit likes and bookmarks are queued directly by callers.
/// Dwell-based signals are queued by `DwellTracker`.
@MainActor
final class InteractionService: ObservableObject {
    static let shared = InteractionService()

    private static let flushInterval: TimeInterval = 60
    private static let fileName = "pending_interactions.json"

    private var pending: [PendingInteraction] = []
    private var flushTask: Task<Void, Never>?
    private var backgroundObserver: Any?
    private var saveGeneration = 0

    private init() {
        loadFromDisk()
        startFlushLoop()
        observeBackground()
    }

    // MARK: - Queue an interaction

    func queue(articleID: UUID, interaction: String, dwellMs: Int = 0) {
        let item = PendingInteraction(
            articleID: articleID.uuidString,
            interaction: interaction,
            dwellMs: dwellMs,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
        pending.append(item)
        saveToDisk()
    }

    // MARK: - Flush to backend

    func flush() async {
        guard !pending.isEmpty else { return }

        let userID = UserDefaults.standard.string(forKey: "NEWSHAWK_USER_ID") ?? "anonymous"
        let batch = pending
        pending.removeAll()
        saveToDisk()

        do {
            try await sendToBackend(userID: userID, interactions: batch)
        } catch {
            // Re-queue on failure so we don't lose signals
            pending.insert(contentsOf: batch, at: 0)
            saveToDisk()
            print("[InteractionService] flush failed: \(error)")
        }
    }

    // MARK: - Network

    private func sendToBackend(userID: String, interactions: [PendingInteraction]) async throws {
        let baseURL = NewsService.baseURL
        guard let url = URL(string: "\(baseURL)/interactions") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "user_id": userID,
            "interactions": interactions.map { ix in
                [
                    "article_id": ix.articleID,
                    "interaction": ix.interaction,
                    "dwell_ms": ix.dwellMs,
                    "timestamp": ix.timestamp,
                ] as [String: Any]
            },
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Flush loop

    private func startFlushLoop() {
        flushTask?.cancel()
        flushTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.flushInterval))
                if Task.isCancelled { break }
                await flush()
            }
        }
    }

    private func observeBackground() {
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            var bgTask: UIBackgroundTaskIdentifier = .invalid
            bgTask = UIApplication.shared.beginBackgroundTask(withName: "InteractionFlush") {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = .invalid
            }
            Task { @MainActor in
                await self.flush()
                if bgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(bgTask)
                }
            }
        }
    }

    // MARK: - Disk persistence

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(fileName)
    }

    private func saveToDisk() {
        saveGeneration += 1
        let generation = saveGeneration
        let dataToSave = pending
        let url = Self.fileURL
        Task.detached(priority: .background) {
            await PendingInteractionDiskWriter.shared.save(
                dataToSave,
                generation: generation,
                to: url
            )
        }
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let loaded = try? JSONDecoder().decode([PendingInteraction].self, from: data)
        else { return }
        pending = loaded
    }
}

// MARK: - Pending interaction model

private struct PendingInteraction: Codable, Sendable {
    let articleID: String
    let interaction: String
    let dwellMs: Int
    let timestamp: String
}

private actor PendingInteractionDiskWriter {
    static let shared = PendingInteractionDiskWriter()

    private var latestGeneration = 0

    func save(_ pending: [PendingInteraction], generation: Int, to url: URL) {
        guard generation >= latestGeneration else { return }
        latestGeneration = generation

        do {
            let data = try JSONEncoder().encode(pending)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[InteractionService] save failed: \(error)")
        }
    }
}
