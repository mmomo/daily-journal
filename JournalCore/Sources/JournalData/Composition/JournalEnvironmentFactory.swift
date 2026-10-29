import Foundation
import JournalDomain
import SwiftData

/// Everything a process needs: the wired use cases and the SwiftData container behind them.
public struct JournalEnvironment: Sendable {
    public let useCases: JournalUseCases
    public let modelContainer: ModelContainer
    public let configuration: AppConfiguration
}

/// Composition root: wires Domain ports to Data implementations (component-dependency.md).
public enum JournalEnvironmentFactory {
    /// Production wiring for the app or the widget.
    public static func make(
        for context: PersistenceContext,
        configuration: AppConfiguration = .fromBundle(),
        time: any TimeSource = SystemTimeSource()
    ) throws -> JournalEnvironment {
        let container = try PersistenceController.makeContainer(for: context, configuration: configuration)
        let defaults = configuration.sharedDefaults()
        let reminders: any ReminderScheduler = context == .app ? UserNotificationReminderScheduler() : NoopReminderScheduler()
        let widgets: any WidgetRefresher = context == .app ? WidgetCenterRefresher() : NoopWidgetRefresher()
        return try wire(
            container: container, defaults: defaults, configuration: configuration,
            time: time, reminders: reminders, widgets: widgets
        )
    }

    /// In-memory wiring for SwiftUI previews and tests. Uses a throwaway `UserDefaults` suite.
    public static func makeInMemory(
        time: any TimeSource = SystemTimeSource(),
        reminders: any ReminderScheduler = NoopReminderScheduler(),
        widgets: any WidgetRefresher = NoopWidgetRefresher()
    ) throws -> JournalEnvironment {
        let configuration = AppConfiguration()
        let container = try PersistenceController.makeContainer(for: .app, configuration: configuration, inMemory: true)
        let suite = "journal.inmemory.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        return try wire(
            container: container, defaults: defaults, configuration: configuration,
            time: time, reminders: reminders, widgets: widgets
        )
    }

    private static func wire(
        container: ModelContainer,
        defaults: UserDefaults,
        configuration: AppConfiguration,
        time: any TimeSource,
        reminders: any ReminderScheduler,
        widgets: any WidgetRefresher
    ) throws -> JournalEnvironment {
        let useCases = JournalUseCases(
            time: time,
            entries: SwiftDataEntryRepository(modelContainer: container),
            prompts: try BundledPromptLibrary(),
            promptState: AppGroupPromptStateStore(defaults: defaults),
            settings: AppGroupSettingsStore(defaults: defaults),
            reminders: reminders,
            widgets: widgets
        )
        return JournalEnvironment(useCases: useCases, modelContainer: container, configuration: configuration)
    }
}
