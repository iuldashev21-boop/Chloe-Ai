import XCTest
@testable import ChloeApp

final class CrisisResponseTests: XCTestCase {

    func testSelfHarm_contains988() {
        let response = CrisisResponses.response(for: .selfHarm)
        XCTAssertTrue(response.contains("988"), "Self-harm response should contain 988 hotline")
    }

    func testSelfHarm_containsCrisisTextLine() {
        let response = CrisisResponses.response(for: .selfHarm)
        XCTAssertTrue(response.contains("741741"), "Self-harm response should contain Crisis Text Line")
    }

    func testAbuse_containsDVHotline() {
        let response = CrisisResponses.response(for: .abuse)
        XCTAssertTrue(response.contains("1-800-799-7233"), "Abuse response should contain DV hotline")
    }

    func testAbuse_containsCrisisTextLine() {
        let response = CrisisResponses.response(for: .abuse)
        XCTAssertTrue(response.contains("741741"), "Abuse response should contain Crisis Text Line")
    }

    func testSevereMH_contains988() {
        let response = CrisisResponses.response(for: .severeMentalHealth)
        XCTAssertTrue(response.contains("988"), "Severe MH response should contain 988")
    }

    func testSevereMH_containsSAMHSA() {
        let response = CrisisResponses.response(for: .severeMentalHealth)
        XCTAssertTrue(response.contains("SAMHSA"), "Severe MH response should contain SAMHSA")
    }

    func testSevereMH_containsCrisisTextLine() {
        let response = CrisisResponses.response(for: .severeMentalHealth)
        XCTAssertTrue(response.contains("741741"), "Severe MH response should contain Crisis Text Line")
    }

    func testAllResponses_nonEmpty() {
        for crisisType: CrisisType in [.selfHarm, .abuse, .severeMentalHealth] {
            let response = CrisisResponses.response(for: crisisType)
            XCTAssertFalse(response.isEmpty, "\(crisisType) response should not be empty")
        }
    }

    func testSafetyServiceGetCrisisResponse_matchesDirect() {
        let service = SafetyService.shared
        for crisisType: CrisisType in [.selfHarm, .abuse, .severeMentalHealth] {
            XCTAssertEqual(
                service.getCrisisResponse(for: crisisType),
                CrisisResponses.response(for: crisisType)
            )
        }
    }
}
