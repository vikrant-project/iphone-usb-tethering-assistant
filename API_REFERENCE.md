# API Reference & Data Contracts

This document specifies the internal service contracts, protocols, models, and type definitions for both the iOS Application (`TetherAssistant`) and the Windows Companion (`TetherAssistant.Windows`).

---

## Part 1: iOS Application APIs (Swift 6)

### 1. Protocols & Service Interfaces

#### `ThermalMonitoring`
Monitors the device thermal state using Darwin kernel events and calculates thermal velocity.

```swift
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

    public var colorHex: String {
        switch self {
        case .nominal: return "#10B981" // Emerald Green
        case .fair: return "#F59E0B"    // Amber
        case .serious: return "#F97316" // Orange
        case .critical: return "#EF4444"// Crimson Red
        }
    }
}

public struct ThermalSnapshot: Sendable, Codable, Equatable {
    public let state: DeviceThermalState
    public let timestamp: Date
    public let recommendation: String
}

public protocol ThermalMonitoring: Sendable {
    /// Current instantaneous thermal state
    var currentThermalState: DeviceThermalState { get }
    
    /// Asynchronous stream of thermal state transitions
    var thermalUpdates: AsyncStream<ThermalSnapshot> { get }
    
    /// Starts thermal state observation
    func startMonitoring() async
    
    /// Stops thermal state observation
    func stopMonitoring() async
}
```

---

#### `BatteryMonitoring`
Tracks battery level, charging status, and charging rate hazards.

```swift
import Foundation

public enum BatteryPowerState: Sendable, Codable, Equatable {
    case unknown
    case unplugged
    case charging(isFastCharging: Bool)
    case full
}

public struct BatterySnapshot: Sendable, Codable, Equatable {
    public let levelPercent: Int       // 0 to 100
    public let state: BatteryPowerState
    public let timestamp: Date
    public let isHighTemperatureRisk: Bool
}

public protocol BatteryMonitoring: Sendable {
    /// Current battery snapshot
    var currentBatterySnapshot: BatterySnapshot { get }
    
    /// Asynchronous stream of battery level and power state changes
    var batteryUpdates: AsyncStream<BatterySnapshot> { get }
    
    /// Starts battery monitoring
    func startMonitoring() async
    
    /// Stops battery monitoring
    func stopMonitoring() async
}
```

---

#### `NetworkDiagnostics`
Monitors path status, network interface types, and cellular constraints using `Network.framework`.

```swift
import Foundation
import Network

public enum InterfaceMedium: String, Sendable, Codable {
    case cellular
    case wifi
    case wiredEthernet
    case other
}

public struct NetworkPathSnapshot: Sendable, Codable, Equatable {
    public let isSatisfied: Bool
    public let activeInterface: InterfaceMedium
    public let isExpensive: Bool
    public let isConstrained: Bool
    public let timestamp: Date
}

public protocol NetworkDiagnostics: Sendable {
    /// Returns current network path information
    var currentPathSnapshot: NetworkPathSnapshot { get }
    
    /// Asynchronous stream of network interface path transitions
    var pathUpdates: AsyncStream<NetworkPathSnapshot> { get }
    
    /// Starts the path monitor
    func startMonitoring() async
    
    /// Stops the path monitor
    func stopMonitoring() async
}
```

---

#### `SessionRepository`
Manages local SQLite / SwiftData storage for tethering duration and thermal trajectories.

```swift
import Foundation

public struct TetherSessionRecord: Identifiable, Sendable, Codable {
    public let id: UUID
    public let startTime: Date
    public var endTime: Date?
    public let initialBatteryPercent: Int
    public var finalBatteryPercent: Int?
    public var peakThermalState: DeviceThermalState
    public let wasCharging: Bool
}

public protocol SessionRepository: Sendable {
    func startNewSession(initialBattery: Int, isCharging: Bool) async throws -> TetherSessionRecord
    func updateSession(_ session: TetherSessionRecord) async throws
    func endCurrentSession(finalBattery: Int, peakThermal: DeviceThermalState) async throws
    func fetchRecentSessions(limit: Int) async throws -> [TetherSessionRecord]
    func clearAllHistory() async throws
}
```

---

## Part 2: Windows Companion APIs (C# / .NET)

### 1. Domain Models

#### `AdapterInfo.cs`
Represents the detected Apple USB Tethering interface.

```csharp
using System;
using System.Net;
using System.Net.NetworkInformation;

namespace TetherAssistant.Windows.Models;

public sealed record AdapterInfo
{
    public required string Id { get; init; }
    public required string Name { get; init; }
    public required string Description { get; init; }
    public required OperationalStatus Status { get; init; }
    public required IPAddress? IpAddress { get; init; }
    public required IPAddress? SubnetMask { get; init; }
    public required IPAddress? GatewayAddress { get; init; }
    public required IPAddress? DnsServer { get; init; }
    public required long SpeedBitsPerSecond { get; init; }
    public required bool IsAppleTethering { get; init; }
    public required DateTime DetectedAtUtc { get; init; }
}
```

---

#### `TelemetrySample.cs`
Continuous throughput sample.

```csharp
using System;

namespace TetherAssistant.Windows.Models;

public sealed record TelemetrySample
{
    public required DateTime TimestampUtc { get; init; }
    public required double DownloadSpeedMbps { get; init; }
    public required double UploadSpeedMbps { get; init; }
    public required long TotalBytesReceived { get; init; }
    public required long TotalBytesSent { get; init; }
    public required double SessionDownloadedMB { get; init; }
    public required double SessionUploadedMB { get; init; }
    public required TimeSpan SessionDuration { get; init; }
}
```

---

#### `DiagnosticResult.cs`
Diagnostic stage evaluation outcome.

```csharp
using System;
using System.Collections.Generic;

namespace TetherAssistant.Windows.Models;

public enum DiagnosticStage
{
    DriverAndPhysicalLink,
    GatewayReachability,
    DnsResolution,
    InternetWanReachability
}

public enum DiagnosticSeverity
{
    Pass,
    Warning,
    Failure
}

public sealed record DiagnosticStageResult
{
    public required DiagnosticStage Stage { get; init; }
    public required string StageName { get; init; }
    public required DiagnosticSeverity Severity { get; init; }
    public required double LatencyMilliseconds { get; init; }
    public required string? Details { get; init; }
    public required string? TroubleshootingAdvice { get; init; }
}

public sealed record DiagnosticSuiteResult
{
    public required DateTime TimestampUtc { get; init; }
    public required bool IsHealthy { get; init; }
    public required IReadOnlyList<DiagnosticStageResult> Stages { get; init; }
    public required string OverallSummary { get; init; }
}
```

---

### 2. Service Interfaces

#### `INetworkAdapterService.cs`
```csharp
using System;
using System.Threading;
using System.Threading.Tasks;
using TetherAssistant.Windows.Models;

namespace TetherAssistant.Windows.Services;

public interface INetworkAdapterService
{
    /// <summary>
    /// Event fired whenever an Apple USB network adapter connects or disconnects.
    /// </summary>
    event EventHandler<AdapterInfo?>? AdapterStateChanged;

    /// <summary>
    /// Gets the current active Apple USB Tethering adapter, or null if disconnected.
    /// </summary>
    AdapterInfo? CurrentAdapter { get; }

    /// <summary>
    /// Scans the system for Apple USB Ethernet / CDC-NCM interfaces.
    /// </summary>
    Task<AdapterInfo?> ScanForAdapterAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Begins listening to PnP and NetworkChange event triggers.
    /// </summary>
    void StartListening();

    /// <summary>
    /// Stops listening to events.
    /// </summary>
    void StopListening();
}
```

---

#### `ITelemetryService.cs`
```csharp
using System;
using System.Threading;
using System.Threading.Tasks;
using TetherAssistant.Windows.Models;

namespace TetherAssistant.Windows.Services;

public interface ITelemetryService
{
    /// <summary>
    /// Event raised every second with new throughput and data consumption figures.
    /// </summary>
    event EventHandler<TelemetrySample>? TelemetryUpdated;

    /// <summary>
    /// Starts high-precision periodic telemetry sampling for the target adapter.
    /// </summary>
    void StartSampling(string networkInterfaceId);

    /// <summary>
    /// Stops telemetry sampling and saves session stats to SQLite.
    /// </summary>
    Task StopSamplingAsync();

    /// <summary>
    /// Current instantaneous sample.
    /// </summary>
    TelemetrySample? LatestSample { get; }
}
```

---

#### `IDiagnosticsService.cs`
```csharp
using System.Threading;
using System.Threading.Tasks;
using TetherAssistant.Windows.Models;

namespace TetherAssistant.Windows.Services;

public interface IDiagnosticsService
{
    /// <summary>
    /// Runs all 4 diagnostic stages sequentially against the tethered iPhone interface.
    /// </summary>
    Task<DiagnosticSuiteResult> RunFullDiagnosticsAsync(CancellationToken cancellationToken = default);
}
```
