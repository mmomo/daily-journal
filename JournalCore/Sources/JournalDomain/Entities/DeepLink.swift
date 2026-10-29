import Foundation

/// Typed app routes shared by the widget, notifications and the app.
public enum DeepLink: String, CaseIterable, Equatable, Sendable {
    case todayEditor = "today"
    case backfillEditor = "backfill"

    /// Must match the URL scheme registered in the app's Info.plist (Tuist `AppIdentifiers`).
    public static let scheme = "dailyjournal"

    public var url: URL {
        URL(string: "\(DeepLink.scheme)://\(rawValue)")!
    }

    /// Accepts only the `dailyjournal` scheme with a known host; query and fragment are ignored.
    public init?(url: URL) {
        guard url.scheme?.lowercased() == DeepLink.scheme,
              let host = url.host()?.lowercased(),
              let link = DeepLink(rawValue: host)
        else { return nil }
        self = link
    }
}
