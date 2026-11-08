# System Architecture & Design Specification

## 1. High-Level Architectural Topology

The USB Tethering Assistant ecosystem is designed around an **independent, zero-cloud, decoupled architecture**. Both the iOS application and the Windows companion operate autonomously while complementing each other when tethered via a standard USB cable.

```mermaid
flowchart TB
    subgraph iOS_Device["iPhone (iOS 16.0 - 18.x)"]
        subgraph iOS_App["TetherAssistant (SwiftUI 6.0)"]
            iOS_UI["SwiftUI Views (Dashboard, Health, Setup, Logs)"]
            iOS_VM["Observable ViewModels"]
            iOS_Services["Domain Services (Thermal, Battery, Network, Session)"]
            iOS_Storage["Local Storage (SQLite / SwiftData)"]
        end
        subgraph iOS_OS["Native iOS Core"]
            iOS_Kernel["Darwin Kernel & Power Management"]
            iOS_Hotspot["Personal Hotspot Daemon (tetheringd)"]
            iOS_USB_Driver["Apple USB NCM / CDC Ethernet Controller"]
        end
    end

    subgraph Physical_Medium["Physical USB Interconnect"]
        Cable["USB-C to Lightning / USB-C to USB-C Cable"]
    end

    subgraph Windows_Host["Windows 10 / 11 Host PC"]
        subgraph Win_OS["Windows OS Kernel & Subsystems"]
            Win_PnP["Plug and Play Subsystem (PnP / WMI)"]
            Win_NDIS["NDIS Network Stack"]
            Apple_Adapter["Apple Mobile Device Ethernet / UsbNcm Adapter (172.20.10.1 Gateway)"]
        end
        subgraph Win_App["TetherAssistant.Windows (WinUI 3 / .NET)"]
            Win_Services["Monitoring Services (Adapter, Telemetry, Diagnostics)"]
            Win_VM["CommunityToolkit.Mvvm ViewModels"]
            Win_UI["WinUI 3 Fluent Views (Mica, Dark Theme)"]
            Win_Storage["Local SQLite Database (WAL Mode)"]
        end
    end

    iOS_App --> iOS_OS
    iOS_Hotspot --> iOS_USB_Driver
    iOS_USB_Driver <--> Cable <--> Apple_Adapter
    Apple_Adapter --> Win_NDIS
    Win_NDIS --> Win_Services
    Win_PnP --> Win_Services
    Win_Services --> Win_VM --> Win_UI
    Win_Services --> Win_Storage
```

### Architectural Principles
1. **Decoupled Operation**: Neither client requires a proprietary IPC daemon, peer-to-peer TCP socket, or cloud relay between the phone and PC. The communication channel is strictly the standard NDIS network interface created by native Apple USB tethering.
2. **Platform Native Concurrency**:
   - iOS leverages **Swift 6 Structured Concurrency** (`async`/`await`, actors, `AsyncStream`) with `@MainActor` binding for SwiftUI rendering.
   - Windows leverages modern **C# Task Asynchronous Pattern (TAP)**, thread pool offloading, and WinUI 3 `DispatcherQueue` dispatching.
3. **Zero Polling Where Possible**:
   - iOS: Uses OS-level event notifications (`ProcessInfo.thermalStateDidChangeNotification`, `UIDevice.batteryLevelDidChangeNotification`, `NWPathMonitor` update handlers).
   - Windows: Uses `NetworkChange.NetworkAddressChanged`, `NetworkChange.NetworkAvailabilityChanged`, and WMI event listeners (`__InstanceOperationEvent`) for hardware insertions/removals. Polling is restricted strictly to active throughput counters (1-second intervals during active data transfer).
4. **Privacy-First Local Persistence**: All connection logs, throughput metrics, and thermal history stay on the local device inside SQLite / SwiftData databases. No telemetry is transmitted over the internet.

---

## 2. iOS Application Architecture (`TetherAssistant`)

The iOS application follows the **Clean MVVM (Model-View-ViewModel)** pattern with strict protocol-oriented dependency injection.

```mermaid
flowchart TD
    subgraph UI_Layer["UI Presentation Layer"]
        V1["DashboardView"]
        V2["SetupGuideView"]
        V3["DeviceHealthView"]
        V4["HistoryView"]
        V5["SettingsView"]
    end

    subgraph ViewModel_Layer["Presentation State Layer (@MainActor)"]
        VM1["DashboardViewModel"]
        VM2["DeviceHealthViewModel"]
        VM3["HistoryViewModel"]
        VM4["SettingsViewModel"]
    end

    subgraph Domain_Service_Layer["Domain Service Layer (Actors & Services)"]
        S1["ThermalMonitorService (Protocol: ThermalMonitoring)"]
        S2["BatteryMonitorService (Protocol: BatteryMonitoring)"]
        S3["NetworkDiagnosticsService (Protocol: NetworkDiagnostics)"]
        S4["SessionTrackingService (Protocol: SessionTracking)"]
        S5["NotificationService (Protocol: NotificationHandling)"]
    end

    subgraph Core_Data_Layer["Persistence & System Layer"]
        Repo["LocalSessionRepository (Protocol: SessionRepository)"]
        DB[("Encrypted Local SQLite Database")]
        Sys1["ProcessInfo.processInfo"]
        Sys2["UIDevice.current"]
        Sys3["Network.framework (NWPathMonitor)"]
    end

    V1 --> VM1
    V3 --> VM2
    V4 --> VM3
    V5 --> VM4

    VM1 --> S1
    VM1 --> S2
    VM1 --> S3
    VM1 --> S4

    VM2 --> S1
    VM2 --> S2

    VM3 --> Repo

    S1 --> Sys1
    S2 --> Sys2
    S3 --> Sys3
    S4 --> Repo
    Repo --> DB
```

### Component Breakdown

#### Presentation Layer (SwiftUI Views)
- **Declarative Navigation**: Implemented via `NavigationStack` with typed destination enums.
- **Dynamic Theming**: Custom dark color palette optimized for OLED displays (pure blacks `#000000`, deep zinc `#121214`, and vibrant semantic accents: emerald `#10B981`, amber `#F59E0B`, crimson `#EF4444`).
- **Responsive Gauges**: Custom SwiftUI canvas and shape animations for battery discharge vectors and thermal gradients.

#### ViewModel Layer
- Each view model is annotated with `@MainActor` and conforms to `ObservableObject` (or uses the Swift 5.9+ `@Observable` macro).
- ViewModels receive protocols via initializer injection, allowing for 100% mocked unit tests without hardware dependencies.
- Exposes immutable state structures and reactive publishers (`AsyncStream` or `@Published`).

#### Domain Service Layer
- **`ThermalMonitorService`**:
  - Subscribes to `ProcessInfo.thermalStateDidChangeNotification`.
  - Normalizes raw `ProcessInfo.ThermalState` (`.nominal`, `.fair`, `.serious`, `.critical`) into domain events.
  - Generates adaptive cooldown recommendations based on state velocity (rapid jump from nominal to serious).
- **`BatteryMonitorService`**:
  - Activates `UIDevice.current.isBatteryMonitoringEnabled = true`.
  - Monitors `batteryLevel` (0.0 to 1.0) and `batteryState` (`.unplugged`, `.charging`, `.full`).
  - Detects high thermal charging risk (e.g. charging when thermal state is `>= .serious`).
- **`NetworkDiagnosticsService`**:
  - Uses `Network.framework`'s `NWPathMonitor` to observe path interface status.
  - Identifies cellular technology indicators (`CTTelephonyNetworkInfo` for 5G NR, LTE, etc.).
  - Evaluates constrained/expensive data flags.
- **`SessionTrackingService`**:
  - Encapsulates active tethering sessions, computes elapsed connection time, thermal peaks, and persists to repository.

---

## 3. Windows Companion Architecture (`TetherAssistant.Windows`)

The Windows application is built on **.NET 8 / 9 / 10** utilizing **WinUI 3** and the **Windows App SDK** (WASDK), structured with the **CommunityToolkit.Mvvm** framework.

```mermaid
flowchart TD
    subgraph WinUI_Views["Presentation Layer (WinUI 3 / XAML)"]
        WV1["DashboardPage.xaml"]
        WV2["NetworkPage.xaml"]
        WV3["DiagnosticsPage.xaml"]
        WV4["SettingsPage.xaml"]
        WShell["MainWindow.xaml (NavigationView + Mica)"]
    end

    subgraph Win_ViewModels["ViewModel Layer (CommunityToolkit.Mvvm)"]
        WVM1["DashboardViewModel"]
        WVM2["NetworkViewModel"]
        WVM3["DiagnosticsViewModel"]
        WVM4["SettingsViewModel"]
    end

    subgraph Win_Services["Domain Services (DI Injected)"]
        WS1["NetworkAdapterService (INetworkAdapterService)"]
        WS2["TelemetryService (ITelemetryService)"]
        WS3["DiagnosticsService (IDiagnosticsService)"]
        WS4["TroubleshootingService (ITroubleshootingService)"]
        WS5["NotificationService (INotificationService)"]
    end

    subgraph Win_Infrastructure["Infrastructure & OS Interop"]
        PnP["Windows PnP / WMI Service (DeviceArrival/Removal)"]
        NDIS["System.Net.NetworkInformation.NetworkInterface"]
        NetChange["NetworkChange (NetworkAddressChanged)"]
        RawSockets["System.Net.Sockets / ICMP Ping"]
        SqliteRepo["SessionRepository (Microsoft.Data.Sqlite)"]
    end

    WShell --> WV1
    WShell --> WV2
    WShell --> WV3
    WShell --> WV4

    WV1 --> WVM1
    WV2 --> WVM2
    WV3 --> WVM3
    WV4 --> WVM4

    WVM1 --> WS1
    WVM1 --> WS2
    WVM2 --> WS1
    WVM2 --> WS2
    WVM3 --> WS3
    WVM3 --> WS4

    WS1 --> PnP
    WS1 --> NDIS
    WS1 --> NetChange
    WS2 --> NDIS
    WS3 --> RawSockets
    WS2 --> SqliteRepo
```

### Component Breakdown

#### Adapter Detection Engine (`NetworkAdapterService`)
Unlike legacy utilities that check if the adapter string contains `"Apple Mobile Device Ethernet"` (which fails on non-English Windows or when Windows 11 binds generic UsbNcm drivers), this engine applies a **multi-factor heuristic**:
1. **PnP Device ID Check**: Inspects WMI `Win32_PnPEntity` for Apple's USB Vendor ID (`VID_05AC`).
2. **Subnet & Gateway Signature**: Evaluates whether the IPv4 gateway equals `172.20.10.1` and subnet mask is `255.255.255.240` (`/28`).
3. **NDIS Hardware Interface Type**: Asserts the interface physical medium is `NetworkInterfaceType.Ethernet` and not loopback or tunnel.

#### Live Telemetry Engine (`TelemetryService`)
- Subscribes to adapter state changes.
- Samples `IPv4InterfaceStatistics.BytesReceived` and `BytesSent` at 1000ms intervals using a low-overhead background `System.Threading.PeriodicTimer`.
- Derives instant throughput (Mbps), cumulative session payload, and packet loss rate.
- Posts metrics to the UI thread via `DispatcherQueue` without UI stutter.

#### Diagnostics Engine (`DiagnosticsService`)
Executes an isolated 4-stage pipeline returning detailed latency and error codes:
```mermaid
sequenceDiagram
    autonumber
    participant D as DiagnosticsEngine
    participant NDIS as Network Interface
    participant GW as Gateway (172.20.10.1)
    participant DNS as DNS Resolver
    participant WAN as Cloud HTTP Probe

    D->>NDIS: 1. Validate NDIS Link Up & DHCP Configured
    alt Link Down
        D-->>D: Fail (Stage 1: Hardware/Driver Error)
    else Link Up
        D->>GW: 2. ICMP Echo (172.20.10.1)
        alt Gateway Unresponsive
            D-->>D: Fail (Stage 2: iPhone Tethering Gateway Down)
        else Gateway Echo Reply (<2ms)
            D->>DNS: 3. Resolve "one.one.one.one" / "dns.google"
            alt DNS Timeout / NXDOMAIN
                D-->>D: Fail (Stage 3: Cellular DNS Blocked / No Data)
            else DNS Resolved
                D->>WAN: 4. HTTP GET /generate_204 (Cloudflare/MSFT)
                alt HTTP Probe 204 Received
                    D-->>D: Pass (Full Internet Functional)
                else Probe Fails / Captive Portal
                    D-->>D: Fail (Stage 4: Carrier Throttling or Captive Portal)
                end
            end
        end
    end
```

---

## 4. Cross-Platform Data Contracts & Schemas

Even though the apps do not establish a continuous network socket between them (to avoid complex pairing, firewall restrictions, and security risks), they share standardized domain schemas for diagnostic data, session history, and metrics.

### Diagnostic Result Model (`shared/schemas/diagnostic_result.json`)
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "DiagnosticResult",
  "type": "object",
  "properties": {
    "timestampUtc": { "type": "string", "format": "date-time" },
    "overallStatus": { "type": "string", "enum": ["Healthy", "Degraded", "Failed"] },
    "stages": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "stageName": { "type": "string" },
          "isPassed": { "type": "boolean" },
          "latencyMs": { "type": "number" },
          "errorMessage": { "type": ["string", "null"] }
        },
        "required": ["stageName", "isPassed", "latencyMs"]
      }
    },
    "recommendation": { "type": "string" }
  },
  "required": ["timestampUtc", "overallStatus", "stages"]
}
```

---

## 5. Persistence Architecture

### Windows Persistence (`SQLite`)
- Engine: `Microsoft.Data.Sqlite`
- Journal Mode: `PRAGMA journal_mode = WAL;` (Write-Ahead Logging for high read/write concurrency).
- Synchronous Mode: `PRAGMA synchronous = NORMAL;` (optimal balance between performance and durability).
- Schema:
  - `sessions`: `id (UUID)`, `startTime (INTEGER)`, `endTime (INTEGER)`, `bytesReceived (INTEGER)`, `bytesSent (INTEGER)`, `peakThroughputMbps (REAL)`, `adapterName (TEXT)`.
  - `diagnostic_logs`: `id (UUID)`, `sessionId (UUID)`, `timestamp (INTEGER)`, `stage (TEXT)`, `passed (INTEGER)`, `latencyMs (REAL)`, `details (TEXT)`.

### iOS Persistence (`SwiftData / SQLite`)
- Stores thermal events and battery discharge snapshots.
- Schema:
  - `TetherSession`: `id (UUID)`, `startedAt (Date)`, `endedAt (Date?)`, `initialBatteryPercent (Float)`, `finalBatteryPercent (Float?)`, `peakThermalState (Int)`, `wasCharging (Bool)`.
  - `ThermalEvent`: `timestamp (Date)`, `state (Int)`, `deviceModel (String)`, `batteryLevel (Float)`.

---

## 6. Resource Efficiency & Performance Targets

| Metric | iOS App Target | Windows App Target |
| :--- | :--- | :--- |
| **Idle CPU Usage** | < 0.1% | < 0.2% |
| **Active Telemetry CPU** | < 1.0% (Screen On) | < 1.5% (1s polling) |
| **RAM Footprint** | < 35 MB | < 65 MB |
| **App Launch Time (Cold)** | < 450 ms | < 800 ms |
| **Diagnostic Execution Time**| < 2.5 seconds | < 2.0 seconds |
| **Disk Write Rate** | Batched every 60s (<10 KB) | Batched every 30s (<15 KB) |
