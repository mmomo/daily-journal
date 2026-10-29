import ProjectDescription
import ProjectDescriptionHelpers

private var appInfoPlist: [String: Plist.Value] {
    var info: [String: Plist.Value] = [
        "CFBundleDisplayName": .string(AppIdentifiers.displayName),
        "CFBundleShortVersionString": "$(MARKETING_VERSION)",
        "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
        "UILaunchScreen": .dictionary([:]),
        "UISupportedInterfaceOrientations": .array(["UIInterfaceOrientationPortrait"]),
        "CFBundleURLTypes": .array([
            .dictionary([
                "CFBundleURLName": .string(AppIdentifiers.appBundleID),
                "CFBundleURLSchemes": .array([.string(AppIdentifiers.urlScheme)]),
            ]),
        ]),
    ]
    if AppIdentifiers.isSigningConfigured {
        info["UIBackgroundModes"] = .array(["remote-notification"]) // CloudKit push
    }
    return info.merging(AppIdentifiers.configurationInfoPlist) { $1 }
}

private var widgetInfoPlist: [String: Plist.Value] {
    let info: [String: Plist.Value] = [
        "CFBundleDisplayName": .string(AppIdentifiers.displayName),
        "CFBundleShortVersionString": "$(MARKETING_VERSION)",
        "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
        "NSExtension": .dictionary([
            "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
        ]),
    ]
    return info.merging(AppIdentifiers.configurationInfoPlist) { $1 }
}

let project = Project(
    name: "DailyJournal",
    organizationName: "mmomo",
    packages: [
        .local(path: "JournalCore"),
    ],
    settings: .settings(base: [
        "SWIFT_VERSION": "6.0",
        "MARKETING_VERSION": "1.0",
        "CURRENT_PROJECT_VERSION": "1",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    ]),
    targets: [
        .target(
            name: "JournalApp",
            destinations: [.iPhone],
            product: .app,
            bundleId: AppIdentifiers.appBundleID,
            deploymentTargets: .iOS(AppIdentifiers.deploymentTarget),
            infoPlist: .extendingDefault(with: appInfoPlist),
            sources: ["JournalApp/Sources/**"],
            resources: ["JournalApp/Resources/**"],
            entitlements: AppIdentifiers.isSigningConfigured ? .file(path: "JournalApp/JournalApp.entitlements") : nil,
            dependencies: [
                .package(product: "JournalDomain"),
                .package(product: "JournalData"),
                .target(name: "JournalWidget"),
            ],
            settings: .settings(base: AppIdentifiers.signingSettings)
        ),
        .target(
            name: "JournalWidget",
            destinations: [.iPhone],
            product: .appExtension,
            bundleId: AppIdentifiers.widgetBundleID,
            deploymentTargets: .iOS(AppIdentifiers.deploymentTarget),
            infoPlist: .extendingDefault(with: widgetInfoPlist),
            sources: ["JournalWidget/Sources/**"],
            resources: ["JournalWidget/Resources/**"],
            entitlements: AppIdentifiers.isSigningConfigured ? .file(path: "JournalWidget/JournalWidget.entitlements") : nil,
            dependencies: [
                .package(product: "JournalDomain"),
                .package(product: "JournalData"),
            ],
            settings: .settings(base: AppIdentifiers.signingSettings)
        ),
    ]
)
