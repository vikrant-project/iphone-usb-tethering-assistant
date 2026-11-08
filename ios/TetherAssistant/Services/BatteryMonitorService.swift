import Foundation
import UIKit
import os.log

public protocol BatteryMonitoring: Sendable {
    var currentBatterySnapshot: BatterySnapshot { get }
    var batteryUpdates: AsyncStream<BatterySnapshot> { get }
    func startMonitoring() async
    func stopMonitoring() async
}

public final class BatteryMonitorService: BatteryMonitoring, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.tetherassistant.ios", category: "BatteryMonitor")
    private var streamContinuation: AsyncStream<BatterySnapshot>.Continuation?
    private var observers: [NSObjectProtocol] = []
    private let lock = NSLock()

    public private(set) var currentBatterySnapshot: BatterySnapshot

    public lazy var batteryUpdates: AsyncStream<BatterySnapshot> = {
        AsyncStream { continuation in
            self.lock.lock()
            self.streamContinuation = continuation
            self.lock.unlock()
            
            continuation.yield(self.currentBatterySnapshot)
        }
    }()

    public init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let rawLevel = Int(max(0.0, UIDevice.current.batteryLevel) * 100)
        let state = Self.mapPowerState(UIDevice.current.batteryState)
        self.currentBatterySnapshot = BatterySnapshot(
            levelPercent: rawLevel,
            state: state,
            timestamp: Date(),
            isHighTemperatureRisk: rawLevel > 80 && state != .unplugged
        )
    }

    public func startMonitoring() async {
        logger.info("Enabling UIDevice battery state monitoring")
        UIDevice.current.isBatteryMonitoringEnabled = true

        let levelObs = NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshSnapshot()
        }

        let stateObs = NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshSnapshot()
        }

        observers = [levelObs, stateObs]
    }

    public func stopMonitoring() async {
        for obs in observers {
            NotificationCenter.default.removeObserver(obs)
        }
        observers.removeAll()
        streamContinuation?.finish()
    }

    private func refreshSnapshot() {
        let rawLevel = Int(max(0.0, UIDevice.current.batteryLevel) * 100)
        let state = Self.mapPowerState(UIDevice.current.batteryState)
        let isRisk = rawLevel > 80 && state != .unplugged

        let snapshot = BatterySnapshot(
            levelPercent: rawLevel,
            state: state,
            timestamp: Date(),
            isHighTemperatureRisk: isRisk
        )
        self.currentBatterySnapshot = snapshot
        streamContinuation?.yield(snapshot)
    }

    private static func mapPowerState(_ state: UIDevice.BatteryState) -> BatteryPowerState {
        switch state {
        case .unknown: return .unknown
        case .unplugged: return .unplugged
        case .charging: return .charging(isFastCharging: false)
        case .full: return .full
        @unknown default: return .unknown
        }
    }
}

