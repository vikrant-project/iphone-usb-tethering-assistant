import Foundation
import os.log

public protocol ThermalMonitoring: Sendable {
    var currentThermalState: DeviceThermalState { get }
    var thermalUpdates: AsyncStream<ThermalSnapshot> { get }
    func startMonitoring() async
    func stopMonitoring() async
}

public final class ThermalMonitorService: ThermalMonitoring, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.tetherassistant.ios", category: "ThermalMonitor")
    private var streamContinuation: AsyncStream<ThermalSnapshot>.Continuation?
    private var observerToken: NSObjectProtocol?
    private let lock = NSLock()

    public private(set) var currentThermalState: DeviceThermalState = .nominal

    public lazy var thermalUpdates: AsyncStream<ThermalSnapshot> = {
        AsyncStream { continuation in
            self.lock.lock()
            self.streamContinuation = continuation
            self.lock.unlock()
            
            continuation.yield(self.buildSnapshot(for: self.currentThermalState))
        }
    }()

    public init() {
        self.currentThermalState = Self.mapState(ProcessInfo.processInfo.thermalState)
    }

    public func startMonitoring() async {
        logger.info("Starting Darwin thermal state observer")
        self.currentThermalState = Self.mapState(ProcessInfo.processInfo.thermalState)

        observerToken = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let newState = Self.mapState(ProcessInfo.processInfo.thermalState)
            self.currentThermalState = newState
            let snapshot = self.buildSnapshot(for: newState)
            self.logger.notice("Thermal state transition: \(newState.title, privacy: .public)")
            self.streamContinuation?.yield(snapshot)
        }
    }

    public func stopMonitoring() async {
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
            observerToken = nil
        }
        streamContinuation?.finish()
    }

    private func buildSnapshot(for state: DeviceThermalState) -> ThermalSnapshot {
        let recommendation: String
        switch state {
        case .nominal:
            recommendation = "Optimal operating temperature. USB tethering is running efficiently."
        case .fair:
            recommendation = "Minor heating detected. Keep the iPhone away from direct sunlight or heavy cases."
        case .serious:
            recommendation = "Thermal throttling active! Reduce screen brightness and disconnect fast chargers."
        case .critical:
            recommendation = "Emergency! Disconnect phone immediately to avoid emergency hardware shutdown."
        }
        return ThermalSnapshot(state: state, timestamp: Date(), recommendation: recommendation)
    }

    private static func mapState(_ state: ProcessInfo.ThermalState) -> DeviceThermalState {
        switch state {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .nominal
        }
    }
}

