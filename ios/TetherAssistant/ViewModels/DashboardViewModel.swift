import Foundation
import Combine
import SwiftUI

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public private(set) var thermalState: DeviceThermalState = .nominal
    @Published public private(set) var thermalRecommendation: String = "Normal"
    @Published public private(set) var batteryPercent: Int = 100
    @Published public private(set) var powerStateTitle: String = "Checking..."
    @Published public private(set) var isHighThermalRisk: Bool = false
    @Published public private(set) var activeMedium: InterfaceMedium = .cellular
    @Published public private(set) var isHotspotLikelyActive: Bool = false
    @Published public private(set) var sessionDurationFormatted: String = "00:00"

    private let thermalService: ThermalMonitoring
    private let batteryService: BatteryMonitoring
    private let networkService: NetworkDiagnostics
    private let sessionRepo: SessionRepository
    private var timerTask: Task<Void, Never>?
    private var sessionStartTime: Date?

    public init(
        thermalService: ThermalMonitoring,
        batteryService: BatteryMonitoring,
        networkService: NetworkDiagnostics,
        sessionRepo: SessionRepository
    ) {
        self.thermalService = thermalService
        self.batteryService = batteryService
        self.networkService = networkService
        self.sessionRepo = sessionRepo
    }

    public func startObserving() {
        Task {
            for await thermal in thermalService.thermalUpdates {
                self.thermalState = thermal.state
                self.thermalRecommendation = thermal.recommendation
            }
        }

        Task {
            for await battery in batteryService.batteryUpdates {
                self.batteryPercent = battery.levelPercent
                self.powerStateTitle = battery.state.title
                self.isHighThermalRisk = battery.isHighTemperatureRisk
                
                // If plugged into USB and battery is charging, infer session start
                if battery.state != .unplugged && self.sessionStartTime == nil {
                    self.startSessionTimer()
                } else if battery.state == .unplugged && self.sessionStartTime != nil {
                    self.stopSessionTimer()
                }
            }
        }

        Task {
            for await net in networkService.pathUpdates {
                self.activeMedium = net.activeInterface
                self.isHotspotLikelyActive = net.activeInterface == .cellular
            }
        }
    }

    private func startSessionTimer() {
        sessionStartTime = Date()
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let start = self.sessionStartTime else { break }
                let elapsed = Int(Date().timeIntervalSince(start))
                let m = elapsed / 60
                let s = elapsed % 60
                self.sessionDurationFormatted = String(format: "%02d:%02d", m, s)
            }
        }
    }

    private func stopSessionTimer() {
        timerTask?.cancel()
        timerTask = nil
        sessionStartTime = nil
        sessionDurationFormatted = "00:00"
    }
}

