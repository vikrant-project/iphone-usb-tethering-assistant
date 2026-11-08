import Foundation

public enum BatteryPowerState: Sendable, Codable, Equatable {
    case unknown
    case unplugged
    case charging(isFastCharging: Bool)
    case full

    public var title: String {
        switch self {
        case .unknown: return "Unknown"
        case .unplugged: return "Discharging (Unplugged)"
        case .charging(let fast): return fast ? "Fast Charging (High Heat Risk)" : "USB Standard Charging"
        case .full: return "Fully Charged"
        }
    }
}

public struct BatterySnapshot: Sendable, Codable, Equatable {
    public let levelPercent: Int
    public let state: BatteryPowerState
    public let timestamp: Date
    public let isHighTemperatureRisk: Bool
}

