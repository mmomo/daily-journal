public enum JournalError: Error, Equatable, Sendable {
    case emptyText
    case entryLocked
    case backfillNotAvailable
    case noRefreshesLeft
    case categoriesEmpty
    case notificationsDenied
    case nothingToExport
    /// A repository or store call failed; the message is for logs only.
    case storageFailure(String)
}
