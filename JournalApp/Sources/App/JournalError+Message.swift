import JournalDomain

extension JournalError {
    /// User-facing wording (entities §6); the Domain stays free of UI text.
    var message: String {
        switch self {
        case .emptyText: "Write something first."
        case .entryLocked: "This entry is locked."
        case .backfillNotAvailable: "Yesterday can no longer be filled in."
        case .noRefreshesLeft: "No refreshes left today."
        case .categoriesEmpty: "Choose at least one category."
        case .notificationsDenied: "Notifications are off for Daily Journal in Settings."
        case .nothingToExport: "No entries to export yet."
        case .storageFailure: "Couldn't save. Please try again."
        }
    }
}

func userMessage(for error: Error) -> String {
    (error as? JournalError)?.message ?? "Something went wrong. Please try again."
}
