//
//  OnlineSelectionGateTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 LanTa. All rights reserved.
//

import XCTest

final class OnlineSelectionGateTests: XCTestCase {
    func testNormalSwipesAreForwarded() {
        var gate = OnlineSelectionGate()

        XCTAssertTrue(gate.shouldForwardCenteredIndex(1))
        XCTAssertTrue(gate.shouldForwardCenteredIndex(2))
    }

    func testProgrammaticScrollSuppressesIntermediateAndTargetEvents() {
        var gate = OnlineSelectionGate()
        gate.waitForProgrammaticScroll(to: 1)

        XCTAssertFalse(gate.shouldForwardCenteredIndex(5))
        XCTAssertFalse(gate.shouldForwardCenteredIndex(3))
        XCTAssertFalse(gate.shouldForwardCenteredIndex(1))
        XCTAssertTrue(gate.shouldForwardCenteredIndex(2))
    }

    func testFullscreenRestoreStaysSuppressedUntilUserInteraction() {
        var gate = OnlineSelectionGate()
        gate.suspendUntilUserInteraction()
        gate.waitForProgrammaticScroll(to: 1)

        XCTAssertFalse(gate.shouldForwardCenteredIndex(3))
        XCTAssertFalse(gate.shouldForwardCenteredIndex(1))
        XCTAssertFalse(gate.shouldForwardCenteredIndex(2))

        gate.beginUserInteraction()

        XCTAssertTrue(gate.shouldForwardCenteredIndex(2))
    }

    func testFirstSwipeAfterFullscreenWorksEvenWhenTargetEventWasMissed() {
        var gate = OnlineSelectionGate()
        gate.suspendUntilUserInteraction()
        gate.waitForProgrammaticScroll(to: 1)
        XCTAssertFalse(gate.shouldForwardCenteredIndex(3))

        gate.beginUserInteraction()

        XCTAssertTrue(gate.shouldForwardCenteredIndex(2))
        XCTAssertTrue(gate.shouldForwardCenteredIndex(3))
    }

    func testManualSwipeInterruptsProgrammaticNumberSelection() {
        var gate = OnlineSelectionGate()
        gate.waitForProgrammaticScroll(to: 6)
        XCTAssertFalse(gate.shouldForwardCenteredIndex(2))

        gate.beginUserInteraction()

        XCTAssertTrue(gate.shouldForwardCenteredIndex(3))
    }

    func testLatestProgrammaticTargetReplacesPreviousTarget() {
        var gate = OnlineSelectionGate()
        gate.waitForProgrammaticScroll(to: 6)
        gate.waitForProgrammaticScroll(to: 1)

        XCTAssertFalse(gate.shouldForwardCenteredIndex(6))
        XCTAssertFalse(gate.shouldForwardCenteredIndex(2))
        XCTAssertFalse(gate.shouldForwardCenteredIndex(1))
        XCTAssertTrue(gate.shouldForwardCenteredIndex(2))
    }

    func testRepeatedFullscreenRoundTripsDoNotLeaveSelectionLocked() {
        var gate = OnlineSelectionGate()

        for target in [6, 1, 4] {
            gate.suspendUntilUserInteraction()
            gate.waitForProgrammaticScroll(to: target)
            gate.beginUserInteraction()

            XCTAssertTrue(gate.shouldForwardCenteredIndex(target + 1))
        }
    }

    func testNewProgrammaticScrollStillWorksAfterManualInterruption() {
        var gate = OnlineSelectionGate()
        gate.suspendUntilUserInteraction()
        gate.beginUserInteraction()
        gate.waitForProgrammaticScroll(to: 4)

        XCTAssertFalse(gate.shouldForwardCenteredIndex(3))
        XCTAssertFalse(gate.shouldForwardCenteredIndex(4))
        XCTAssertTrue(gate.shouldForwardCenteredIndex(5))
    }
}
