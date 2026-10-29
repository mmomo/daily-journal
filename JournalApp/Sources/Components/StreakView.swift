import JournalDomain
import SwiftUI

/// Current and best streak with done and at-risk states (US-4.1–4.4).
struct StreakView: View {
    let streak: StreakSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(streak.current > 0 ? Color.orange : Color.secondary)
                Text(title)
                    .font(.headline)
                    .accessibilityIdentifier("streak-label")
                if streak.isTodayDone {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityLabel("Today is done")
                }
                Spacer()
                Text("Best \(streak.best)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let caption = atRiskCaption {
                Label(caption, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private var title: String {
        switch streak.current {
        case 0: "Start your streak today"
        case 1: "1 day streak"
        default: "\(streak.current) day streak"
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
    }
    .padding()
}
