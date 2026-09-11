//
//  ParanoidPushPayloadTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation
import XCTest

final class ParanoidPushPayloadTests: XCTestCase {
    func testNestedAlertPayloadPreservesCurrentMapping() throws {
        let payload = try XCTUnwrap(
            ParanoidPushPayload(
                userInfo: [
                    "action": "paranoid",
                    "timestamp": "1700000000",
                    "hash": "hash",
                    "aps": ["alert": ["title": "Title", "body": "Body"]]
                ],
                notificationTitle: nil,
                notificationBody: nil,
                providerBaseURL: "https://example.com/mobile/",
                serverTimeZone: "Europe/Moscow",
                now: Date(timeIntervalSince1970: 0)
            )
        )

        XCTAssertEqual(payload.title, "Title")
        XCTAssertEqual(payload.body, "Body")
        XCTAssertEqual(payload.date, "15.11.2023, 01:13:20")
        XCTAssertEqual(payload.hash, "hash")
        XCTAssertEqual(payload.imageUrl, "https://example.com/mobile/call/camshot/hash")
    }

    func testFlatValuesHavePriorityOverNotificationFallbacks() throws {
        let payload = try XCTUnwrap(
            ParanoidPushPayload(
                userInfo: [
                    "action": "paranoid",
                    "title": "Payload title",
                    "body": "Payload body"
                ],
                notificationTitle: "Notification title",
                notificationBody: "Notification body",
                providerBaseURL: "https://example.com/mobile",
                serverTimeZone: "Europe/Moscow",
                now: Date(timeIntervalSince1970: 0)
            )
        )

        XCTAssertEqual(payload.title, "Payload title")
        XCTAssertEqual(payload.body, "Payload body")
        XCTAssertEqual(payload.date, "01.01.1970, 03:00:00")
        XCTAssertNil(payload.hash)
        XCTAssertNil(payload.imageUrl)
    }

    func testNonParanoidActionIsRejected() {
        let payload = ParanoidPushPayload(
            userInfo: ["action": "inbox"],
            notificationTitle: "Title",
            notificationBody: "Body",
            providerBaseURL: "https://example.com/mobile",
            serverTimeZone: "Europe/Moscow"
        )

        XCTAssertNil(payload)
    }

    func testImageURLHandlesBaseURLWithAndWithoutTrailingSlash() {
        XCTAssertEqual(
            ParanoidPushPayload.imageURL(
                providerBaseURL: "https://example.com/mobile",
                hash: "hash"
            ),
            "https://example.com/mobile/call/camshot/hash"
        )
        XCTAssertEqual(
            ParanoidPushPayload.imageURL(
                providerBaseURL: "https://example.com/mobile/",
                hash: "hash"
            ),
            "https://example.com/mobile/call/camshot/hash"
        )
    }
}
