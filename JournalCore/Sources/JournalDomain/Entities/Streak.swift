import Foundation

public enum StreakStatus: Equatable, Sendable {
    /// Current streak is 0.
    case none
    /// The streak runs through today, or through yesterday while today is still open.
    case active
    /// Yesterday is missing and backfilling it before `until` restores a run of `restorableCount` days.
    case atRisk(restorableCount: Int, until: Date)
}

public struct StreakSummary: Equatable, Sendable {
    public let current: Int
    public let best: Int
    public let status: StreakStatus
    public let isTodayDone: Bool

    public init(current: Int, best: Int, status: StreakStatus, isTodayDone: Bool) {
        self.current = current
        self.best = best
        self.status = status
        self.isTodayDone = isTodayDone
    }

    public static let empty = StreakSummary(current: 0, best: 0, status: .none, isTodayDone: false)
}
