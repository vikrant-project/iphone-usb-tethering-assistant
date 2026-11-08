# iPhone USB Tethering Assistant & Windows Companion

[![Platform iOS](https://img.shields.io/badge/iOS-16.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Platform Windows](https://img.shields.io/badge/Windows-10%20%2F%2011-0078D6.svg)](https://microsoft.com/windows)
[![.NET Version](https://img.shields.io/badge/.NET-8.0%20%2F%209.0%20%2F%2010.0-purple.svg)](https://dotnet.microsoft.com/)
[![UI Framework](https://img.shields.io/badge/UI-SwiftUI%20%2F%20WinUI%203-brightgreen.svg)](https://learn.microsoft.com/windows/apps/winui/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

An enterprise-grade, privacy-first companion ecosystem designed to optimize, monitor, and troubleshoot wired USB Internet tethering between iPhones and Windows PCs.

---

## 1. Executive Overview

### The Problem
Wireless Personal Hotspots (Wi-Fi tethering) subject iPhones to severe thermal stress, sustained high battery drain, RF contention, and connection jitter. Over prolonged periods (remote work, gaming, downloading large files), Wi-Fi hotspotting causes:
- Aggressive thermal throttling (dimmed displays, dropped frame rates, cellular modem fallback).
- Lithium-ion battery degradation from concurrent fast charging and multi-band radio heat dissipation.
- Dropped packets and variable latency caused by 2.4 GHz / 5 GHz interference in crowded environments.

### The Solution
Native Apple USB Tethering transmits network traffic over a high-bandwidth, shielded physical USB interface (USB 2.0 / USB 3.0 / USB-C depending on iPhone model). This eliminates wireless RF transmission overhead, reduces device temperature by **6°C to 12°C**, and guarantees ultra-low jitter (<2ms round-trip to the local gateway).

However, Apple's USB tethering on Windows suffers from critical usability pain points:
1. **Driver Ambiguity**: Windows requires the Apple Mobile Device Ethernet driver or modern UsbNcm driver, which frequently fails to load if iTunes or Apple Devices service is corrupted or missing.
2. **Black-Box Status**: Neither iOS nor Windows displays live USB throughput, adapter health, gateway status, or thermal throttling alerts in a single coherent interface.
3. **Overheating While Charging**: Connecting an iPhone via USB to a PC motherboard frequently triggers continuous 5V 1.5A–2.0A or USB-PD charging while data flows, causing battery heating if not monitored intelligently.

### What This Suite Does
- **iOS Application (`TetherAssistant`)**: A lightweight, standalone SwiftUI utility monitoring battery health, thermal state transitions, charging metrics, cellular path states, and tethering duration with smart acoustic/haptic thermal warnings.
- **Windows Companion (`TetherAssistant.Windows`)**: A modern WinUI 3 desktop application that dynamically detects Apple USB network interfaces without brittle string matching, validates the `172.20.10.0/28` gateway subnet, streams real-time telemetry, runs automated diagnostics, and resolves driver/DNS issues.

---

## 2. Key Features

### iOS Application
- **Modern Minimal Dark Dashboard**: Real-time display of battery percentage, charging state, thermal state (`Nominal`, `Fair`, `Serious`, `Critical`), and active network interface.
- **USB Setup Assistant**: Interactive, visual step-by-step wizard guiding the user through USB connection, Trust Prompt verification, and iOS Personal Hotspot activation.
- **Smart Thermal Sentinel**: Event-driven thermal state monitoring with audio-visual notifications and actionable recommendations (e.g., lower screen brightness, switch to low-power USB port, avoid direct sunlight).
- **Session History & Analytics**: Local encrypted SQLite/SwiftData repository tracking tethering duration, thermal trajectory, and session frequency without external tracking.
- **Zero Jailbreak / 100% App Store & Sideload Compliant**: Uses only public Apple frameworks (`ProcessInfo`, `UIKit`, `Network`, `UserNotifications`, `OSLog`).

### Windows Companion Application
- **Hardware-Agnostic Adapter Detection**: Uses PnP Hardware IDs (`VID_05AC`), NDIS interface type, and gateway IP heuristics (`172.20.10.1`) rather than localized string scraping.
- **Real-Time Bandwidth & Data Telemetry**: Live sampling of NDIS byte counters (`BytesReceived`, `BytesSent`) converted into throughput gauges and historical session logs.
- **End-to-End Diagnostics Engine**: Automated 4-tier health check:
  1. *Physical Layer / USB NCM Driver Check*
  2. *DHCP & Gateway ICMP Probe (`172.20.10.1`)*
  3. *DNS Resolution Probe (`172.20.10.1` & upstream servers)*
  4. *WAN Connectivity & HTTP 204 Probe*
- **Automated Repair Guidance**: Detects missing Apple Mobile Device Ethernet drivers, DNS deadlocks, or IP address conflicts and provides one-click troubleshooting guides.
- **Modern WinUI 3 & Fluent Design**: Dark mode interface built with Windows App SDK, Mica material, and responsive data charts.

---

## 3. Technology Stack

| Layer | iOS App (`TetherAssistant`) | Windows Companion (`TetherAssistant.Windows`) |
| :--- | :--- | :--- |
| **Language** | Swift 6 (Strict Concurrency) | C# 12 / 13 |
| **Target Runtime** | iOS 16.0 – iOS 18.x | .NET 8.0 LTS / .NET 9.0 / .NET 10.0 |
| **UI Framework** | SwiftUI + Combine | WinUI 3 (Windows App SDK 1.5+) |
| **Architecture** | Clean Architecture + MVVM + DI | Clean Architecture + MVVM + DI |
| **System APIs** | `ProcessInfo`, `UIDevice`, `NWPathMonitor` | `System.Net.NetworkInformation`, WMI / PnP, Win32 NDIS |
| **Diagnostics** | `NWPath`, `URLSession` probe | Raw ICMP Sockets, DNS Client, HTTP Client |
| **Persistence** | SQLite / CoreData / SwiftData (local only) | SQLite (`Microsoft.Data.Sqlite`) with WAL mode |
| **Logging** | Apple Unified Logging (`os.Logger`) | Structured Logging (`Serilog` / `Microsoft.Extensions.Logging`) |

---

## 4. Repository Structure

```text
iphone-hotspot-wired/
├── .github/                      # CI/CD Workflows for iOS and Windows builds
├── docs/                         # Architecture diagrams, specifications, and schematics
│   ├── ARCHITECTURE.md           # End-to-end multi-tier architecture & data flows
│   ├── DEVELOPMENT_PLAN.md       # Phased roadmap, milestones, and task checklists
│   ├── TECHNICAL_RESEARCH.md     # Deep dive into Apple USB CDC-NCM & Windows NDIS
│   ├── API_REFERENCE.md          # Comprehensive data contracts and public interfaces
│   ├── IOS_LIMITATIONS.md        # Apple sandbox restrictions & technical boundaries
│   ├── WINDOWS_IMPLEMENTATION.md # Windows PnP, NDIS, and WinUI 3 implementation
│   ├── SECURITY.md               # Security, privacy, sandboxing, and trust models
│   ├── TESTING_PLAN.md           # Unit, integration, hardware, and stress testing
│   └── BUILD_AND_RELEASE.md      # Xcode sideloading and Windows packaging guide
├── ios/                          # iOS Application source directory
│   ├── TetherAssistant/          # Xcode Project root
│   │   ├── App/                  # App entrypoint and dependency injection container
│   │   ├── Core/                 # Protocols, Constants, Extensions, Utilities
│   │   ├── Models/               # Thermal, Battery, Network, and Session models
│   │   ├── Services/             # ThermalMonitor, BatteryMonitor, NetworkDiagnostics
│   │   ├── ViewModels/           # Observable ViewModels for SwiftUI
│   │   ├── Views/                # Dashboard, SetupGuide, DeviceHealth, History, Settings
│   │   └── Resources/            # Assets, Localizations, Entitlements, Info.plist
│   └── TetherAssistant.xcodeproj # Xcode Project configuration
├── windows/                      # Windows Companion Application source directory
│   ├── TetherAssistant.Windows/  # WinUI 3 / C# Project root
│   │   ├── App.xaml / .cs        # Application lifecycle & IoC container setup
│   │   ├── Core/                 # Enums, Helpers, Base ObservableObject
│   │   ├── Models/               # AdapterInfo, TelemetryData, DiagnosticResult
│   │   ├── Services/             # NetworkAdapterService, DiagnosticService, TelemetryService
│   │   ├── ViewModels/           # DashboardViewModel, NetworkViewModel, DiagnosticsViewModel
│   │   ├── Views/                # DashboardPage, NetworkPage, DiagnosticsPage, SettingsPage
│   │   └── Package.appxmanifest  # MSIX Packaging manifest
│   └── TetherAssistant.Windows.sln # Visual Studio Solution file
├── shared/                       # Shared telemetry schemas and diagnostic contracts
└── README.md                     # Project documentation overview
```

---

## 5. Quick Start

### Windows Companion
1. Prerequisites:
   - Windows 10 (version 19041+) or Windows 11.
   - .NET 8.0 SDK or newer.
   - Apple Devices app or iTunes installed (provides `Apple Mobile Device Ethernet` driver) OR modern Windows 11 with built-in USB NCM driver.
2. Building:
   ```powershell
   cd windows/TetherAssistant.Windows
   dotnet build -c Release
   dotnet run -c Release
   ```

### iOS Application
1. Prerequisites:
   - macOS 14.0+ with Xcode 15.0+ or 16.0+.
   - iPhone running iOS 16.0 or higher.
   - Apple Developer Account (free or paid) OR AltStore / SideStore.
2. Building & Sideloading:
   - Open `ios/TetherAssistant.xcodeproj` in Xcode.
   - Select your personal development signing team under **Signing & Capabilities**.
   - Build and run directly on your connected iPhone, or export an unsigned `.ipa` for AltStore / SideStore installation.
   - For detailed step-by-step instructions, see [docs/BUILD_AND_RELEASE.md](docs/BUILD_AND_RELEASE.md).

---

## 6. Documentation Index

- [Architecture Blueprint](docs/ARCHITECTURE.md): Multi-tier architecture, data flow diagrams, and MVVM service topologies.
- [Development Plan & Roadmap](docs/DEVELOPMENT_PLAN.md): Detailed 6-phase engineering roadmap and sub-agent task allocations.
- [Technical Research & Validation](docs/TECHNICAL_RESEARCH.md): Deep reverse-engineering analysis of Apple USB tethering, CDC-NCM protocols, and Windows NDIS hooks.
- [API & Interface Reference](docs/API_REFERENCE.md): Complete Swift and C# interfaces, telemetry schemas, and event contracts.
- [iOS Sandbox Limitations](docs/IOS_LIMITATIONS.md): Definitive guide on what is possible vs. restricted within Apple's iOS sandbox.
- [Windows Implementation Guide](docs/WINDOWS_IMPLEMENTATION.md): Hardware detection algorithms, WMI queries, and NDIS byte-counter calculations.
- [Security & Privacy Blueprint](docs/SECURITY.md): Threat modeling, trust boundaries, zero-telemetry privacy design, and driver validation.
- [Testing & Quality Assurance Plan](docs/TESTING_PLAN.md): Unit tests, simulated network flaps, thermal regression suites, and benchmark criteria.
- [Build, Packaging & Sideloading](docs/BUILD_AND_RELEASE.md): Xcode configuration, SideStore setup, and Windows installer generation.

---

## 7. License & Compliance
This software is provided under the [MIT License](LICENSE).
Apple, iPhone, Lightning, and macOS are registered trademarks of Apple Inc.
Windows, WinUI, and .NET are registered trademarks of Microsoft Corporation.
This project is an independent engineering tool designed to interface with native system features without unauthorized modification or reverse engineering of proprietary DRM.

