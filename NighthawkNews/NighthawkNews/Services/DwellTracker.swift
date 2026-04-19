import Foundation
import UIKit

/// Tracks how long a user dwells on each article and classifies the signal.
///
/// Usage: call `startTracking(id)` on appear, `stopTracking(id)` on disappear.
/// The tracker records dwell time and queues the resulting interaction signal
/// via `InteractionService`.
@MainActor
final class DwellTracker: ObservableObject {
    static let shared = DwellTracker()

    /// Active timers keyed by article ID.
    private var startTimes: [UUID: Date] = [:]

    /// Paused accumulated durations keyed by article ID.
    private var pausedDurations: [UUID: TimeInterval] = [:]

    private var backgroundObserver: Any?
    private var foregroundObserver: Any?

    private init() {
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseAll()
        }

        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeAll()
        }
    }

    private func pauseAll() {
        let now = Date()
        for (id, start) in startTimes {
            let elapsed = now.timeIntervalSince(start)
            pausedDurations[id, default: 0] += elapsed
        }
        startTimes.removeAll()
    }

    private func resumeAll() {
        let now = Date()
        for id in pausedDurations.keys {
            startTimes[id] = now
        }
    }

    /// Begin tracking dwell time for an article.
    func startTracking(_ articleID: UUID) {
        startTimes[articleID] = Date()
    }

    /// Stop tracking and classify the dwell into an interaction signal.
    /// Returns the classified interaction type and dwell duration in ms,
    /// or nil if tracking was never started for this ID.
    @discardableResult
    func stopTracking(_ articleID: UUID) -> (interaction: String, dwellMs: Int)? {
        let pausedDuration = pausedDurations.removeValue(forKey: articleID) ?? 0
        let start = startTimes.removeValue(forKey: articleID)

        guard start != nil || pausedDuration > 0 else { return nil }

        var dwellSeconds: TimeInterval = pausedDuration
        if let start {
            dwellSeconds += -start.timeIntervalSinceNow
        }
        let dwellMs = Int(dwellSeconds * 1000)

        let interaction: String
        switch dwellSeconds {
        case ..<3:
            interaction = "skip"
        case 3..<10:
            interaction = "view"
        case 10..<30:
            interaction = "read"
        default:
            interaction = "long_read"
        }

        InteractionService.shared.queue(
            articleID: articleID,
            interaction: interaction,
            dwellMs: dwellMs
        )

        return (interaction, dwellMs)
    }
}
