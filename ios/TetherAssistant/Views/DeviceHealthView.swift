import SwiftUI

public struct DeviceHealthView: View {
    @ObservedObject var viewModel: AppContainer

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Thermal status overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("THERMAL DYNAMICS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textMuted)

                        HStack {
                            Text(viewModel.thermalMonitor.currentThermalState.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text(viewModel.thermalMonitor.currentThermalState.shortDescription)
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .padding(20)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cornerRadius)

                    // Battery Health & Thermal Mitigation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SMART OVERHEATING RECOMMENDATIONS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textMuted)

                        RecommendationRow(
                            icon: "sun.min.fill",
                            title: "Dim Display Brightness",
                            detail: "Display backlights contribute up to 35% of total device heat during daytime tethering."
                        )

                        RecommendationRow(
                            icon: "case.fill",
                            title: "Remove Thick Protective Cases",
                            detail: "Rubber and leather cases trap thermal radiation emitted from the back glass."
                        )

                        RecommendationRow(
                            icon: "bolt.badge.a.fill",
                            title: "Avoid 20W+ Fast Chargers",
                            detail: "USB tethering over standard 5V PC ports provides gentle, cool charging."
                        )

                        RecommendationRow(
                            icon: "wind",
                            title: "Position Near Airflow",
                            detail: "Place the iPhone flat on a cool desk surface rather than on fabrics or bedsheets."
                        )
                    }
                    .padding(20)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cornerRadius)
                }
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Device Health")
        }
    }
}

private struct RecommendationRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}

