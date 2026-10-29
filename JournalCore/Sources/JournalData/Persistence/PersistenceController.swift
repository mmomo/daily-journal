import Foundation
import SwiftData

public enum PersistenceContext: Sendable {
    /// The app process: read/write, CloudKit sync when enabled.
    case app
    /// The widget extension: same store file, read-only, never syncs.
    case widget
}

public enum PersistenceController {
    public static let storeFileName = "Journal.store"

    static var schema: Schema { Schema([EntryRecord.self]) }

    public static func makeContainer(
        for context: PersistenceContext,
        configuration: AppConfiguration,
        inMemory: Bool = false
    ) throws -> ModelContainer {
        if inMemory {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, configurations: config)
        }

        let directory = try configuration.storeDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: storeFileName)

        let cloudKit: ModelConfiguration.CloudKitDatabase =
            context == .app && configuration.cloudKitEnabled
                ? .private(configuration.iCloudContainerIdentifier)
                : .none
        let config = ModelConfiguration(
            schema: schema,
            url: url,
            allowsSave: context == .app,
            cloudKitDatabase: cloudKit
        )
        return try ModelContainer(for: schema, configurations: config)
    }
}
