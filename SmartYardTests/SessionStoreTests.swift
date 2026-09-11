//
//  SessionStoreTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation
import XCTest

final class SessionStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()

        suiteName = "SessionStoreTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil

        try super.tearDownWithError()
    }

    func testReadsSessionStoredUnderExistingKeys() throws {
        let encodedName = try JSONEncoder().encode(
            APIClientName(name: "Александр", patronymic: "Сергеевич")
        )
        defaults.set("legacy-token", forKey: "accessToken")
        defaults.set(encodedName, forKey: "clientName")
        defaults.set("79991234567", forKey: "clientPhoneNumber")

        let store = SessionStore(defaults: defaults)

        XCTAssertEqual(store.accessToken, "legacy-token")
        XCTAssertEqual(store.clientName?.name, "Александр")
        XCTAssertEqual(store.clientName?.patronymic, "Сергеевич")
        XCTAssertEqual(store.clientPhoneNumber, "79991234567")
    }

    func testAuthorizePersistsCompleteSession() {
        let store = SessionStore(defaults: defaults)

        store.authorize(
            token: "token",
            name: APIClientName(name: "Иван", patronymic: nil),
            phone: "79990000000"
        )

        let restoredStore = SessionStore(defaults: defaults)
        XCTAssertEqual(restoredStore.accessToken, "token")
        XCTAssertEqual(restoredStore.clientName?.name, "Иван")
        XCTAssertNil(restoredStore.clientName?.patronymic)
        XCTAssertEqual(restoredStore.clientPhoneNumber, "79990000000")
    }

    func testAuthorizeWithoutNameRemovesPreviouslyStoredName() {
        let store = SessionStore(defaults: defaults)
        store.clientName = APIClientName(name: "Старое имя", patronymic: nil)

        store.authorize(token: "token", name: nil, phone: "79990000000")

        XCTAssertNil(store.clientName)
        XCTAssertNil(defaults.data(forKey: "clientName"))
    }

    func testClearRemovesOnlySessionValues() {
        let store = SessionStore(defaults: defaults)
        store.authorize(
            token: "token",
            name: APIClientName(name: "Иван", patronymic: nil),
            phone: "79990000000"
        )
        defaults.set("https://example.com", forKey: "backendURL")
        defaults.set("voip-token", forKey: "voipToken")

        store.clear()

        XCTAssertNil(store.accessToken)
        XCTAssertNil(store.clientName)
        XCTAssertNil(store.clientPhoneNumber)
        XCTAssertEqual(defaults.string(forKey: "backendURL"), "https://example.com")
        XCTAssertEqual(defaults.string(forKey: "voipToken"), "voip-token")
    }

    func testHasValidTokenPreservesCurrentEmptyStringBehavior() {
        let store = SessionStore(defaults: defaults)

        XCTAssertFalse(store.hasValidToken)

        store.accessToken = ""
        XCTAssertFalse(store.hasValidToken)

        store.accessToken = " "
        XCTAssertTrue(store.hasValidToken)

        store.accessToken = "token"
        XCTAssertTrue(store.hasValidToken)
    }
}
