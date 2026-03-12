import SwiftUI

@main
struct WanderApp: App {
    @StateObject private var store = EntryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
