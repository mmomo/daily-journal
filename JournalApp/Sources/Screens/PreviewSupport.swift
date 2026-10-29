import JournalData
import JournalDomain

/// Use cases backed by in-memory storage, for SwiftUI previews only.
enum JournalEnvironmentFactoryPreview {
    static func useCases() throws -> JournalUseCases {
        try JournalEnvironmentFactory.makeInMemory().useCases
    }
}
