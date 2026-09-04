//
//  IncomingCallRoutingPolicyTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 LanTa. All rights reserved.
//

import XCTest

final class IncomingCallRoutingPolicyTests: XCTestCase {
    func testAdmissionPreservesBusyThenIgnoredPriority() {
        XCTAssertEqual(
            IncomingCallRoutingPolicy.admission(
                hasEnqueuedCall: false,
                isIgnored: false
            ),
            .enqueue
        )
        XCTAssertEqual(
            IncomingCallRoutingPolicy.admission(
                hasEnqueuedCall: true,
                isIgnored: false
            ),
            .rejectAlreadyHandling
        )
        XCTAssertEqual(
            IncomingCallRoutingPolicy.admission(
                hasEnqueuedCall: true,
                isIgnored: true
            ),
            .rejectAlreadyHandling
        )
        XCTAssertEqual(
            IncomingCallRoutingPolicy.admission(
                hasEnqueuedCall: false,
                isIgnored: true
            ),
            .rejectIgnored
        )
    }

    func testPresentationDependsOnCallKit() {
        XCTAssertEqual(
            IncomingCallRoutingPolicy.presentation(useCallKit: false),
            .immediately
        )
        XCTAssertEqual(
            IncomingCallRoutingPolicy.presentation(useCallKit: true),
            .afterCallKitAnswer
        )
    }

    func testQuickActionRecognizesOnlyOpenAndIgnore() {
        XCTAssertEqual(
            IncomingCallRoutingPolicy.quickAction(identifier: "OPEN_ACTION"),
            .openDoor
        )
        XCTAssertEqual(
            IncomingCallRoutingPolicy.quickAction(identifier: "IGNORE_ACTION"),
            .ignore
        )
        XCTAssertEqual(
            IncomingCallRoutingPolicy.quickAction(identifier: ""),
            .none
        )
        XCTAssertEqual(
            IncomingCallRoutingPolicy.quickAction(identifier: "UNKNOWN_ACTION"),
            .none
        )
    }
}
