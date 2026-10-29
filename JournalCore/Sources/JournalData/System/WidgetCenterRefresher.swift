import JournalDomain
import WidgetKit

/// Asks WidgetKit to reload the journal widget's timelines.
public struct WidgetCenterRefresher: WidgetRefresher {
    public init() {}

    public func reloadAll() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// No-op refresher/scheduler for previews and the widget process.
public struct NoopWidgetRefresher: WidgetRefresher {
    public init() {}
    public func reloadAll() {}
}

public struct NoopReminderScheduler: ReminderScheduler {
    public init() {}
    public func authorizationStatus() async -> ReminderAuthorization { .denied }
    public func requestAuthorization() async -> Bool { false }
    public func replacePending(with reminders: [ScheduledReminder]) async {}
}
