import Foundation

public struct TetherSessionRecord: Identifiable, Sendable, Codable {
    public let id: UUID
    public let startTime: Date
    public var endTime: Date?
    public let initialBatteryPercent: Int
    public var finalBatteryPercent: Int?
    public var peakThermalState: DeviceThermalState
    public let wasCharging: Bool

    public var durationFormatted: String {
        let end = endTime ?? Date()
        let interval = end.timeIntervalSince(startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }
}

