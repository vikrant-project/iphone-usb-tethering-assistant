# Building & Sideloading the iOS IPA on Windows (No Mac Required)

If you do not own a Mac or macOS device, you can still compile and install `TetherAssistant.ipa` directly onto your iPhone. This guide explains how to get a 100% genuine, compiled iOS IPA using free automated cloud builds and install it using standard Windows sideloading tools.

---

## 1. Why Can't Windows Directly Compile Swift/SwiftUI for iOS?

Apple's compiler (`clang` / `swiftc`), the iOS SDK frameworks (`SwiftUI`, `UIKit`, `Network`, `Darwin`), and the `ld64` ARM64 Mach-O linker are proprietary Apple software distributed exclusively within macOS. 

However, **you do not need to buy or own a Mac**. You can use GitHub's free Apple Silicon macOS runners to compile your IPA in the cloud in under 2 minutes, download the `.ipa` to your Windows PC, and install it via USB.

---

## 2. Step 1: Build the IPA in the Cloud via GitHub Actions (Free)

We have already configured a complete, automated GitHub Actions workflow in [`.github/workflows/build-ipa.yml`](../.github/workflows/build-ipa.yml).

### Instructions:
1. Push this repository to your GitHub account (public or private):
   ```bash
   git add .
   git commit -m "Add TetherAssistant project with iOS workflow"
   git push origin main
   ```
2. Open your repository on [github.com](https://github.com) in your web browser.
3. Click on the **Actions** tab at the top.
4. On the left sidebar, click **Build iOS Sideloadable IPA**.
5. Click the **Run workflow** dropdown button on the right, and click **Run workflow**.
6. GitHub will spin up an Apple Silicon Mac (`macos-14`) with Xcode 15 pre-installed, compile the Swift 6 / SwiftUI code into a native ARM64 Mach-O binary, package it into `TetherAssistant.ipa`, and complete in ~2 minutes.
7. Click on the completed workflow run, scroll down to the **Artifacts** section at the bottom, and click **`TetherAssistant-iOS-IPA`** to download your ready-to-install `TetherAssistant.ipa`.

---

## 3. Step 2: Sideload onto iPhone from Windows

Once you have downloaded `TetherAssistant.ipa` on your Windows PC, choose either **Sideloadly** (easiest, 1-click) or **AltStore**.

### Method A: Sideloadly (Recommended for Windows)
*Sideloadly is the most popular, reliable tool for installing IPAs on Windows using a free Apple ID.*

1. **Download & Install**:
   - Download Sideloadly for Windows (64-bit) from [sideloadly.io](https://sideloadly.io).
   - Ensure **iTunes** (or the **Apple Devices** app) is installed on your Windows PC so the Apple USB driver is present.
2. **Connect iPhone**:
   - Plug your iPhone into your Windows PC via USB cable.
   - Unlock your iPhone and tap **"Trust This Computer"** if prompted.
3. **Install the IPA**:
   - Open Sideloadly on Windows. Your iPhone will appear in the device dropdown.
   - Drag and drop `TetherAssistant.ipa` into the large icon box in Sideloadly.
   - Under **Apple ID**, enter your personal Apple ID email.
   - Click **Start**. Sideloadly will connect to Apple's developer servers, issue a free personal development certificate, sign the binary, and push it directly to your iPhone.
4. **Trust the Certificate on iPhone**:
   - On your iPhone, open **Settings -> General -> VPN & Device Management**.
   - Under *Developer App*, tap your Apple ID email.
   - Tap **Trust "[Your Apple ID]"**.
   - If on iOS 16+, enable **Developer Mode** in **Settings -> Privacy & Security -> Developer Mode** (requires one quick device restart).
5. **Done!** `TetherAssistant` is now installed on your home screen and ready to use!

---

### Method B: AltStore & AltServer (Windows)

1. Download **AltServer for Windows** from [altstore.io](https://altstore.io).
2. Install AltServer, launch it from the Windows system tray, and click **Install AltStore -> [Your iPhone]**.
3. Once AltStore is on your iPhone, send `TetherAssistant.ipa` to your iPhone (via USB or iCloud Drive).
4. In AltStore on your iPhone, tap the **"+"** button on the *My Apps* tab and select `TetherAssistant.ipa`.
5. AltStore signs and installs the app. AltServer refreshes the 7-day certificate automatically over Wi-Fi when you are on the same local network.

---

### Method C: TrollStore (For iOS 14.0 – 16.6.1 & 17.0)
If your iPhone runs iOS 14.0 through 16.6.1 (or 17.0) with TrollStore installed:
- Simply AirDrop or transfer `TetherAssistant.ipa` to your phone.
- Open in TrollStore and tap **Install**.
- **Permanent Signing**: TrollStore uses the CoreTrust bug, so the app will never expire and never need resigning!

---

## Summary of the Workflow for Windows Users

```mermaid
flowchart LR
    A["Your Code on Windows PC"] -->|Git Push| B["GitHub Actions (Free macOS Runner)"]
    B -->|Compiles with Xcode| C["Download TetherAssistant.ipa"]
    C -->|USB Cable| D["Sideloadly on Windows (Signs with your Apple ID)"]
    D -->|Installed!| E["iPhone Ready to Tether!"]
```

