import Foundation

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

    private init() {}

    /// Begin tracking dwell time for an article.
    func startTracking(_ articleID: UUID) {
        startTimes[articleID] = Date()
    }

    /// Stop tracking and classify the dwell into an interaction signal.
    /// Returns the classified interaction type and dwell duration in ms,
    /// or nil if tracking was never started for this ID.
    @discardableResult
    func stopTracking(_ articleID: UUID) -> (interaction: String, dwellMs: Int)? {
        guard let start = startTimes.removeValue(forKey: articleID) else { return nil }
        let dwellSeconds = -start.timeIntervalSinceNow
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
