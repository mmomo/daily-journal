import JournalDomain
import SwiftUI
import WidgetKit

struct PromptStreakWidgetView: View {
    let entry: PromptStreakEntry

    var body: some View {
        Group {
            switch entry.content {
            case let .ready(state):
                ready(state)
            case .needsSetup:
                needsSetup
            }
        }
        .widgetURL(DeepLink.todayEditor.url)
    }

    private func ready(_ state: TodayState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            StreakBadge(streak: state.streak)
            Text(state.prompt.text)
                .font(.subheadline.weight(.semibold))
                .lineLimit(5)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText(for: state))
    }

    private var needsSetup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "book.pages")
                .font(.title2)
                .foregroundStyle(.tint)
            Text("Open Daily Journal to get your first prompt")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func accessibilityText(for state: TodayState) -> String {
        var parts = ["Today's prompt: \(state.prompt.text)", "\(state.streak.current) day streak"]
        if state.isTodayDone { parts.append("Today is done") }
        if case .atRisk = state.streak.status { parts.append("Streak at risk") }
        return parts.joined(separator: ". ")
    }
}

/// Flame + count, with ✓ when today is done and ⚠︎ when the streak is at risk.
private struct StreakBadge: View {
    let streak: StreakSummary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(streak.current > 0 ? Color.orange : Color.secondary)
            Text("\(streak.current)")
                .font(.headline.monospacedDigit())
            Spacer(minLength: 0)
            if streak.isTodayDone {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            } else if case .atRisk = streak.status {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            }
        }
        .font(.subheadline)
    }
}

#Preview("Ready", as: .systemSmall) {
    PromptStreakWidget()
} timeline: {
    PromptStreakEntry(date: .now, content: .ready(.sample))
}

#Preview("Done", as: .systemSmall) {
    PromptStreakWidget()
} timeline: {
    PromptStreakEntry(date: .now, content: .ready(TodayState(
        day: TodayState.sample.day, prompt: TodayState.sample.prompt, entry: nil, entryEditability: .locked,
        refreshesRemaining: 0, backfillOffer: nil,
        streak: StreakSummary(current: 6, best: 12, status: .active, isTodayDone: true), onboardingCompleted: true
    )))
}

#Preview("At risk", as: .systemSmall) {
    PromptStreakWidget()
} timeline: {
    PromptStreakEntry(date: .now, content: .ready(TodayState(
        day: TodayState.sample.day, prompt: TodayState.sample.prompt, entry: nil, entryEditability: .locked,
        refreshesRemaining: 3, backfillOffer: nil,
        streak: StreakSummary(current: 3, best: 3, status: .atRisk(restorableCount: 3, until: .now), isTodayDone: false),
        onboardingCompleted: true
    )))
}

#Preview("Needs setup", as: .systemSmall) {
    PromptStreakWidget()
} timeline: {
    PromptStreakEntry(date: .now, content: .needsSetup)
}
