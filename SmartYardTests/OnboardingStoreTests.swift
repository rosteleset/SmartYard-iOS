//
//  OnboardingStoreTests.swift
//  SmartYardTests
//
//  Created by Александр Попов on 27.10.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import XCTest

@MainActor
final class OnboardingStoreTests: XCTestCase {
    func testAdvancingPagesDoesNotCompleteOnboarding() async {
        var completions = 0
        let store = OnboardingStore(pageCount: 3, onSkip: { completions += 1 }, onStart: { completions += 1 })
        XCTAssertEqual(store.selectedPage, 0)
        XCTAssertFalse(store.isLastPage)
        store.advance()
        XCTAssertEqual(store.selectedPage, 1)
        store.advance()
        XCTAssertTrue(store.isLastPage)
        store.advance()
        XCTAssertEqual(store.selectedPage, 2)
        XCTAssertEqual(completions, 0)
    }

    func testActionsAreAvailableOnTheSamePagesAsTheOriginalControls() async {
        var skips = 0
        var starts = 0
        let store = OnboardingStore(pageCount: 3, onSkip: { skips += 1 }, onStart: { starts += 1 })
        store.start()
        XCTAssertEqual(starts, 0)
        store.skip()
        XCTAssertEqual(skips, 1)
        store.selectPage(2)
        store.skip()
        XCTAssertEqual(skips, 1)
        store.start()
        XCTAssertEqual(starts, 1)
        store.selectPage(1)
        store.skip()
        XCTAssertEqual(skips, 2)
    }

    func testInitialAndChangedPageIndicesStayWithinThePager() async {
        let store = OnboardingStore(pageCount: 3, initialPage: 9, onSkip: {}, onStart: {})
        XCTAssertEqual(store.selectedPage, 2)
        store.selectPage(-5)
        XCTAssertEqual(store.selectedPage, 0)
        store.selectPage(100)
        XCTAssertEqual(store.selectedPage, 2)
        store.selectPage(1)
        XCTAssertEqual(store.selectedPage, 1)
    }

    func testSinglePageOnlyOffersTheFinalAction() async {
        var starts = 0
        var skips = 0
        let store = OnboardingStore(pageCount: 1, onSkip: { skips += 1 }, onStart: { starts += 1 })
        XCTAssertTrue(store.isLastPage)
        store.advance()
        store.skip()
        store.start()
        XCTAssertEqual(store.selectedPage, 0)
        XCTAssertEqual(skips, 0)
        XCTAssertEqual(starts, 1)
    }
}
