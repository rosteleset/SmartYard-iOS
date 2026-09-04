//
//  LogoutWorkflowTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 LanTa. All rights reserved.
//

import RxSwift
import XCTest

final class LogoutWorkflowTests: XCTestCase {
    func testSubscriptionStartsPushCleanupAndWaitsForResetCompletion() {
        let recorder = Recorder()
        let resetSubject = PublishSubject<Void>()
        let workflow = makeWorkflow(
            recorder: recorder,
            resetPushRegistration: resetSubject.ignoreElements().asCompletable()
        )

        XCTAssertTrue(recorder.events.isEmpty)

        let disposable = workflow.run().subscribe()
        defer { disposable.dispose() }

        XCTAssertEqual(
            recorder.events,
            ["disablePushAutoInit", "deletePushToken", "resetPushRegistration"]
        )
    }

    func testResetCompletionFinishesLocalLogoutInCurrentOrder() {
        let recorder = Recorder()
        let resetSubject = PublishSubject<Void>()
        let workflow = makeWorkflow(
            recorder: recorder,
            resetPushRegistration: resetSubject.ignoreElements().asCompletable()
        )
        var didComplete = false

        let disposable = workflow.run()
            .subscribe(onCompleted: {
                didComplete = true
            })
        defer { disposable.dispose() }

        resetSubject.onCompleted()

        XCTAssertEqual(
            recorder.events,
            [
                "disablePushAutoInit",
                "deletePushToken",
                "resetPushRegistration",
                "clearSharedData",
                "clearSession"
            ]
        )
        XCTAssertTrue(didComplete)
    }

    func testResetFailureStillFinishesLocalLogout() {
        let recorder = Recorder()
        let workflow = makeWorkflow(
            recorder: recorder,
            resetPushRegistration: .error(TestError.resetFailed)
        )
        var didComplete = false
        var receivedError: Error?

        let disposable = workflow.run()
            .subscribe(
                onCompleted: {
                    didComplete = true
                },
                onError: { error in
                    receivedError = error
                }
            )
        defer { disposable.dispose() }

        XCTAssertEqual(
            recorder.events,
            [
                "disablePushAutoInit",
                "deletePushToken",
                "resetPushRegistration",
                "clearSharedData",
                "clearSession"
            ]
        )
        XCTAssertTrue(didComplete)
        XCTAssertNil(receivedError)
    }

    private func makeWorkflow(
        recorder: Recorder,
        resetPushRegistration: Completable
    ) -> LogoutWorkflow {
        return LogoutWorkflow(
            disableAutomaticPushRegistration: {
                recorder.events.append("disablePushAutoInit")
            },
            deletePushToken: {
                recorder.events.append("deletePushToken")
            },
            resetPushRegistration: {
                recorder.events.append("resetPushRegistration")

                return resetPushRegistration
            },
            clearSharedData: {
                recorder.events.append("clearSharedData")
            },
            clearSession: {
                recorder.events.append("clearSession")
            }
        )
    }

    private final class Recorder {
        var events = [String]()
    }

    private enum TestError: Error {
        case resetFailed
    }
}
