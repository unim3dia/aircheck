import XCTest
@testable import AircheckCore

final class ResumePositionPolicyTests: XCTestCase {
    func testStartsAtBeginningWithoutSavedProgress() {
        XCTAssertEqual(ResumePositionPolicy.startTime(saved: nil, duration: 18_000), 0)
    }

    func testResumesMeaningfulSavedProgress() {
        XCTAssertEqual(ResumePositionPolicy.startTime(saved: 3_600, duration: 18_000), 3_600)
    }

    func testRestartsCompletedShow() {
        XCTAssertEqual(ResumePositionPolicy.startTime(saved: 17_990, duration: 18_000), 0)
    }

    func testClampsInvalidValues() {
        XCTAssertEqual(ResumePositionPolicy.startTime(saved: -20, duration: 18_000), 0)
        XCTAssertEqual(ResumePositionPolicy.startTime(saved: 99_000, duration: 18_000), 0)
    }
}
