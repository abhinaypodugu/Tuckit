import SwiftUI
import TuckiiCore
import TuckiiUI

@main
struct TuckiiApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var store: LibraryStore

    private let screenOverride: String?

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let screenArgument = arguments
            .first { $0.hasPrefix("--screen=") }?
            .replacingOccurrences(of: "--screen=", with: "")
        screenOverride = screenArgument

        let store = LibraryStore()
        if screenArgument == "onboarding" {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        } else if arguments.contains("--seed-demo") || screenArgument != nil {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            store.seedDemoData()
        }
        _store = StateObject(wrappedValue: store)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let screenOverride {
                    overrideScreen(screenOverride)
                } else if hasCompletedOnboarding {
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

    @ViewBuilder
    private func overrideScreen(_ screen: String) -> some View {
        switch screen {
        case "collection":
            NavigationStack {
                CollectionScreen(collectionID: demoCollectionID)
            }
        case "details":
            NavigationStack {
                LinkDetailView(bookmarkID: store.bookmarks.first?.id ?? UUID())
            }
        case "search":
            SearchView()
        case "settings":
            SettingsView()
        case "focus":
            FocusModeView(collectionID: nil)
        case "paywall":
            PaywallView {}
        case "onboarding":
            OnboardingView {}
        default:
            HomeView()
        }
    }

    private var demoCollectionID: UUID {
        store.collections.first(where: { !$0.isSystem })?.id ?? store.unsorted.id
    }
}
