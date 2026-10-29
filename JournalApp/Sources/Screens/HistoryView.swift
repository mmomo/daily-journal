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
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.day.shortTitle).font(.headline)
                    Text(entry.promptText).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                    Text(entry.text).font(.body).lineLimit(2)
                }
                .padding(.vertical, 4)
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
                            .font(.title3.weight(.semibold))
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
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
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
