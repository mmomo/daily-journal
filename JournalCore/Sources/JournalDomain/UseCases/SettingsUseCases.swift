import Foundation

public struct GetSettingsUseCase: Sendable {
    let settings: any SettingsStore

    public func execute() -> AppSettings {
        settings.load()
    }
}

/// US-1.4, BR-G2, BR-G3. Today's already-chosen prompt is unaffected (BR-P4).
public struct UpdatePromptCategoriesUseCase: Sendable {
    let settings: any SettingsStore
    let widgets: any WidgetRefresher

    public func execute(_ categories: Set<PromptCategory>) throws {
        guard !categories.isEmpty else { throw JournalError.categoriesEmpty }
        var current = settings.load()
        current.categories = categories
        settings.save(current)
        widgets.reloadAll()
    }
}

/// Recomputes the rolling reminder window (BR-R1–R6). Best effort; never throws.
public struct SyncReminderWithTodayUseCase: Sendable {
    let time: any TimeSource
    let entries: any EntryRepository
    let settings: any SettingsStore
    let scheduler: any ReminderScheduler

    public func execute() async {
        let reminder = settings.load().reminder
        let isAuthorized = reminder.isEnabled ? await scheduler.authorizationStatus() == .authorized : false
        var streak = StreakSummary.empty
        if reminder.isEnabled, isAuthorized, let days = try? await entries.entryDays() {
            streak = StreakCalculator.summary(entryDays: days, now: time.now, timeZone: time.timeZone)
        }
        let plan = ReminderPlanner.plan(
            settings: reminder,
            isAuthorized: isAuthorized,
            streak: streak,
            now: time.now,
            timeZone: time.timeZone
        )
        await scheduler.replacePending(with: plan)
    }
}

/// Turns the reminder on/off or changes its time (US-6.1, BR-R7).
public struct ConfigureReminderUseCase: Sendable {
    let settings: any SettingsStore
    let scheduler: any ReminderScheduler
    let syncReminder: SyncReminderWithTodayUseCase

    @discardableResult
    public func execute(_ reminder: ReminderSettings) async throws -> ReminderAuthorization {
        var current = settings.load()
        var status = await scheduler.authorizationStatus()

        if reminder.isEnabled {
            if status == .notDetermined {
                status = await scheduler.requestAuthorization() ? .authorized : .denied
            }
            guard status == .authorized else {
                var off = reminder
                off.isEnabled = false
                current.reminder = off
                settings.save(current)
                await syncReminder.execute()
                throw JournalError.notificationsDenied
            }
        }
        current.reminder = reminder
        settings.save(current)
        await syncReminder.execute()
        return status
    }
}

/// Finishes first-launch onboarding (US-7.1, BR-G4).
public struct CompleteOnboardingUseCase: Sendable {
    let settings: any SettingsStore
    let widgets: any WidgetRefresher
    let configureReminder: ConfigureReminderUseCase

    /// Completes onboarding even if notification permission is denied; that case is reported
    /// by throwing `notificationsDenied` *after* onboarding has been saved as complete.
    public func execute(categories: Set<PromptCategory>, reminder: ReminderSettings?) async throws {
        guard !categories.isEmpty else { throw JournalError.categoriesEmpty }
        var current = settings.load()
        current.categories = categories
        settings.save(current)

        var denied = false
        if let reminder, reminder.isEnabled {
            do {
                try await configureReminder.execute(reminder)
            } catch JournalError.notificationsDenied {
                denied = true
            }
        }

        current = settings.load()
        current.onboardingCompleted = true
        settings.save(current)
        widgets.reloadAll()
        if denied { throw JournalError.notificationsDenied }
    }
}
