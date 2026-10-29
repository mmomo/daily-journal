import JournalDomain
import SwiftUI

/// Current and best streak with done and at-risk states (US-4.1–4.4).
struct StreakView: View {
    let streak: StreakSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(streak.current > 0 ? Color.orange : Color.secondary)
                    .frame(width: 48, height: 48)
                    .background(
                        (streak.current > 0 ? Color.orange : Color.secondary).opacity(0.15),
                        in: Circle()
                    )
                VStack(alignment: .leading, spacing: 2) {
                    if streak.current > 0 {
                        Text("\(streak.current)")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .contentTransition(.numericText())
                    }
                    Text(title)
                        .font(streak.current > 0 ? .subheadline : .headline)
                        .foregroundStyle(streak.current > 0 ? .secondary : .primary)
                        .accessibilityIdentifier("streak-label")
                }
                .accessibilityElement(children: .combine)
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    if streak.isTodayDone {
                        Label("Done", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .accessibilityLabel("Today is done")
                    }
                    Text("Best \(streak.best)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                }
            }
            if let caption = atRiskCaption {
                Label(caption, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
        .card()
    }

    private var title: String {
        switch streak.current {
        case 0: "Start your streak today"
        case 1: "day streak"
        default: "days in a row"
        }
    }

    private var atRiskCaption: String? {
        guard case let .atRisk(restorable, until) = streak.status else { return nil }
        let time = until.formatted(date: .omitted, time: .shortened)
        let verb = streak.isTodayDone ? "restore" : "keep"
        return "Write yesterday's entry by \(time) to \(verb) your \(restorable)-day streak."
    }
}

#Preview {
    VStack {
        StreakView(streak: StreakSummary(current: 5, best: 12, status: .active, isTodayDone: true))
        StreakView(streak: StreakSummary(current: 3, best: 3, status: .atRisk(restorableCount: 3, until: .now), isTodayDone: false))
        StreakView(streak: .empty)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
