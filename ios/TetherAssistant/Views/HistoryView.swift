import SwiftUI

public struct HistoryView: View {
    let repository: SessionRepository
    @State private var sessions: [TetherSessionRecord] = []
    @State private var isLoading = true

    public var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty && !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.badge.xmark")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.textMuted)
                        Text("No Tethering Sessions Recorded")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        Text("Connect your iPhone via USB and launch tethering to log sessions.")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(sessions) { session in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text(session.durationFormatted)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Theme.surfaceElevated)
                                    .foregroundColor(Theme.accent)
                                    .cornerRadius(6)
                            }

                            HStack(spacing: 16) {
                                Label("\(session.initialBatteryPercent)% → \(session.finalBatteryPercent ?? session.initialBatteryPercent)%", systemImage: "battery.100")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)

                                Label(session.peakThermalState.title, systemImage: "flame")
                                    .font(.caption)
                                    .foregroundColor(session.peakThermalState == .nominal ? Theme.success : Theme.warning)
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Theme.surface)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Session History")
            .task {
                sessions = (try? await repository.fetchRecentSessions(limit: 50)) ?? []
                isLoading = false
            }
        }
    }
}

