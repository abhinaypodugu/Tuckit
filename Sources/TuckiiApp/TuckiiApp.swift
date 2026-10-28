import SwiftUI
import TuckiiCore
import TuckiiUI

@main
struct TuckiiApp: App {
    @StateObject private var store = LibraryStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .preferredColorScheme(store.settings.darkMode ? .dark : .light)
        }
    }
}
