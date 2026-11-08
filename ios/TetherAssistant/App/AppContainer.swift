import Foundation
import Combine

@MainActor
public final class AppContainer: ObservableObject {
    public let thermalMonitor: ThermalMonitoring
    public let batteryMonitor: BatteryMonitoring
    public let networkDiagnostics: NetworkDiagnostics
    public let sessionRepository: SessionRepository

    public init() {
        self.thermalMonitor = ThermalMonitorService()
        self.batteryMonitor = BatteryMonitorService()
        self.networkDiagnostics = NetworkDiagnosticsService()
        self.sessionRepository = LocalSessionRepository()
    }

    public func startAllServices() async {
        await thermalMonitor.startMonitoring()
        await batteryMonitor.startMonitoring()
        await networkDiagnostics.startMonitoring()
    }

    public func stopAllServices() async {
        await thermalMonitor.stopMonitoring()
        await batteryMonitor.stopMonitoring()
        await networkDiagnostics.stopMonitoring()
    }
}

