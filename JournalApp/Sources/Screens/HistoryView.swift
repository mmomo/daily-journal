import JournalDomain
import SwiftUI

/// Past entries, newest first, with search (US-3.1, US-3.2).
struct HistoryView: View {
    let useCases: JournalUseCases

    @Environment(AppEnvironment.self) private var environment
    @State private var query = ""
    @State private var entries: [JournalEntry] = []
    @State private var loaded = false
    @State private var errorMessage: String?

    var body: some View {
        List(entries) { entry in
            NavigationLink(value: Route.entry(entry.day)) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.day.shortTitle)
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.tint)
                    Text(entry.promptText)
                        .font(.system(.headline, design: .serif))
                        .lineLimit(1)
                    Text(entry.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 6)
            }
        }
        .accessibilityIdentifier("history-list")
        .overlay {
            if loaded && entries.isEmpty {
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    ContentUnavailableView(
                        "No entries yet",
                        systemImage: "book.closed",
                        description: Text("Today's prompt is waiting for you.")
                    )
                } else {
                    ContentUnavailableView.search(text: query)
                }
            }
        }
        .navigationTitle("History")
        .searchable(text: $query, prompt: "Search entries and prompts")
        .task(id: "\(query)|\(environment.refreshToken)") {
            if !query.isEmpty {
                try? await Task.sleep(for: .milliseconds(250))
                if Task.isCancelled { return }
            }
            do {
                entries = try await useCases.searchEntries.execute(query: query)
                errorMessage = nil
            } catch {
                errorMessage = userMessage(for: error)
            }
            loaded = true
        }
        .safeAreaInset(edge: .bottom) {
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red).padding()
            }
        }
    }
}

/// One entry: editable if it is today's, read-only otherwise (US-2.4).
struct EntryDetailView: View {
    let useCases: JournalUseCases
    let day: CalendarDay

    @Environment(AppEnvironment.self) private var environment
    @State private var detail: EntryDetail?
    @State private var missing = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let detail {
                        Text(detail.entry.promptText)
                            .font(.system(.title2, design: .serif, weight: .semibold))
                        if detail.editability.isEditable {
                            EntryEditorView(
                                mode: .today(day),
                                useCases: useCases,
                                initialText: detail.entry.text,
                                onSaved: { environment.refresh() },
                                onEditingActivity: { proxy.scrollTo(day, anchor: .bottom) }
                            )
                            .id(day)
                        } else {
                            Text(detail.entry.text)
                                .lineSpacing(4)
                                .textSelection(.enabled)
                                .card(padding: 20)
                            Label("Past entries are read-only.", systemImage: "lock")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else if missing {
                        ContentUnavailableView("Entry not found", systemImage: "questionmark.folder")
                    } else {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(day.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            detail = try? await useCases.getEntry.execute(day: day)
            missing = detail == nil
        }
    }
}
