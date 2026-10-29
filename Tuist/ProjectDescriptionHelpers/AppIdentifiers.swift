import ProjectDescription

/// Single source of truth for every identifier in the project (Q3:B).
public enum AppIdentifiers {
    public static let appBundleID = "com.mmomo.dailyjournal"
    public static let widgetBundleID = "com.mmomo.dailyjournal.widget"
    public static let appGroup = "group.com.mmomo.dailyjournal"
    public static let iCloudContainer = "iCloud.com.mmomo.dailyjournal"
    public static let urlScheme = "dailyjournal"
    public static let displayName = "Daily Journal"
    public static let deploymentTarget = "17.0"

    /// Apple Developer Team ID. Leave empty for unsigned simulator builds (Q4:A).
    /// Setting it enables the App Group + iCloud entitlements and CloudKit sync.
    public static let developmentTeam = ""

    public static var isSigningConfigured: Bool { !developmentTeam.isEmpty }

    /// Info.plist keys read by `AppConfiguration` in JournalData.
    public static var configurationInfoPlist: [String: Plist.Value] {
        [
            "JournalAppGroupIdentifier": .string(appGroup),
            "JournalICloudContainerIdentifier": .string(iCloudContainer),
            "JournalCloudKitEnabled": .boolean(isSigningConfigured),
        ]
    }

    /// Build settings for signing; empty when no team is configured.
    public static var signingSettings: SettingsDictionary {
        guard isSigningConfigured else { return [:] }
        return [
            "DEVELOPMENT_TEAM": .string(developmentTeam),
            "CODE_SIGN_STYLE": "Automatic",
        ]
    }
}
