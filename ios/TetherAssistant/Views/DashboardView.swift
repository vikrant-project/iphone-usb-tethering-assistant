import SwiftUI

public struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Status Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("WIRED TETHERING STATUS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textMuted)
                            Spacer()
                            Circle()
                                .fill(viewModel.isHotspotLikelyActive ? Theme.success : Theme.warning)
                                .frame(width: 8, height: 8)
                            Text(viewModel.isHotspotLikelyActive ? "Active" : "Standby")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(viewModel.isHotspotLikelyActive ? Theme.success : Theme.warning)
                        }

                        Text(viewModel.isHotspotLikelyActive ? "USB Tethering Engaged" : "Ready to Connect")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)

                        Text("Active Interface: \(viewModel.activeMedium.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cornerRadius)

                    // Session Time & Metrics Row
                    HStack(spacing: 16) {
                        MetricCard(
                            title: "Session Time",
                            value: viewModel.sessionDurationFormatted,
                            icon: "stopwatch.fill",
                            accentColor: Theme.accent
                        )

                        MetricCard(
                            title: "Battery Level",
                            value: "\(viewModel.batteryPercent)%",
                            icon: "battery.100",
                            accentColor: viewModel.isHighThermalRisk ? Theme.warning : Theme.success
                        )
                    }

                    // Thermal Sentinel Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "flame.circle.fill")
                                .font(.title3)
                                .foregroundColor(thermalColor(for: viewModel.thermalState))
                            Text("Thermal Sentinel")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text(viewModel.thermalState.title.uppercased())
                                .font(.caption)
                                .fontWeight(.heavy)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(thermalColor(for: viewModel.thermalState).opacity(0.2))
                                .foregroundColor(thermalColor(for: viewModel.thermalState))
                                .cornerRadius(8)
                        }

                        Text(viewModel.thermalRecommendation)
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)

                        if viewModel.isHighThermalRisk {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Theme.warning)
                                Text("High battery charge with active tethering increases heat.")
                                    .font(.caption)
                                    .foregroundColor(Theme.warning)
                            }
                            .padding(10)
                            .background(Theme.warning.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cornerRadius)
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Tether Sentinel")
            .onAppear {
                viewModel.startObserving()
            }
        }
    }

    private func thermalColor(for state: DeviceThermalState) -> Color {
        switch state {
        case .nominal: return Theme.success
        case .fair: return Theme.warning
        case .serious: return Color.orange
        case .critical: return Theme.danger
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                Spacer()
            }
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textMuted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
    }
}

