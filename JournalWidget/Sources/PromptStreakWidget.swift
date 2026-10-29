import SwiftUI
import WidgetKit

/// Small Home Screen widget: today's prompt with a streak badge (US-5.1–5.3).
struct PromptStreakWidget: Widget {
    static let kind = "PromptStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: PromptStreakProvider()) { entry in
            PromptStreakWidgetView(entry: entry)
                .containerBackground(Color("WidgetBackground"), for: .widget)
        }
        .configurationDisplayName("Daily Prompt")
        .description("Today's journaling prompt and your streak.")
        .supportedFamilies([.systemSmall])
    }
}
