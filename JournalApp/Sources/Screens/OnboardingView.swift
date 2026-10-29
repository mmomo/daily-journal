import JournalDomain
import SwiftUI

/// Two-step first-launch setup: prompt categories, then an optional reminder (US-7.1).
struct OnboardingView: View {
    let useCases: JournalUseCases
    let onFinished: () -> Void

    @State private var step = 0
    @State private var categories = Set(PromptCategory.allCases)
    @State private var reminderOn = false
    @State private var reminder = ReminderSettings.default
    @State private var isFinishing = false
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 12)
            if step == 0 { categoriesStep } else { reminderStep }
            Spacer()
            if let message {
                Text(message).font(.footnote).foregroundStyle(.secondary)
            }
            footer
        }
        .padding(24)
        .animation(.default, value: step)
    }

    private var categoriesStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to\nDaily Journal")
                .font(.largeTitle.bold())
            Text("One prompt a day, a few honest sentences, and a streak to keep you going. What would you like to write about?")
                .foregroundStyle(.secondary)
            ForEach(PromptCategory.allCases, id: \.self) { category in
                Toggle(isOn: binding(for: category)) {
                    Label(category.title, systemImage: category.symbol)
                }
                .accessibilityIdentifier("onboarding-category-toggle-\(category.rawValue)")
            }
            if categories.isEmpty {
                Text("Choose at least one category.").font(.footnote).foregroundStyle(.red)
            }
        }
    }

    private var reminderStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("A gentle nudge?")
                .font(.largeTitle.bold())
            Text("Get one reminder a day. It's skipped automatically once you've written.")
                .foregroundStyle(.secondary)
            Toggle("Daily reminder", isOn: $reminderOn)
                .accessibilityIdentifier("onboarding-reminder-toggle")
            if reminderOn {
                DatePicker(
                    "Time",
                    selection: Binding(get: { reminder.timeOfDay }, set: { reminder = reminder.with(time: $0) }),
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if step == 0 {
                Button("Next") { step = 1 }
                    .buttonStyle(.primary)
                    .disabled(categories.isEmpty)
                    .accessibilityIdentifier("onboarding-next-button")
            } else {
                Button(reminderOn ? "Start journaling" : "Not now, start journaling") { finish() }
                    .buttonStyle(.primary)
                    .disabled(isFinishing)
                    .accessibilityIdentifier("onboarding-finish-button")
                Button("Back") { step = 0 }
                    .font(.subheadline.weight(.medium))
            }
        }
    }

    private func binding(for category: PromptCategory) -> Binding<Bool> {
        Binding(
            get: { categories.contains(category) },
            set: { isOn in
                if isOn { categories.insert(category) } else { categories.remove(category) }
            }
        )
    }

    private func finish() {
        isFinishing = true
        Task {
            var settings = reminder
            settings.isEnabled = true
            do {
                try await useCases.completeOnboarding.execute(categories: categories, reminder: reminderOn ? settings : nil)
                onFinished()
            } catch JournalError.notificationsDenied {
                // Onboarding is complete; the reminder simply stays off (BR-G4).
                onFinished()
            } catch {
                message = userMessage(for: error)
                isFinishing = false
            }
        }
    }
}

#Preview {
    OnboardingView(useCases: try! JournalEnvironmentFactoryPreview.useCases(), onFinished: {})
}
