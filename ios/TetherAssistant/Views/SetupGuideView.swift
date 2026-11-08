import SwiftUI

public struct SetupGuideView: View {
    @State private var currentStep = 1

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header progress
                    HStack(spacing: 8) {
                        ForEach(1...4, id: \.self) { step in
                            Capsule()
                                .fill(step <= currentStep ? Theme.accent : Theme.surfaceElevated)
                                .frame(height: 6)
                        }
                    }
                    .padding(.horizontal)

                    // Step card
                    VStack(alignment: .leading, spacing: 16) {
                        stepContent(for: currentStep)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cornerRadius)

                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentStep > 1 {
                            Button(action: { currentStep -= 1 }) {
                                Text("Previous")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.surfaceElevated)
                                    .foregroundColor(Theme.textPrimary)
                                    .cornerRadius(12)
                            }
                        }

                        if currentStep < 4 {
                            Button(action: { currentStep += 1 }) {
                                Text("Next Step")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.accent)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        } else {
                            Button(action: { openIosSettings() }) {
                                Text("Open iPhone Settings")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.success)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("USB Tethering Setup")
        }
    }

    @ViewBuilder
    private func stepContent(for step: Int) -> some View {
        switch step {
        case 1:
            VStack(alignment: .leading, spacing: 12) {
                Label("Step 1: Connect Physical USB Cable", systemImage: "cable.connector")
                    .font(.headline)
                    .foregroundColor(Theme.accent)
                Text("Connect your iPhone directly to your Windows PC using a high-quality USB-C or Lightning cable.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                Text("Tip: Prefer direct motherboard USB 3.0 ports on the back of your desktop PC rather than unpowered external USB hubs.")
                    .font(.caption)
                    .foregroundColor(Theme.textMuted)
            }
        case 2:
            VStack(alignment: .leading, spacing: 12) {
                Label("Step 2: Trust This Computer", systemImage: "lock.shield.fill")
                    .font(.headline)
                    .foregroundColor(Theme.accent)
                Text("Unlock your iPhone with your Passcode. If a prompt appears asking 'Trust This Computer?', tap Trust.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                Text("Why: Apple's lockdown security blocks USB data negotiation until the pairing certificate is authorized.")
                    .font(.caption)
                    .foregroundColor(Theme.textMuted)
            }
        case 3:
            VStack(alignment: .leading, spacing: 12) {
                Label("Step 3: Enable Personal Hotspot", systemImage: "personalhotspot")
                    .font(.headline)
                    .foregroundColor(Theme.accent)
                Text("Open iOS Settings -> Personal Hotspot -> Toggle 'Allow Others to Join' to ON.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                Text("When asked 'Wi-Fi is Off', select 'USB Only' to prevent wireless hotspot radio heat.")
                    .font(.caption)
                    .foregroundColor(Theme.warning)
            }
        case 4:
            VStack(alignment: .leading, spacing: 12) {
                Label("Step 4: Launch Windows Companion", systemImage: "desktopcomputer")
                    .font(.headline)
                    .foregroundColor(Theme.success)
                Text("Open 'TetherAssistant' on your Windows PC. The companion will automatically detect your Apple Ethernet adapter and display live throughput.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
        default:
            EmptyView()
        }
    }

    private func openIosSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

