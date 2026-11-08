import SwiftUI

@main
struct TetherAssistantApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(container)
                .preferredColorScheme(.dark)
                .task {
                    await container.startAllServices()
                }
        }
    }
}

