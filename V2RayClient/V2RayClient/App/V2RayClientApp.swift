import SwiftUI

@main
struct V2RayClientApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .onAppear {
                    appState.storage.loadAll()
                }
        }
    }
}