import JournalDomain
import SwiftUI
import UIKit

/// Categories, daily reminder and export (US-7.2, US-1.4, US-6.1, US-3.3).
struct SettingsView: View {
    let useCases: JournalUseCases

    @Environment(AppEnvironment.self) private var environment
    @State private var settings = AppSettings.default
    @State private var categoryMessage: String?
    @State private var notificationsDenied = false

    var body: some View {
        Form {
            Section {
                ForEach(PromptCategory.allCases, id: \.self) { category in
                    Toggle(isOn: categoryBinding(category)) {
                        Label(category.title, systemImage: category.symbol)
                    }
                    .accessibilityIdentifier("settings-category-toggle-\(category.rawValue)")
                }
            } header: {
                Text("Prompt categories")
            } footer: {
                Text(categoryMessage ?? "Changes apply to refreshes today and to prompts from tomorrow.")
            }

            Section {
                Toggle("Daily reminder", isOn: reminderEnabledBinding)
                    .accessibilityIdentifier("settings-reminder-toggle")
                if settings.reminder.isEnabled {
                    DatePicker(
                        "Time",
                        selection: Binding(
                            get: { settings.reminder.timeOfDay },
                            set: { apply(settings.reminder.with(time: $0)) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .accessibilityIdentifier("settings-reminder-time")
                }
            } header: {
                Text("Reminder")
            } footer: {
                if notificationsDenied {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(JournalError.notificationsDenied.message)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                } else {
                    Text("Skipped automatically on days you've already written.")
                }
            }

            ExportSection(useCases: useCases)
        }
        .navigationTitle("Settings")
        .task {
            settings = useCases.getSettings.execute()
        }
    }

    private func categoryBinding(_ category: PromptCategory) -> Binding<Bool> {
        Binding(
            get: { settings.categories.contains(category) },
            set: { isOn in
                var updated = settings.categories
                if isOn { updated.insert(category) } else { updated.remove(category) }
                do {
                    try useCases.updatePromptCategories.execute(updated)
                    settings.categories = updated
                    categoryMessage = nil
                    environment.refresh()
                } catch {
                    categoryMessage = userMessage(for: error)
                }
            }
        )
    }

    private var reminderEnabledBinding: Binding<Bool> {
        Binding(
            get: { settings.reminder.isEnabled },
            set: { isOn in
                var updated = settings.reminder
                updated.isEnabled = isOn
                apply(updated)
            }
        )
    }

    private func apply(_ reminder: ReminderSettings) {
        settings.reminder = reminder
        Task {
            do {
                try await useCases.configureReminder.execute(reminder)
                notificationsDenied = false
            } catch JournalError.notificationsDenied {
                notificationsDenied = true
                settings.reminder.isEnabled = false
            } catch {
                settings = useCases.getSettings.execute()
            }
        }
    }
}

/// Prepares export files and offers them through the share sheet (US-3.3).
struct ExportSection: View {
    let useCases: JournalUseCases

    @State private var files: [ExportFormat: URL] = [:]
    @State private var unavailableMessage: String?

    var body: some View {
        Section {
            if let unavailableMessage {
                Text(unavailableMessage).foregroundStyle(.secondary)
            } else {
                exportLink(.markdown, title: "Export as Markdown", identifier: "settings-export-markdown")
                exportLink(.plainText, title: "Export as plain text", identifier: "settings-export-text")
            }
        } header: {
            Text("Export")
        }
        .task {
            await prepare()
        }
    }

    @ViewBuilder
    private func exportLink(_ format: ExportFormat, title: String, identifier: String) -> some View {
        if let url = files[format] {
            ShareLink(item: url) {
                Label(title, systemImage: "square.and.arrow.up")
            }
            .accessibilityIdentifier(identifier)
        } else {
            Label(title, systemImage: "square.and.arrow.up").foregroundStyle(.secondary)
        }
    }

    private func prepare() async {
        for format in ExportFormat.allCases {
            do {
                let document = try await useCases.exportJournal.execute(format: format)
                let url = FileManager.default.temporaryDirectory.appending(path: document.fileName)
                try Data(document.contents.utf8).write(to: url, options: .atomic)
                files[format] = url
            } catch {
                unavailableMessage = userMessage(for: error)
                return
            }
        }
    }
}
