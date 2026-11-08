import SwiftUI

public struct SettingsView: View {
    let repository: SessionRepository
    @State private var thermalAlertEnabled = true
    @State private var batteryWarningEnabled = true
    @State private var showWipeConfirm = false
    @State private var wipeMessage: String?

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("ALERTS & THRESHOLDS").foregroundColor(Theme.textMuted)) {
                    Toggle("Thermal State Alerts", isOn: $thermalAlertEnabled)
                    Toggle("High Battery Charge Warnings", isOn: $batteryWarningEnabled)
                }
                .listRowBackground(Theme.surface)

                Section(header: Text("PRIVACY & DATA").foregroundColor(Theme.textMuted)) {
                    Button(role: .destructive, action: { showWipeConfirm = true }) {
                        Label("Wipe Session History", systemImage: "trash.fill")
                    }
                }
                .listRowBackground(Theme.surface)

                Section(header: Text("ABOUT").foregroundColor(Theme.textMuted)) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 100)")
                            .foregroundColor(Theme.textSecondary)
                    }

                    HStack {
                        Text("Zero Cloud Telemetry")
                        Spacer()
                        Text("Active")
                            .foregroundColor(Theme.success)
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .confirmationDialog("Are you sure you want to erase all session history?", isPresented: $showWipeConfirm, titleVisibility: .visible) {
                Button("Erase All", role: .destructive) {
                    Task {
                        try? await repository.clearAllHistory()
                        wipeMessage = "History successfully cleared."
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

