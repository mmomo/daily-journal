import JournalData
import JournalDomain
import UIKit
import UserNotifications

/// Shows reminders while the app is open and routes notification taps to the editor (US-6.3).
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    /// Set by `JournalApp`. Links that arrive earlier (cold launch from a notification) are buffered.
    var onDeepLink: ((DeepLink) -> Void)? {
        didSet {
            if let link = bufferedLink, let onDeepLink {
                bufferedLink = nil
                onDeepLink(link)
            }
        }
    }

    private var bufferedLink: DeepLink?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let link = ReminderRequestBuilder.deepLink(from: response.notification.request.content.userInfo) else { return }
        await deliver(link)
    }

    @MainActor
    private func deliver(_ link: DeepLink) {
        if let onDeepLink {
            onDeepLink(link)
        } else {
            bufferedLink = link
        }
    }
}
