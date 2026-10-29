import JournalDomain
import SwiftUI

@main
struct JournalApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var environment = AppEnvironment()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .onOpenURL { environment.handle(url: $0) }
                .task {
                    appDelegate.onDeepLink = { [environment] link in environment.pendingDeepLink = link }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await environment.becameActive() }
            }
        }
    }
}
