import Foundation
import JournalDomain

extension CalendarDay {
    /// "Thursday, October 8"
    var longTitle: String {
        start(in: .autoupdatingCurrent).formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    /// "Oct 8, 2026"
    var shortTitle: String {
        start(in: .autoupdatingCurrent).formatted(.dateTime.month(.abbreviated).day().year())
    }
}

extension PromptCategory {
    var title: String {
        switch self {
        case .gratitude: "Gratitude"
        case .reflection: "Reflection"
        case .goals: "Goals"
        case .creativity: "Creativity"
        }
    }

    var symbol: String {
        switch self {
        case .gratitude: "heart"
        case .reflection: "leaf"
        case .goals: "flag"
        case .creativity: "paintbrush"
        }
    }
}

extension ReminderSettings {
    /// Today's date at the reminder time, for `DatePicker`.
    var timeOfDay: Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    func with(time: Date) -> ReminderSettings {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        return ReminderSettings(isEnabled: isEnabled, hour: parts.hour ?? hour, minute: parts.minute ?? minute)
    }
}
