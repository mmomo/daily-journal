import Foundation
import JournalDomain
import UserNotifications

/// `ReminderScheduler` backed by `UNUserNotificationCenter` (US-6.1, BR-R1–R5).
public final class UserNotificationReminderScheduler: ReminderScheduler, @unchecked Sendable {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func authorizationStatus() async -> ReminderAuthorization {
        ReminderRequestBuilder.authorization(from: await center.notificationSettings().authorizationStatus)
    }

    public func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    public func replacePending(with reminders: [ScheduledReminder]) async {
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(ReminderRequestBuilder.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        for reminder in reminders {
            try? await center.add(ReminderRequestBuilder.request(for: reminder, timeZone: .autoupdatingCurrent))
        }
    }
}

/// Pure mapping from domain reminders to notification requests (unit-testable).
public enum ReminderRequestBuilder {
    public static let identifierPrefix = "reminder-"
    public static let deepLinkKey = "deepLink"

    public static func request(for reminder: ScheduledReminder, timeZone: TimeZone) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        content.userInfo = [deepLinkKey: reminder.deepLink.url.absoluteString]

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        // Wall-clock components (no time zone) so the reminder follows the device's local time.
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
    }

    /// The deep link carried by a delivered notification, if any.
    public static func deepLink(from userInfo: [AnyHashable: Any]) -> DeepLink? {
        (userInfo[deepLinkKey] as? String).flatMap(URL.init(string:)).flatMap(DeepLink.init(url:))
    }

    static func authorization(from status: UNAuthorizationStatus) -> ReminderAuthorization {
        switch status {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized, .provisional: .authorized
        #if os(iOS)
        case .ephemeral: .authorized
        #endif
        @unknown default: .denied
        }
    }
}
