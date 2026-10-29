import JournalDomain
import SwiftUI

/// Value-based destinations for the root `NavigationStack`, all registered on `TodayView`.
enum Route: Hashable {
    case history
    case settings
    case entry(CalendarDay)
}

/// The home screen: streak, prompt, and today's entry (US-1.x, US-2.x, US-4.x, US-2.5).
struct TodayView: View {
    let useCases: JournalUseCases

    @Environment(AppEnvironment.self) private var environment
    @State private var state: TodayState?
    @State private var errorMessage: String?
    /// Keeps the editor on screen while typing, even after the first autosave marks today as done.
    @State private var isEditing = false
    @State private var showingBackfill = false
    @State private var focusTrigger = 0

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let state {
                        content(for: state, scrollProxy: proxy)
                    } else {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                    if let errorMessage {
                        Text(errorMessage).font(.footnote).foregroundStyle(.red)
                    }
                }
                .padding()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(state?.day.longTitle ?? "Today")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(value: Route.history) {
                    Label("History", systemImage: "book")
                }
                .accessibilityIdentifier("today-history-button")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: Route.settings) {
                    Label("Settings", systemImage: "gearshape")
                }
                .accessibilityIdentifier("today-settings-button")
            }
        }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .history: HistoryView(useCases: useCases)
            case .settings: SettingsView(useCases: useCases)
            case let .entry(day): EntryDetailView(useCases: useCases, day: day)
            }
        }
        .task(id: environment.refreshToken) {
            await load()
            consumeDeepLink()
        }
        .onChange(of: environment.pendingDeepLink) {
            consumeDeepLink()
        }
        .sheet(isPresented: $showingBackfill) {
            if let offer = state?.backfillOffer {
                BackfillSheet(offer: offer, useCases: useCases) {
                    showingBackfill = false
                    environment.refresh()
                }
            }
        }
    }

    @ViewBuilder
    private func content(for state: TodayState, scrollProxy: ScrollViewProxy) -> some View {
        StreakView(streak: state.streak)

        if let offer = state.backfillOffer {
            Button {
                showingBackfill = true
            } label: {
                Label(
                    "Write yesterday's entry · until \(offer.until.formatted(date: .omitted, time: .shortened))",
                    systemImage: "clock.arrow.circlepath"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("today-backfill-button")
        }

        PromptCard(
            prompt: state.prompt,
            refreshesRemaining: state.refreshesRemaining,
            showsRefresh: !state.isTodayDone,
            onRefresh: refresh
        )

        if state.isTodayDone, !isEditing, let entry = state.entry {
            savedEntry(entry, editable: state.entryEditability.isEditable)
        } else if state.entryEditability.isEditable {
            EntryEditorView(
                mode: .today(state.day),
                useCases: useCases,
                initialText: state.entry?.text ?? "",
                autoFocus: !state.isTodayDone || isEditing,
                focusTrigger: focusTrigger,
                onSaved: {
                    isEditing = true
                    Task { await load() }
                },
                onFinished: { isEditing = false },
                onEditingActivity: { scrollProxy.scrollTo(state.day, anchor: .bottom) }
            )
            .id(state.day)
        }
    }

    private func savedEntry(_ entry: JournalEntry, editable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(entry.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
            if editable {
                Button("Edit") { isEditing = true }
                    .accessibilityIdentifier("today-edit-button")
            } else {
                Label("This entry is locked.", systemImage: "lock")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }

    private func load() async {
        do {
            state = try await useCases.getTodayState.execute()
            errorMessage = nil
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    private func refresh() {
        Task {
            do {
                try await useCases.refreshPrompt.execute()
                await load()
            } catch {
                errorMessage = userMessage(for: error)
            }
        }
    }

    /// Widget/notification/URL routing (services.md S9).
    private func consumeDeepLink() {
        guard let link = environment.pendingDeepLink, let state else { return }
        environment.pendingDeepLink = nil
        switch link {
        case .todayEditor:
            if !state.isTodayDone { focusTrigger += 1 }
        case .backfillEditor:
            showingBackfill = state.backfillOffer != nil
        }
    }
}

/// Sheet for writing yesterday's missing entry before the noon deadline (US-2.3).
private struct BackfillSheet: View {
    let offer: BackfillOffer
    let useCases: JournalUseCases
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(offer.prompt.text)
                    .font(.title3.weight(.semibold))
                EntryEditorView(mode: .backfill(offer.day), useCases: useCases, autoFocus: true, onFinished: onDone)
                Spacer()
            }
            .padding()
            .navigationTitle(offer.day.longTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDone)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TodayView(useCases: try! JournalEnvironmentFactoryPreview.useCases())
    }
    .environment(AppEnvironment.preview())
}
