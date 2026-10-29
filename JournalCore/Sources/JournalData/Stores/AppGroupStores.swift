import Foundation
import JournalDomain

/// Per-device prompt state in App Group `UserDefaults` (key `promptState.v1`).
public final class AppGroupPromptStateStore: PromptStateStore, @unchecked Sendable {
    public static let key = "promptState.v1"
    // UserDefaults is thread-safe; the lock keeps read-modify-write updates atomic.
    private let defaults: UserDefaults
    private let lock = NSLock()

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func state(for day: CalendarDay) -> DailyPromptState? {
        lock.withLock { load()[day.key] }
    }

    public func save(_ state: DailyPromptState, keepingFrom: CalendarDay) {
        lock.withLock {
            var all = load()
            all[state.day.key] = state
            all = all.filter { (CalendarDay(key: $0.key) ?? keepingFrom.adding(days: -1)) >= keepingFrom }
            if let data = try? JSONEncoder().encode(all) {
                defaults.set(data, forKey: Self.key)
            }
        }
    }

    private func load() -> [String: DailyPromptState] {
        guard let data = defaults.data(forKey: Self.key),
              let decoded = try? JSONDecoder().decode([String: DailyPromptState].self, from: data)
        else { return [:] }
        return decoded
    }
}

/// App settings in App Group `UserDefaults` (key `settings.v1`), so the widget can read them too.
public final class AppGroupSettingsStore: SettingsStore, @unchecked Sendable {
    public static let key = "settings.v1"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// Defaults (BR-G1) when nothing is stored or the stored value is unreadable.
    public func load() -> AppSettings {
        guard let data = defaults.data(forKey: Self.key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return .default }
        return settings.categories.isEmpty ? AppSettings(reminder: settings.reminder, onboardingCompleted: settings.onboardingCompleted) : settings
    }

    public func save(_ settings: AppSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Self.key)
        }
    }
}
