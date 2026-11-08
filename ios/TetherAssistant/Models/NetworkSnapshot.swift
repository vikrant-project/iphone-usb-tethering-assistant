import Foundation

public enum InterfaceMedium: String, Sendable, Codable {
    case cellular = "Cellular (5G/LTE)"
    case wifi = "Wi-Fi (Wireless Hotspot Risk)"
    case wiredEthernet = "Wired Ethernet / USB"
    case other = "Other Interface"
}

public struct NetworkPathSnapshot: Sendable, Codable, Equatable {
    public let isSatisfied: Bool
    public let activeInterface: InterfaceMedium
    public let isExpensive: Bool
    public let isConstrained: Bool
    public let timestamp: Date
}

