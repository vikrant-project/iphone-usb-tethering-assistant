# Build, Packaging & Sideloading Guide

This guide provides instructions for compiling, packaging, signing, and installing both the iOS Application (`TetherAssistant`) and the Windows Companion (`TetherAssistant.Windows`).

---

## 1. Prerequisites Matrix

| Requirement | iOS Application | Windows Companion |
| :--- | :--- | :--- |
| **Operating System** | macOS 14.0 (Sonoma) or macOS 15.0+ | Windows 10 (Build 19041+) or Windows 11 |
| **IDE / Tooling** | Xcode 15.0+ / Xcode 16.0+ | Visual Studio 2022 (v17.8+) or .NET 8/9/10 SDK |
| **SDK Runtime** | iOS 16.0+ Deployment Target | Windows App SDK 1.5+, .NET 8.0 LTS / 9.0 / 10.0 |
| **Developer Account**| Free Apple ID (7-day cert) OR Paid ($99/yr) | None required (Self-signed or Unpackaged) |

> [!IMPORTANT]
> **macOS Requirement**: Building the native iOS application binary (`.ipa`) requires macOS with Xcode installed. The Windows companion can be built directly on Windows using the standard `.NET SDK` or Visual Studio.

---

## 2. iOS Application Build & Sideloading Guide

### 2.1 Xcode Direct Build & Installation
1. Clone the repository on your Mac:
   ```bash
   git clone https://github.com/your-org/iphone-hotspot-wired.git
   cd iphone-hotspot-wired/ios
   ```
2. Open `TetherAssistant.xcodeproj` in Xcode.
3. In Xcode, navigate to the **TetherAssistant** target -> **Signing & Capabilities**.
4. Check **Automatically manage signing**.
5. In the **Team** dropdown, select your Personal Apple ID or Developer Team.
6. Connect your physical iPhone via USB, select it as the target device in Xcode's top toolbar, and press **Cmd + R** (Build and Run).
7. On your iPhone, navigate to **Settings -> General -> VPN & Device Management** and trust your Developer App certificate.

---

### 2.2 Exporting a Signed IPA for Sideloading
To distribute the application to users without a Mac using AltStore or SideStore:

1. In Xcode, select **Product -> Archive**.
2. Once the Organizer window opens, click **Distribute App**.
3. Select **Development** or **Ad Hoc** distribution.
4. Export the resulting `TetherAssistant.ipa` file.

---

### 2.3 Sideloading via AltStore / SideStore

#### Option A: AltStore (via Windows PC or Mac)
1. Install **AltServer** on your Windows PC from [altstore.io](https://altstore.io).
2. Connect your iPhone to your Windows PC via USB and ensure **iTunes** / **Apple Devices** recognizes it.
3. Click the AltServer icon in the Windows system tray -> **Install AltStore -> [Your iPhone]**.
4. Enter your Apple ID and password.
5. On the iPhone, open AltStore, tap the **"+"** icon in the My Apps tab, and select `TetherAssistant.ipa`.
6. AltStore signs and installs the app directly onto your device.

#### Option B: SideStore (Computer-Free Resigning)
1. Install SideStore onto your iPhone (one-time setup via SideServer).
2. Connect to the local **SideStore WireGuard VPN** on your iPhone.
3. Open SideStore, select `TetherAssistant.ipa`, and tap Install.
4. SideStore refreshes the 7-day personal certificate over your local Wi-Fi or tethered connection automatically.

---

## 3. Windows Companion Packaging & Distribution

### 3.1 Self-Contained Release Build
To generate a standalone executable that runs without requiring users to pre-install the .NET runtime:

```powershell
cd windows/TetherAssistant.Windows

dotnet publish -c Release `
  -r win-x64 `
  --self-contained true `
  -p:PublishSingleFile=true `
  -p:IncludeNativeLibrariesForSelfExtract=true `
  -p:WindowsAppSDKSelfContained=true `
  -o ./dist/publish
```

This compiles a clean, optimized `TetherAssistant.Windows.exe` inside `./dist/publish/`.

---

### 3.2 Distributable Inno Setup Installer
To create a standard Windows installer (`Setup.exe`) that configures start menu shortcuts and checks for Apple drivers:

1. Download and install [Inno Setup 6](https://jrsoftware.org/isdl.php).
2. Open `windows/installer/TetherAssistant.iss`.
3. Inno Setup compiles `./dist/TetherAssistant-Setup-v1.0.0.exe`.

The installer script includes verification for:
- Windows 10 (19041+) or Windows 11.
- Detects whether Apple Mobile Device Ethernet or modern UsbNcm driver is present. If missing, prompts the user to download the official Apple Devices app from the Microsoft Store.

---

### 3.3 Driver Setup Guide for End Users

| Operating System | Recommended Driver Source | Notes |
| :--- | :--- | :--- |
| **Windows 11 (22H2+)** | Built-in native `UsbNcm.sys` | Plug-and-play for iPhone 15 & 16 series (USB-C). No extra software needed. |
| **Windows 11 / 10** | **Apple Devices** (Microsoft Store) | Modern official replacement for iTunes from Apple. Installs modern Apple USB drivers. |
| **Windows 10 (Legacy)** | **iTunes for Windows** (Apple Direct MSI) | Provides `netaapl64.sys` driver for Lightning-based devices. |

