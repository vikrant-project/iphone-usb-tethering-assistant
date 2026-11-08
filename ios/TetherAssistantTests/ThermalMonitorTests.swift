import XCTest
@testable import TetherAssistant

final class ThermalMonitorTests: XCTestCase {

    func testDeviceThermalState_DisplayTitlesAndDescriptions() {
        XCTAssertEqual(DeviceThermalState.nominal.title, "Nominal")
        XCTAssertEqual(DeviceThermalState.fair.title, "Fair")
        XCTAssertEqual(DeviceThermalState.serious.title, "Serious")
        XCTAssertEqual(DeviceThermalState.critical.title, "Critical")

        XCTAssertFalse(DeviceThermalState.nominal.shortDescription.isEmpty)
        XCTAssertFalse(DeviceThermalState.serious.shortDescription.isEmpty)
    }

    func testBatterySnapshot_HighTemperatureRiskDetection() {
        let safeSnapshot = BatterySnapshot(
            levelPercent: 50,
            state: .charging(isFastCharging: false),
            timestamp: Date(),
            isHighTemperatureRisk: false
        )
        XCTAssertFalse(safeSnapshot.isHighTemperatureRisk)

        let riskSnapshot = BatterySnapshot(
            levelPercent: 95,
            state: .charging(isFastCharging: true),
            timestamp: Date(),
            isHighTemperatureRisk: true
        )
        XCTAssertTrue(riskSnapshot.isHighTemperatureRisk)
    }

    func testTetherSessionDurationFormatting() {
        let start = Date()
        let end = start.addingTimeInterval(3665) // 1 hour, 1 minute, 5 seconds

        let session = TetherSessionRecord(
            id: UUID(),
            startTime: start,
            endTime: end,
            initialBatteryPercent: 80,
            finalBatteryPercent: 85,
            peakThermalState: .fair,
            wasCharging: true
        )

        XCTAssertEqual(session.durationFormatted, "1h 01m")
    }
}
