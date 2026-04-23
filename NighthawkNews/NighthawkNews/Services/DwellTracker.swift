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

    enum Context: Hashable {
        case feed
        case detail
    }

    private struct TrackingKey: Hashable {
        let articleID: UUID
        let context: Context
    }

    /// Active timers keyed by article ID.
    private var startTimes: [TrackingKey: Date] = [:]

    /// Paused accumulated durations keyed by article ID.
    private var pausedDurations: [TrackingKey: TimeInterval] = [:]

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
        for key in pausedDurations.keys {
            startTimes[key] = now
        }
    }

    /// Begin tracking dwell time for an article.
    func startTracking(_ articleID: UUID, context: Context) {
        let key = TrackingKey(articleID: articleID, context: context)
        guard startTimes[key] == nil else { return }
        startTimes[key] = Date()
    }

    /// Stop tracking and classify the dwell into an interaction signal.
    /// Returns the classified interaction type and dwell duration in ms,
    /// or nil if tracking was never started for this ID.
    @discardableResult
    func stopTracking(_ articleID: UUID, context: Context) -> (interaction: String, dwellMs: Int)? {
        let key = TrackingKey(articleID: articleID, context: context)
        let pausedDuration = pausedDurations.removeValue(forKey: key) ?? 0
        let start = startTimes.removeValue(forKey: key)

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
