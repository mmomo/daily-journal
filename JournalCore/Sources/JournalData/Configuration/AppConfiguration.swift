import Foundation

/// Identifiers and feature flags shared by the app and widget.
///
/// Values come from the host bundle's Info.plist (set by Tuist from `AppIdentifiers.swift`),
/// with defaults matching the project identifiers so tests and previews work without a bundle.
public struct AppConfiguration: Sendable, Equatable {
    public static let appGroupKey = "JournalAppGroupIdentifier"
    public static let iCloudContainerKey = "JournalICloudContainerIdentifier"
    public static let cloudKitEnabledKey = "JournalCloudKitEnabled"

    public let appGroupIdentifier: String
    public let iCloudContainerIdentifier: String
    /// CloudKit sync is opt-in: it requires a signed build with the iCloud entitlement (Q4:A).
    public let cloudKitEnabled: Bool

    public init(
        appGroupIdentifier: String = "group.com.mmomo.dailyjournal",
        iCloudContainerIdentifier: String = "iCloud.com.mmomo.dailyjournal",
        cloudKitEnabled: Bool = false
    ) {
        self.appGroupIdentifier = appGroupIdentifier
        self.iCloudContainerIdentifier = iCloudContainerIdentifier
        self.cloudKitEnabled = cloudKitEnabled
    }

    /// Reads the configuration from `bundle`'s Info.plist, falling back to defaults.
    public static func fromBundle(_ bundle: Bundle = .main) -> AppConfiguration {
        let defaults = AppConfiguration()
        func string(_ key: String) -> String? {
            (bundle.object(forInfoDictionaryKey: key) as? String).flatMap { $0.isEmpty ? nil : $0 }
        }
        let enabled: Bool = switch bundle.object(forInfoDictionaryKey: cloudKitEnabledKey) {
        case let value as Bool: value
        case let value as String: ["yes", "true", "1"].contains(value.lowercased())
        case let value as NSNumber: value.boolValue
        default: false
        }
        return AppConfiguration(
            appGroupIdentifier: string(appGroupKey) ?? defaults.appGroupIdentifier,
            iCloudContainerIdentifier: string(iCloudContainerKey) ?? defaults.iCloudContainerIdentifier,
            cloudKitEnabled: enabled
        )
    }

    /// The shared App Group container, or `nil` when the entitlement is missing (unsigned builds).
    public var appGroupContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    /// App Group defaults, falling back to `.standard` when the App Group is unavailable.
    public func sharedDefaults() -> UserDefaults {
        guard appGroupContainerURL != nil, let suite = UserDefaults(suiteName: appGroupIdentifier) else {
            return .standard
        }
        return suite
    }

    /// Directory for the SwiftData store: the App Group container, or Application Support as a fallback.
    public func storeDirectory() throws -> URL {
        if let group = appGroupContainerURL {
            return group.appending(path: "Library/Application Support", directoryHint: .isDirectory)
        }
        return try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
    }
}
