# iOS Sandbox Limitations & API Feasibility Analysis

This document provides a rigorous, technical examination of Apple’s iOS sandbox, public frameworks, and operational constraints as they relate to USB tethering and companion monitoring.

---

## 1. Executive Feasibility Matrix

| Proposed Feature | Technical Feasibility | Public API Available? | Required Mechanism / Workaround |
| :--- | :--- | :--- | :--- |
| **Toggle Personal Hotspot On/Off** | ❌ **Impossible Programmatically** | ❌ None | **User Action Required**: Guide user via UI wizard to iOS Settings (`App-Prefs:root=INTERNET_TETHERING` or deep link). |
| **Enumerate Connected USB Hotspot Clients** | ❌ **Impossible Programmatically** | ❌ None | Internal to Darwin kernel daemon `tetheringd`. Monitored host-side via Windows Companion. |
| **Read USB Data Counters on iOS** | ❌ **Impossible for Third-Party Apps** | ❌ None | Sandboxed apps cannot read system-wide network interface counters (`pcap` / `sysctl` restricted). Throughput is measured on Windows. |
| **Monitor Thermal State** | ✅ **100% Feasible** | ✅ `ProcessInfo.thermalState` | Event-driven via `thermalStateDidChangeNotification`. |
| **Monitor Battery & Charging State** | ✅ **100% Feasible** | ✅ `UIDevice.batteryLevel`, `batteryState` | Event-driven via `batteryLevelDidChangeNotification` and `batteryStateDidChangeNotification`. |
| **Monitor Cellular Interface Status** | ✅ **100% Feasible** | ✅ `NWPathMonitor`, `CTTelephonyNetworkInfo` | Real-time path satisfying, interface type detection (`.cellular`), expensive/constrained flags. |
| **Acoustic & Local Push Notifications** | ✅ **100% Feasible** | ✅ `UserNotifications`, `AudioToolbox` | System alerts when thermal threshold reaches `.serious` or `.critical`. |
| **Continuous Background Execution (24/7)** | ❌ **Restricted by iOS Sandbox** | ⚠️ `BackgroundTasks` | Standard iOS apps cannot run infinite background loops without Audio/VoIP/Location modes (which waste battery). We use event-driven and foreground-first design. |
| **Inspect Windows Host Adapter from iOS** | ❌ **Impossible over USB without Socket Server** | ❌ None | Host-side NDIS adapter is managed entirely by the Windows Companion application. |

---

## 2. In-Depth Analysis of Critical iOS Subsystems

### 2.1 Personal Hotspot Control & Apple Restrictions
- **Apple's Security Model**: Network configuration and cellular routing are protected system privileges. Third-party applications run under the `mobile` user account with strict sandbox profiles applied by `container-metadata` and `sandboxd`.
- **Private Frameworks**: Frameworks such as `MobileWiFi.framework`, `CoreTelephony` private symbols (`CTServerConnectionSetCellularDataIsEnabled`), and `Preferences.framework` contain hooks to toggle hotspot status. However:
  1. Using them results in immediate rejection on the App Store.
  2. In modern iOS (iOS 16, 17, 18), these private APIs are guarded by root entitlements (`com.apple.wifi.manager-access`, `com.apple.CommCenter.cellular-control`) that are rejected by the kernel unless signed by Apple's internal platform certificates.
- **Architectural Solution**: The app provides an intuitive, high-fidelity setup wizard that clearly illustrates how to enable Personal Hotspot and handles deep-linking to iOS Settings.

---

### 2.2 USB Cable Detection vs. Charging State
When an iPhone is plugged into a Windows PC via USB:
- `UIDevice.current.batteryState` transitions from `.unplugged` to `.charging` (or `.full`).
- The iOS public SDK **does not provide a public API to query the USB PHY connection type** (e.g., distinguishing between a USB-C wall charger and a USB-C PC connection).
- **Correlative Detection Heuristic**:
  When the device is `.charging` AND `NWPathMonitor` indicates that local network routing is active, the app infers tethering mode.
  On the Windows PC, hardware presence is known with 100% certainty via PnP VID `05AC`.

---

### 2.3 Thermal State Throttling Architecture
`ProcessInfo.processInfo.thermalState` surfaces Darwin kernel thermal pressure levels:

```swift
switch ProcessInfo.processInfo.thermalState {
case .nominal:
    // Device is operating within standard thermal parameters.
    // Recommended: Standard operations.
case .fair:
    // Slight thermal elevation. Fans may spin up on host PC, minor iPhone heat.
    // Recommended: Warn user if concurrent fast charging is active.
case .serious:
    // Severe thermal elevation. iOS begins throttling AP CPU frequency,
    // display brightness is reduced, cellular modem throughput is capped.
    // Action: Fire immediate acoustic/haptic warning. Urge user to reduce screen brightness.
case .critical:
    // Thermal emergency. Cellular hardware shutdown imminent to prevent permanent battery damage.
    // Action: Fire urgent alarm. Urge immediate disconnection from charging.
@unknown default:
    break
}
```

#### Why Monitoring This is Revolutionary for Tethering:
Users typically leave their tethered iPhone tucked behind a monitor or under a laptop, completely unaware that the phone is baking at 46°C until the cellular connection drops. The iOS application acts as a **Thermal Sentinel**, audibly alerting the user before permanent battery degradation or connection drops occur.

---

### 2.4 Background Execution Constraints
Apple strictly enforces background limits:
- **`BGAppRefreshTask`**: Scheduled by the system machine-learning scheduler; cannot be forced to run continuously.
- **Audio / VoIP Background Modes**: Abusing Audio or VoIP background entitlements to keep an app awake when no audio is playing violates Apple Developer Guidelines and wastes significant battery, which directly contradicts the primary goal of our project (minimizing heat and power waste).
- **Foreground-First Paradigm**:
  The iOS application is engineered as an active monitoring console meant to be glanced at or run in StandBy mode / Auto-Lock Disabled mode. When backgrounded, it schedules local push notifications for critical state transitions.

