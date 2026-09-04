//
//  AddressListTransformerTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 LanTa. All rights reserved.
//

import XCTest

final class AddressListTransformerTests: XCTestCase {
    func testDefaultOrderPlacesAddressesWithDoorsFirstAndSortsEachGroup() {
        let addresses = [
            Address(id: "4", title: "beta", hasDoors: false),
            Address(id: "2", title: "beta", hasDoors: true),
            Address(id: "3", title: "Alpha", hasDoors: false),
            Address(id: "1", title: "Alpha", hasDoors: true)
        ]

        let result = sorted(addresses, savedOrder: [])

        XCTAssertEqual(result.map(\.id), ["1", "2", "3", "4"])
    }

    func testSavedOrderHasPriorityAndSortsUnknownAddressesByTitle() {
        let addresses = [
            Address(id: "unknown-b", title: "Zulu", hasDoors: true),
            Address(id: "saved-last", title: "Alpha", hasDoors: false),
            Address(id: "unknown-a", title: "beta", hasDoors: false),
            Address(id: "saved-first", title: "Zulu", hasDoors: false)
        ]

        let result = sorted(
            addresses,
            savedOrder: ["saved-first", "saved-last"]
        )

        XCTAssertEqual(
            result.map(\.id),
            ["saved-first", "saved-last", "unknown-a", "unknown-b"]
        )
    }

    func testDuplicateHouseIdentifiersKeepFirstAddress() {
        let addresses = [
            Address(id: "same", title: "First", hasDoors: true),
            Address(id: "other", title: "Other", hasDoors: true),
            Address(id: "same", title: "Second", hasDoors: false)
        ]

        let result = AddressListTransformer.removingDuplicates(
            from: addresses,
            identifiedBy: { $0.id }
        )

        XCTAssertEqual(result.map(\.title), ["First", "Other"])
    }

    private func sorted(
        _ addresses: [Address],
        savedOrder: [String]
    ) -> [Address] {
        AddressListTransformer.sorted(
            addresses,
            savedOrder: savedOrder,
            identifier: { $0.id },
            title: { $0.title },
            hasDoors: { $0.hasDoors }
        )
    }

    private struct Address {
        let id: String
        let title: String
        let hasDoors: Bool
    }
}
