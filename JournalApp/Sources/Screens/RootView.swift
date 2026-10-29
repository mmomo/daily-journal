import JournalData
import JournalDomain
import SwiftUI

/// Chooses between startup error, onboarding and the Today screen.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var onboarded: Bool?

    var body: some View {
        Group {
            if let error = environment.startupError {
                ContentUnavailableView {
                    Label("Can't open your journal", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") { environment.retry() }
                }
            } else if let useCases = environment.useCases, let onboarded {
                if onboarded {
                    NavigationStack {
                        TodayView(useCases: useCases)
                    }
                } else {
                    OnboardingView(useCases: useCases) {
                        self.onboarded = true
                        environment.refresh()
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            environment.start()
        }
        .task(id: environment.useCases != nil) {
            if let useCases = environment.useCases {
                onboarded = useCases.getSettings.execute().onboardingCompleted
            }
        }
    }
}

#Preview("Today") {
    RootView().environment(AppEnvironment.preview())
}

#Preview("Onboarding") {
    RootView().environment(AppEnvironment.preview(onboarded: false))
}
