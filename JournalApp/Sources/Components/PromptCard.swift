import JournalDomain
import SwiftUI

/// Today's prompt with the limited refresh control (US-1.1, US-1.3).
struct PromptCard: View {
    let prompt: Prompt
    let refreshesRemaining: Int
    let showsRefresh: Bool
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(prompt.category.title, systemImage: prompt.category.symbol)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.tint.opacity(0.12), in: Capsule())
            Text(prompt.text)
                .font(.system(.title2, design: .serif, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("today-prompt-text")
            if showsRefresh {
                Button(action: onRefresh) {
                    Label(
                        refreshesRemaining > 0 ? "New prompt · \(refreshesRemaining) left" : "No refreshes left today",
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                    .font(.footnote.weight(.medium))
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .disabled(refreshesRemaining == 0)
                .accessibilityIdentifier("today-refresh-button")
            }
        }
        .card(padding: 20)
    }
}

#Preview {
    PromptCard(
        prompt: Prompt(id: "gratitude-001", category: .gratitude, text: "What small thing made today better?"),
        refreshesRemaining: 2,
        showsRefresh: true,
        onRefresh: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
