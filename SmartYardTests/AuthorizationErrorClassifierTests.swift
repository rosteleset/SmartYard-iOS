//
//  AuthorizationErrorClassifierTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 LanTa. All rights reserved.
//

import Foundation
import XCTest

final class AuthorizationErrorClassifierTests: XCTestCase {
    func testCode401IsUnauthorized() {
        let error = NSError(domain: "Backend", code: 401)

        XCTAssertTrue(AuthorizationErrorClassifier.isUnauthorized(error))
    }

    func testCurrentBehaviorIgnoresErrorDomain() {
        let error = NSError(domain: NSURLErrorDomain, code: 401)

        XCTAssertTrue(AuthorizationErrorClassifier.isUnauthorized(error))
    }

    func testAnotherCodeIsNotUnauthorized() {
        let error = NSError(domain: "Backend", code: 403)

        XCTAssertFalse(AuthorizationErrorClassifier.isUnauthorized(error))
    }

    func testUnauthorizedErrorTriggersHandlerAndIsNotForwarded() {
        var handlerCallCount = 0

        let forwardedError = AuthorizationErrorClassifier.errorToForward(
            NSError(domain: "Backend", code: 401),
            onUnauthorized: { handlerCallCount += 1 }
        )

        XCTAssertNil(forwardedError)
        XCTAssertEqual(handlerCallCount, 1)
    }

    func testAnotherErrorIsForwardedWithoutTriggeringHandler() throws {
        let error = NSError(domain: "Backend", code: 403)
        var handlerCallCount = 0

        let forwardedError = AuthorizationErrorClassifier.errorToForward(
            error,
            onUnauthorized: { handlerCallCount += 1 }
        )

        XCTAssertEqual(try XCTUnwrap(forwardedError as NSError?).code, 403)
        XCTAssertEqual(handlerCallCount, 0)
    }
}
