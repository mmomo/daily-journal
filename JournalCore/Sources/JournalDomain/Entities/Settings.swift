public struct ReminderSettings: Equatable, Codable, Sendable {
    public var isEnabled: Bool
    public var hour: Int
    public var minute: Int

    public init(isEnabled: Bool = false, hour: Int = 20, minute: Int = 0) {
        self.isEnabled = isEnabled
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    public static let `default` = ReminderSettings()
}

public struct AppSettings: Equatable, Codable, Sendable {
    /// Never empty (BR-G2).
    public var categories: Set<PromptCategory>
    public var reminder: ReminderSettings
    public var onboardingCompleted: Bool

    public init(
        categories: Set<PromptCategory> = Set(PromptCategory.allCases),
        reminder: ReminderSettings = .default,
        onboardingCompleted: Bool = false
    ) {
        self.categories = categories.isEmpty ? Set(PromptCategory.allCases) : categories
        self.reminder = reminder
        self.onboardingCompleted = onboardingCompleted
    }

    /// BR-G1 defaults.
    public static let `default` = AppSettings()
}
