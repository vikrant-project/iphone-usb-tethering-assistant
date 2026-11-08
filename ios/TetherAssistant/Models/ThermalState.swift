import Foundation

public enum DeviceThermalState: Int, Sendable, CaseIterable, Codable {
    case nominal = 0
    case fair = 1
    case serious = 2
    case critical = 3

    public var title: String {
        switch self {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        }
    }

    public var shortDescription: String {
        switch self {
        case .nominal: return "Device temperature is normal. Full performance."
        case .fair: return "Minor warmth. Safe for long-term tethering."
        case .serious: return "High temperature! Cellular throttling active."
        case .critical: return "Emergency! Thermal shutdown risk imminent."
        }
    }
}

public struct ThermalSnapshot: Sendable, Codable, Equatable {
    public let state: DeviceThermalState
    public let timestamp: Date
    public let recommendation: String
}

