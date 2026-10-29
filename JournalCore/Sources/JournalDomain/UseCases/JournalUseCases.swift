/// All 15 use cases, wired from the ports. Built once per process by the composition root
/// (Data unit's `JournalEnvironmentFactory`) or directly in tests.
public struct JournalUseCases: Sendable {
    public let getTodayState: GetTodayStateUseCase
    public let refreshPrompt: RefreshPromptUseCase
    public let saveTodayEntry: SaveTodayEntryUseCase
    public let backfillYesterday: BackfillYesterdayUseCase
    public let getEntry: GetEntryUseCase
    public let listEntries: ListEntriesUseCase
    public let searchEntries: SearchEntriesUseCase
    public let exportJournal: ExportJournalUseCase
    public let getStreak: GetStreakUseCase
    public let getSettings: GetSettingsUseCase
    public let updatePromptCategories: UpdatePromptCategoriesUseCase
    public let configureReminder: ConfigureReminderUseCase
    public let syncReminderWithToday: SyncReminderWithTodayUseCase
    public let completeOnboarding: CompleteOnboardingUseCase
    public let reconcileSyncedEntries: ReconcileSyncedEntriesUseCase

    public init(
        time: any TimeSource,
        entries: any EntryRepository,
        prompts: any PromptLibrary,
        promptState: any PromptStateStore,
        settings: any SettingsStore,
        reminders: any ReminderScheduler,
        widgets: any WidgetRefresher
    ) {
        let resolver = PromptResolver(
            time: time, entries: entries, library: prompts, promptState: promptState, settings: settings
        )
        let syncReminder = SyncReminderWithTodayUseCase(
            time: time, entries: entries, settings: settings, scheduler: reminders
        )
        let configureReminder = ConfigureReminderUseCase(
            settings: settings, scheduler: reminders, syncReminder: syncReminder
        )

        getTodayState = GetTodayStateUseCase(
            time: time, entries: entries, library: prompts, settings: settings, resolver: resolver
        )
        refreshPrompt = RefreshPromptUseCase(
            time: time, entries: entries, settings: settings, promptState: promptState,
            widgets: widgets, resolver: resolver
        )
        saveTodayEntry = SaveTodayEntryUseCase(
            time: time, entries: entries, widgets: widgets, resolver: resolver, syncReminder: syncReminder
        )
        backfillYesterday = BackfillYesterdayUseCase(
            time: time, entries: entries, widgets: widgets, resolver: resolver, syncReminder: syncReminder
        )
        getEntry = GetEntryUseCase(time: time, entries: entries)
        listEntries = ListEntriesUseCase(entries: entries)
        searchEntries = SearchEntriesUseCase(entries: entries)
        exportJournal = ExportJournalUseCase(time: time, entries: entries)
        getStreak = GetStreakUseCase(time: time, entries: entries)
        getSettings = GetSettingsUseCase(settings: settings)
        updatePromptCategories = UpdatePromptCategoriesUseCase(settings: settings, widgets: widgets)
        self.configureReminder = configureReminder
        syncReminderWithToday = syncReminder
        completeOnboarding = CompleteOnboardingUseCase(
            settings: settings, widgets: widgets, configureReminder: configureReminder
        )
        reconcileSyncedEntries = ReconcileSyncedEntriesUseCase(
            entries: entries, widgets: widgets, syncReminder: syncReminder
        )
    }
}
