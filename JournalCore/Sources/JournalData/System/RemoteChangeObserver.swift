import CoreData
import Foundation

/// Watches for iCloud imports into the persistent store and calls `onChange` (debounced).
/// Used only in the app process; the widget never syncs (services.md S5).
@MainActor
public final class RemoteChangeObserver {
    private let debounce: Duration
    private let onChange: @MainActor @Sendable () async -> Void
    private var listener: Task<Void, Never>?
    private var pending: Task<Void, Never>?

    public init(debounce: Duration = .seconds(1), onChange: @escaping @MainActor @Sendable () async -> Void) {
        self.debounce = debounce
        self.onChange = onChange
    }

    public func start() {
        guard listener == nil else { return }
        listener = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: .NSPersistentStoreRemoteChange)
            for await _ in notifications {
                self?.schedule()
            }
        }
    }

    public func stop() {
        listener?.cancel()
        pending?.cancel()
        listener = nil
        pending = nil
    }

    private func schedule() {
        pending?.cancel()
        pending = Task { [debounce, onChange] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            await onChange()
        }
    }
}
