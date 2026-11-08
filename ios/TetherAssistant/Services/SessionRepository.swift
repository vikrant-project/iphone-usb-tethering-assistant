import Foundation
import os.log

public protocol SessionRepository: Sendable {
    func startNewSession(initialBattery: Int, isCharging: Bool) async throws -> TetherSessionRecord
    func updateSession(_ session: TetherSessionRecord) async throws
    func endCurrentSession(finalBattery: Int, peakThermal: DeviceThermalState) async throws
    func fetchRecentSessions(limit: Int) async throws -> [TetherSessionRecord]
    func clearAllHistory() async throws
}

public actor LocalSessionRepository: SessionRepository {
    private let logger = Logger(subsystem: "com.tetherassistant.ios", category: "SessionRepository")
    private var activeSession: TetherSessionRecord?
    private var sessions: [TetherSessionRecord] = []
    private let storageKey = "com.tetherassistant.sessions"

    public init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([TetherSessionRecord].self, from: data) {
            self.sessions = decoded
        }
    }

    public func startNewSession(initialBattery: Int, isCharging: Bool) async throws -> TetherSessionRecord {
        let record = TetherSessionRecord(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            initialBatteryPercent: initialBattery,
            finalBatteryPercent: nil,
            peakThermalState: .nominal,
            wasCharging: isCharging
        )
        activeSession = record
        sessions.insert(record, at: 0)
        save()
        logger.info("New tethering session started: \(record.id.uuidString)")
        return record
    }

    public func updateSession(_ session: TetherSessionRecord) async throws {
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
            save()
        }
    }

    public func endCurrentSession(finalBattery: Int, peakThermal: DeviceThermalState) async throws {
        guard var session = activeSession else { return }
        session.endTime = Date()
        session.finalBatteryPercent = finalBattery
        session.peakThermalState = peakThermal
        activeSession = nil

        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
            save()
        }
        logger.info("Session ended. Final battery: \(finalBattery)%")
    }

    public func fetchRecentSessions(limit: Int) async throws -> [TetherSessionRecord] {
        return Array(sessions.prefix(limit))
    }

    public func clearAllHistory() async throws {
        sessions.removeAll()
        activeSession = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
        logger.info("Session history wiped securely.")
    }

    private func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

