import Foundation
import Network
import os.log

public protocol NetworkDiagnostics: Sendable {
    var currentPathSnapshot: NetworkPathSnapshot { get }
    var pathUpdates: AsyncStream<NetworkPathSnapshot> { get }
    func startMonitoring() async
    func stopMonitoring() async
}

public final class NetworkDiagnosticsService: NetworkDiagnostics, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.tetherassistant.ios", category: "NetworkDiagnostics")
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.tetherassistant.networkmonitor")
    private var streamContinuation: AsyncStream<NetworkPathSnapshot>.Continuation?
    private let lock = NSLock()

    public private(set) var currentPathSnapshot: NetworkPathSnapshot

    public lazy var pathUpdates: AsyncStream<NetworkPathSnapshot> = {
        AsyncStream { continuation in
            self.lock.lock()
            self.streamContinuation = continuation
            self.lock.unlock()
            
            continuation.yield(self.currentPathSnapshot)
        }
    }()

    public init() {
        self.currentPathSnapshot = NetworkPathSnapshot(
            isSatisfied: true,
            activeInterface: .cellular,
            isExpensive: true,
            isConstrained: false,
            timestamp: Date()
        )
    }

    public func startMonitoring() async {
        logger.info("Starting NWPathMonitor for interface state detection")
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let medium: InterfaceMedium
            if path.usesInterfaceType(.cellular) {
                medium = .cellular
            } else if path.usesInterfaceType(.wifi) {
                medium = .wifi
            } else if path.usesInterfaceType(.wiredEthernet) {
                medium = .wiredEthernet
            } else {
                medium = .other
            }

            let snapshot = NetworkPathSnapshot(
                isSatisfied: path.status == .satisfied,
                activeInterface: medium,
                isExpensive: path.isExpensive,
                isConstrained: path.isConstrained,
                timestamp: Date()
            )

            self.currentPathSnapshot = snapshot
            self.streamContinuation?.yield(snapshot)
        }
        monitor.start(queue: monitorQueue)
    }

    public func stopMonitoring() async {
        monitor.cancel()
        streamContinuation?.finish()
    }
}

