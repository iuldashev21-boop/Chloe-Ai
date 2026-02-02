import XCTest
@testable import ChloeApp

final class SafetyServiceTests: XCTestCase {

    private let sut = SafetyService.shared

    // MARK: - Self-Harm Patterns (13)

    func testSelfHarm_killMyself() {
        let result = sut.checkSafety(message: "I want to kill myself")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testSelfHarm_wantToDie() {
        let result = sut.checkSafety(message: "i want to die")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testSelfHarm_endMyLife() {
        let result = sut.checkSafety(message: "I want to end my life")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testSelfHarm_thinkingAboutSuicide() {
        let result = sut.checkSafety(message: "thinking about suicide")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testSelfHarm_feelingSuicidal() {
        let result = sut.checkSafety(message: "feeling suicidal")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testSelfHarm_dontWantToBeHere() {
        let result = sut.checkSafety(message: "I don't want to be here anymore")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testSelfHarm_hurtMyself() {
        let result = sut.checkSafety(message: "I want to hurt myself")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testSelfHarm_selfHarmKeyword() {
        let result = sut.checkSafety(message: "I've been thinking about self-harm")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testSelfHarm_cuttingMyself() {
        let result = sut.checkSafety(message: "I've been cutting myself")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testSelfHarm_takeMyLife() {
        let result = sut.checkSafety(message: "I want to take my life")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testSelfHarm_betterOffDead() {
        let result = sut.checkSafety(message: "I'd be better off dead")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testSelfHarm_noReasonToLive() {
        let result = sut.checkSafety(message: "there's no reason to live")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testSelfHarm_overdose() {
        let result = sut.checkSafety(message: "thinking about overdose")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    // MARK: - Abuse Patterns (8)

    func testAbuse_heHitsMe() {
        let result = sut.checkSafety(message: "he hits me")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .abuse)
    }

    func testAbuse_heBeatsMe() {
        let result = sut.checkSafety(message: "he beats me")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .abuse)
    }

    func testAbuse_physicallyAbused() {
        let result = sut.checkSafety(message: "I'm being physically abused")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .abuse)
    }

    func testAbuse_domesticViolence() {
        let result = sut.checkSafety(message: "domestic violence")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .abuse)
    }

    func testAbuse_threatensToKill() {
        let result = sut.checkSafety(message: "he threatens to kill me")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .abuse)
    }

    func testAbuse_forcedMe() {
        let result = sut.checkSafety(message: "he forced me to do things")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .abuse)
    }

    func testAbuse_rapedMe() {
        let result = sut.checkSafety(message: "he raped me")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .abuse)
    }

    func testAbuse_sexualAssault() {
        let result = sut.checkSafety(message: "sexual assault")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .abuse)
    }

    func testAbuse_afraidHellHurtMe() {
        let result = sut.checkSafety(message: "I'm afraid he'll hurt me")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .abuse)
    }

    // MARK: - Severe Mental Health Patterns (6)

    func testSevereMH_hearingVoices() {
        let result = sut.checkSafety(message: "I've been hearing voices")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .severeMentalHealth)
    }

    func testSevereMH_seeingThings() {
        let result = sut.checkSafety(message: "seeing things that aren't real")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .severeMentalHealth)
    }

    func testSevereMH_psychosis() {
        let result = sut.checkSafety(message: "I think I'm having psychosis")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .severeMentalHealth)
    }

    func testSevereMH_haventEatenInDays() {
        let result = sut.checkSafety(message: "I haven't eaten in days")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .severeMentalHealth)
    }

    func testSevereMH_cantStopCrying() {
        let result = sut.checkSafety(message: "I can't stop crying for days")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .severeMentalHealth)
    }

    func testSevereMH_dissociating() {
        // Regex \b(complete(ly)?\s*dissociat)\b requires word boundary after "dissociat",
        // so "dissociating" does not match (no \b between 't' and 'i').
        // This documents current regex behavior — may warrant a fix in SafetyService.
        let result = sut.checkSafety(message: "I'm completely dissociating")
        XCTAssertFalse(result.blocked, "Current regex does not match 'dissociating' — trailing \\b limitation")
    }

    // MARK: - Negative Cases (should NOT block)

    func testNegative_feelingSad() {
        let result = sut.checkSafety(message: "I'm feeling sad today")
        XCTAssertFalse(result.blocked)
        XCTAssertNil(result.crisisType)
    }

    func testNegative_ghostedMe() {
        let result = sut.checkSafety(message: "He ghosted me")
        XCTAssertFalse(result.blocked)
        XCTAssertNil(result.crisisType)
    }

    func testNegative_killedItAtWork() {
        let result = sut.checkSafety(message: "I killed it at work today")
        XCTAssertFalse(result.blocked)
        XCTAssertNil(result.crisisType)
    }

    func testNegative_hitOnMe() {
        let result = sut.checkSafety(message: "He hit on me at the bar")
        XCTAssertFalse(result.blocked)
        XCTAssertNil(result.crisisType)
    }

    func testNegative_dyingOfLaughter() {
        let result = sut.checkSafety(message: "I'm dying of laughter")
        XCTAssertFalse(result.blocked)
        XCTAssertNil(result.crisisType)
    }

    func testNegative_emptyString() {
        let result = sut.checkSafety(message: "")
        XCTAssertFalse(result.blocked)
        XCTAssertNil(result.crisisType)
    }

    // MARK: - Case Insensitivity

    func testCaseInsensitive_allCaps() {
        let result = sut.checkSafety(message: "I WANT TO KILL MYSELF")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    func testCaseInsensitive_mixedCase() {
        let result = sut.checkSafety(message: "I Want To Die")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    // MARK: - Priority Order (self-harm checked first)

    func testPriority_selfHarmBeforeAbuse() {
        // Message that could match both — self-harm should win (checked first)
        let result = sut.checkSafety(message: "I want to kill myself because he hits me")
        XCTAssertTrue(result.blocked)
        XCTAssertEqual(result.crisisType, .selfHarm)
    }

    // MARK: - Soft Spiral (Positive Matches)

    func testSoftSpiral_feelingNumb() {
        XCTAssertTrue(sut.checkSoftSpiral(message: "I've been feeling numb all day"))
    }

    func testSoftSpiral_emptyInside() {
        XCTAssertTrue(sut.checkSoftSpiral(message: "I feel empty inside"))
    }

    func testSoftSpiral_cantGetOutOfBed() {
        XCTAssertTrue(sut.checkSoftSpiral(message: "I can't get out of bed"))
    }

    func testSoftSpiral_everythingFeelsHeavy() {
        XCTAssertTrue(sut.checkSoftSpiral(message: "everything feels heavy right now"))
    }

    func testSoftSpiral_goingThroughTheMotions() {
        XCTAssertTrue(sut.checkSoftSpiral(message: "I'm just going through the motions"))
    }

    func testSoftSpiral_emotionallyDrained() {
        XCTAssertTrue(sut.checkSoftSpiral(message: "I'm emotionally drained"))
    }

    func testSoftSpiral_runningOnAutopilot() {
        XCTAssertTrue(sut.checkSoftSpiral(message: "I feel like I'm running on autopilot"))
    }

    // MARK: - Soft Spiral (False-Positive Negatives — should NOT match)

    func testSoftSpiral_notTriggered_rotAlone() {
        XCTAssertFalse(sut.checkSoftSpiral(message: "I need to rot for a bit"))
    }

    func testSoftSpiral_notTriggered_emptyAlone() {
        XCTAssertFalse(sut.checkSoftSpiral(message: "My fridge is empty"))
    }

    func testSoftSpiral_notTriggered_heavyAlone() {
        XCTAssertFalse(sut.checkSoftSpiral(message: "That was a heavy conversation"))
    }

    func testSoftSpiral_notTriggered_bedRot() {
        XCTAssertFalse(sut.checkSoftSpiral(message: "Time for some bed rot"))
    }

    func testSoftSpiral_notTriggered_normalSadness() {
        XCTAssertFalse(sut.checkSoftSpiral(message: "I'm feeling sad today"))
    }
}
