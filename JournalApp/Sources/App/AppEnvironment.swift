import Foundation
import JournalData
import JournalDomain
import Observation

/// App-wide state shared through SwiftUI's environment: the wired use cases plus lifecycle signals.
/// There are no view models (FQ1:B); views call `useCases` directly and reload on `refreshToken`.
@MainActor
@Observable
final class AppEnvironment {
    private(set) var useCases: JournalUseCases?
    private(set) var startupError: String?
    /// Bumped whenever visible data may have changed (save, sync, day change, noon cutoff).
    private(set) var refreshToken = UUID()
    /// Set by widget taps, notification taps and URLs; consumed by `TodayView`.
    var pendingDeepLink: DeepLink?

    @ObservationIgnored private let makeEnvironment: () throws -> JournalEnvironment
    @ObservationIgnored private var started = false
    @ObservationIgnored private var remoteObserver: RemoteChangeObserver?
    @ObservationIgnored private var dayChangeTask: Task<Void, Never>?
    @ObservationIgnored private var boundaryTask: Task<Void, Never>?

    init(makeEnvironment: @escaping () throws -> JournalEnvironment = { try JournalEnvironmentFactory.make(for: .app) }) {
        self.makeEnvironment = makeEnvironment
    }

    /// Builds the environment once. Safe to call repeatedly.
    func start() {
        guard !started else { return }
        do {
            useCases = try makeEnvironment().useCases
            startupError = nil
            started = true
        } catch {
            startupError = "Your journal couldn't be opened. \(error.localizedDescription)"
            return
        }

        let observer = RemoteChangeObserver { [weak self] in
            await self?.reconcileAndRefresh()
        }
        observer.start()
        remoteObserver = observer

        dayChangeTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                await self?.becameActive()
            }
        }
        Task { await becameActive() }
    }

    func retry() {
        started = false
        start()
    }

    /// Launch, foreground and day change: merge synced duplicates, refresh reminders, reload views (services.md S7).
    func becameActive() async {
        guard let useCases else { return }
        _ = try? await useCases.reconcileSyncedEntries.execute()
        await useCases.syncReminderWithToday.execute()
        refresh()
        scheduleBoundaryRefresh()
    }

    func refresh() {
        refreshToken = UUID()
    }

    func handle(url: URL) {
        if let link = DeepLink(url: url) {
            pendingDeepLink = link
        }
    }

    private func reconcileAndRefresh() async {
        guard let useCases else { return }
        _ = try? await useCases.reconcileSyncedEntries.execute()
        refresh()
    }

    /// While the app is open, refresh at the next 12:00 cutoff or midnight, whichever comes first.
    private func scheduleBoundaryRefresh() {
        boundaryTask?.cancel()
        let now = Date()
        let timeZone = TimeZone.autoupdatingCurrent
        let today = CalendarDay(containing: now, timeZone: timeZone)
        let noon = today.noon(in: timeZone)
        let midnight = today.adding(days: 1).start(in: timeZone)
        let next = noon > now ? noon : midnight
        let delay = max(1, next.timeIntervalSince(now) + 1)
        boundaryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await self?.becameActive()
        }
    }
}

extension AppEnvironment {
    /// In-memory environment for SwiftUI previews.
    static func preview(onboarded: Bool = true, seed: Bool = true) -> AppEnvironment {
        let environment = AppEnvironment {
            let env = try JournalEnvironmentFactory.makeInMemory()
            if onboarded {
                Task {
                    try? await env.useCases.completeOnboarding.execute(categories: Set(PromptCategory.allCases), reminder: nil)
                }
            }
            return env
        }
        environment.start()
        return environment
    }
}
