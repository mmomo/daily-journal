import JournalDomain
import SwiftUI

/// Text editor for today's entry (autosave) or yesterday's backfill (explicit save).
struct EntryEditorView: View {
    enum Mode: Equatable {
        case today(CalendarDay)
        case backfill(CalendarDay)
    }

    let mode: Mode
    let useCases: JournalUseCases
    var autoFocus = false
    var focusTrigger = 0
    var onSaved: () -> Void = {}
    var onFinished: () -> Void = {}
    /// Called on focus and while typing so the enclosing scroll view can keep the editor above the keyboard.
    var onEditingActivity: () -> Void = {}

    @State private var text: String
    @State private var status: String?
    @State private var isLocked = false
    @State private var autosaveTask: Task<Void, Never>?
    @State private var inFlight: Task<Bool, Never>?
    @State private var finishCount = 0
    @FocusState private var focused: Bool

    init(
        mode: Mode,
        useCases: JournalUseCases,
        initialText: String = "",
        autoFocus: Bool = false,
        focusTrigger: Int = 0,
        onSaved: @escaping () -> Void = {},
        onFinished: @escaping () -> Void = {},
        onEditingActivity: @escaping () -> Void = {}
    ) {
        self.mode = mode
        self.useCases = useCases
        self.autoFocus = autoFocus
        self.focusTrigger = focusTrigger
        self.onSaved = onSaved
        self.onFinished = onFinished
        self.onEditingActivity = onEditingActivity
        _text = State(initialValue: initialText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Start writing…")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                    }
                    TextEditor(text: $text)
                        .focused($focused)
                        .lineSpacing(4)
                        .scrollContentBackground(.hidden)
                        .disabled(isLocked)
                        .accessibilityIdentifier("editor-text-field")
                }
                // Capped so long text scrolls inside the editor, keeping the caret and the button on screen.
                .frame(minHeight: 180, maxHeight: 300)

                statusLine
            }
            .card(padding: 12)

            Button(action: finish) {
                Label(finishTitle, systemImage: "checkmark")
            }
            .buttonStyle(.primary)
            .disabled(!canFinish)
            .sensoryFeedback(.success, trigger: finishCount)
            .accessibilityIdentifier("editor-done-button")
        }
        .onAppear {
            if autoFocus { focused = true }
        }
        .onChange(of: focusTrigger) {
            focused = true
        }
        .onChange(of: focused) {
            guard focused else { return }
            // Wait for the keyboard to finish appearing so the scroll lands above it.
            Task {
                try? await Task.sleep(for: .milliseconds(350))
                if focused { onEditingActivity() }
            }
        }
        .onChange(of: text) {
            if !isBackfill { scheduleAutosave() }
            if focused { onEditingActivity() }
        }
    }

    private var statusLine: some View {
        HStack(spacing: 4) {
            if let status {
                Image(systemName: isLocked ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                Text(status)
            }
            Spacer()
            if !text.isEmpty {
                Text(wordCount == 1 ? "1 word" : "\(wordCount) words")
                    .monospacedDigit()
            }
        }
        .font(.caption)
        .foregroundStyle(isLocked ? Color.red : Color.secondary)
        .padding(.horizontal, 5)
        .frame(minHeight: 16)
    }

    private var wordCount: Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    private var finishTitle: String { isBackfill ? "Save" : "Done" }

    private var canFinish: Bool { !isLocked && JournalEntry.isValidText(text) }

    private func finish() {
        autosaveTask?.cancel()
        Task {
            if await save() {
                finishCount += 1
                focused = false
                onFinished()
            }
        }
    }

    private var isBackfill: Bool {
        if case .backfill = mode { return true }
        return false
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        guard JournalEntry.isValidText(text), !isLocked else { return }
        autosaveTask = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            _ = await save()
        }
    }

    /// Serialises saves so an autosave and the Done button never race to create two entries.
    @discardableResult
    private func save() async -> Bool {
        let previous = inFlight
        let snapshot = text
        let task = Task { () -> Bool in
            _ = await previous?.value
            return await perform(snapshot)
        }
        inFlight = task
        return await task.value
    }

    private func perform(_ snapshot: String) async -> Bool {
        do {
            switch mode {
            case let .today(day):
                try await useCases.saveTodayEntry.execute(text: snapshot, day: day)
            case let .backfill(day):
                try await useCases.backfillYesterday.execute(text: snapshot, day: day)
            }
            status = "Saved"
            onSaved()
            return true
        } catch {
            status = userMessage(for: error)
            if let error = error as? JournalError, error == .entryLocked || error == .backfillNotAvailable {
                isLocked = true
                focused = false
            }
            return false
        }
    }
}
