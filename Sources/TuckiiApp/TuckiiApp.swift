import SwiftUI
import TuckiiCore
import TuckiiUI

@main
struct TuckiiApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var store: LibraryStore

    init() {
        let store = LibraryStore()
        if ProcessInfo.processInfo.arguments.contains("--seed-demo") {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            store.seedDemoData()
        }
        _store = StateObject(wrappedValue: store)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    HomeView()
                } else {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .environmentObject(store)
            .preferredColorScheme(store.settings.darkMode ? .dark : .light)
        }
    }
}
