//
//  DoorOpeningDecisionTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import XCTest

final class DoorOpeningDecisionTests: XCTestCase {
    func testMissingAccessTokenRejectsDoorCommand() {
        let decision = DoorOpeningDecision.resolve(
            accessToken: nil,
            domophoneId: "domophone",
            doorId: 7,
            blockReason: nil
        )

        XCTAssertEqual(decision, .reject(.missingAccessToken))
    }

    func testMissingAccessTokenHasPriorityOverBlockReason() {
        let decision = DoorOpeningDecision.resolve(
            accessToken: nil,
            domophoneId: "domophone",
            doorId: 7,
            blockReason: "Blocked"
        )

        XCTAssertEqual(decision, .reject(.missingAccessToken))
    }

    func testAnyPresentBlockReasonRejectsDoorCommand() {
        XCTAssertEqual(
            DoorOpeningDecision.resolve(
                accessToken: "token",
                domophoneId: "domophone",
                doorId: 7,
                blockReason: ""
            ),
            .reject(.blocked(reason: ""))
        )
        XCTAssertEqual(
            DoorOpeningDecision.resolve(
                accessToken: "token",
                domophoneId: "domophone",
                doorId: 7,
                blockReason: "No access"
            ),
            .reject(.blocked(reason: "No access"))
        )
    }

    func testAllowedDoorCommandPreservesRequestData() {
        let decision = DoorOpeningDecision.resolve(
            accessToken: "token",
            domophoneId: "domophone",
            doorId: 7,
            blockReason: nil
        )

        XCTAssertEqual(
            decision,
            .send(
                DoorOpeningRequestData(
                    accessToken: "token",
                    domophoneId: "domophone",
                    doorId: 7
                )
            )
        )

        XCTAssertEqual(
            DoorOpeningDecision.resolve(
                accessToken: "",
                domophoneId: "domophone",
                doorId: nil,
                blockReason: nil
            ),
            .send(
                DoorOpeningRequestData(
                    accessToken: "",
                    domophoneId: "domophone",
                    doorId: nil
                )
            )
        )
    }
}
