import SwiftUI

public struct MainTabView: View {
    @EnvironmentObject var container: AppContainer
    @State private var selectedTab = 0

    public var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: DashboardViewModel(
                thermalService: container.thermalMonitor,
                batteryService: container.batteryMonitor,
                networkService: container.networkDiagnostics,
                sessionRepo: container.sessionRepository
            ))
            .tabItem {
                Label("Home", systemImage: "bolt.horizontal.fill")
            }
            .tag(0)

            SetupGuideView()
                .tabItem {
                    Label("USB Setup", systemImage: "cable.connector")
                }
                .tag(1)

            DeviceHealthView(viewModel: container)
                .tabItem {
                    Label("Device Health", systemImage: "flame.fill")
                }
                .tag(2)

            HistoryView(repository: container.sessionRepository)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(3)

            SettingsView(repository: container.sessionRepository)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Theme.accent)
    }
}

