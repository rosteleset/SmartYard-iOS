//
//  FaceRegistrationWorkflowTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import RxSwift
import XCTest

private final class FaceRegistrationStub {
    enum Failure: Error { case disconnected }

    var calls: [String] = []
    var registeredId: Int? = 11
    var currentGroupId: Int?
    var failRegister = false
    var failCreate = false
    var failAttach = false
    var pendingRegistration: Single<Int?>?

    func makeWorkflow(groupsEnabled: Bool = true) -> FaceRegistrationWorkflow {
        FaceRegistrationWorkflow(
            dependencies: .init(
                register: { [self] in
                    calls.append("register")
                    return failRegister ? .error(Failure.disconnected) : pendingRegistration ?? .just(registeredId)
                },
                createGroup: { [self] name in
                    calls.append("create")
                    return failCreate ? .error(Failure.disconnected) : .just(.init(groupId: 7, groupName: name))
                },
                attach: { [self] _, groupId in
                    calls.append("attach")
                    currentGroupId = groupId
                    return failAttach ? .error(Failure.disconnected) : .just(())
                },
                detach: { [self] _, _ in
                    calls.append("detach")
                    currentGroupId = nil
                    return .just(())
                },
                faces: { [self] in
                    calls.append("faces")
                    return .just([.init(faceId: 11, image: "test", groupId: currentGroupId)])
                }
            ),
            groupsEnabled: { groupsEnabled },
            scheduler: CurrentThreadScheduler.instance
        )
    }
}

final class FaceRegistrationWorkflowTests: XCTestCase {
    func testInvalidNameDoesNotRegisterFace() {
        let api = FaceRegistrationStub()
        let workflow = api.makeWorkflow()
        XCTAssertThrowsError(try result(workflow.save(selection: .new(" \n "), onRegistered: {}))) {
            XCTAssertEqual($0 as? FaceRegistrationWorkflow.Failure, .invalidGroupName)
        }
        XCTAssertTrue(api.calls.isEmpty)
    }

    func testDisabledGroupsStillAllowUngroupedRegistration() throws {
        let api = FaceRegistrationStub()
        let workflow = api.makeWorkflow(groupsEnabled: false)
        XCTAssertThrowsError(try result(workflow.save(selection: .new("Family"), onRegistered: {}))) {
            XCTAssertEqual($0 as? FaceRegistrationWorkflow.Failure, .groupsUnavailable)
        }
        XCTAssertTrue(api.calls.isEmpty)
        XCTAssertNil(try result(workflow.save(selection: .ungrouped, onRegistered: {})))
        XCTAssertEqual(api.calls, ["register"])
    }

    func testPreparedRequestsDoNotRepeatRegistrationOrGroupCreation() throws {
        let api = FaceRegistrationStub()
        let workflow = api.makeWorkflow()
        let first = workflow.save(selection: .new(" Family "), onRegistered: {})
        let second = workflow.save(selection: .new("Family"), onRegistered: {})
        XCTAssertTrue(api.calls.isEmpty)
        XCTAssertEqual(try result(first)?.groupName, "Family")
        _ = try result(second)
        XCTAssertEqual(api.calls, ["register", "create", "attach", "attach"])
    }

    func testConcurrentRegistrationIsRejectedBeforeAnotherRequest() throws {
        let api = FaceRegistrationStub()
        let pending = PublishSubject<Int?>()
        api.pendingRegistration = pending.take(1).asSingle()
        let workflow = api.makeWorkflow()
        var finished = false
        let first = workflow.save(selection: .ungrouped, onRegistered: {}).subscribe(onSuccess: { _ in finished = true })
        defer { first.dispose() }
        XCTAssertThrowsError(try result(workflow.save(selection: .ungrouped, onRegistered: {}))) {
            XCTAssertEqual($0 as? FaceRegistrationWorkflow.Failure, .operationInProgress)
        }
        pending.onNext(11)
        XCTAssertTrue(finished)
        XCTAssertEqual(api.calls, ["register"])
        XCTAssertNil(try result(workflow.save(selection: .ungrouped, onRegistered: {})))
        XCTAssertEqual(api.calls, ["register"])
    }

    func testUngroupedRegistrationDoesNotCallGroupEndpoints() throws {
        let api = FaceRegistrationStub()
        let workflow = api.makeWorkflow()
        XCTAssertNil(try result(workflow.save(selection: .ungrouped, onRegistered: {})))
        XCTAssertEqual(api.calls, ["register"])
    }

    func testAttachRetryDoesNotRegisterOrCreateTwice() throws {
        let api = FaceRegistrationStub()
        api.failAttach = true
        let workflow = api.makeWorkflow()
        XCTAssertThrowsError(try result(workflow.save(selection: .new("Family"), onRegistered: {})))
        XCTAssertTrue(workflow.isRegistered)
        XCTAssertEqual(workflow.faceId, 11)
        XCTAssertEqual(workflow.createdGroup(named: "Family")?.groupId, 7)
        api.failAttach = false
        let group = try result(workflow.save(selection: .new("Family"), onRegistered: {}))
        XCTAssertEqual(group?.groupId, 7)
        XCTAssertEqual(api.calls, ["register", "create", "attach", "attach"])
    }

    func testCreateFailureRetryKeepsRegisteredFace() throws {
        let api = FaceRegistrationStub()
        api.failCreate = true
        let workflow = api.makeWorkflow()
        XCTAssertThrowsError(try result(workflow.save(selection: .new("Family"), onRegistered: {})))
        api.failCreate = false
        _ = try result(workflow.save(selection: .new("Family"), onRegistered: {}))
        XCTAssertEqual(api.calls, ["register", "create", "create", "attach"])
    }

    func testMissingIdentifierDoesNotRepeatSuccessfulLegacyRegistration() throws {
        let api = FaceRegistrationStub()
        api.registeredId = nil
        let workflow = api.makeWorkflow()
        let selection = FaceRegistrationWorkflow.Selection.existing(.init(groupId: 7, groupName: "Family"))
        XCTAssertThrowsError(try result(workflow.save(selection: selection, onRegistered: {}))) {
            XCTAssertEqual($0 as? FaceRegistrationWorkflow.Failure, .missingFaceIdentifier)
        }
        XCTAssertThrowsError(try result(workflow.save(selection: selection, onRegistered: {})))
        XCTAssertNil(try result(workflow.save(selection: .ungrouped, onRegistered: {})))
        XCTAssertEqual(api.calls, ["register"])
    }

    func testRegistrationFailureDoesNotStartGrouping() throws {
        let api = FaceRegistrationStub()
        api.failRegister = true
        let workflow = api.makeWorkflow()
        XCTAssertThrowsError(try result(workflow.save(selection: .new("Family"), onRegistered: {})))
        XCTAssertFalse(workflow.isRegistered)
        XCTAssertEqual(api.calls, ["register"])
    }

    func testUngroupedAfterUncertainAttachReadsBackAndDetaches() throws {
        let api = FaceRegistrationStub()
        api.failAttach = true
        let workflow = api.makeWorkflow()
        let group = APIFaceGroup(groupId: 7, groupName: "Family")
        XCTAssertThrowsError(try result(workflow.save(selection: .existing(group), onRegistered: {})))
        XCTAssertNil(try result(workflow.save(selection: .ungrouped, onRegistered: {})))
        XCTAssertEqual(api.calls, ["register", "attach", "faces", "detach"])
        XCTAssertNil(api.currentGroupId)
    }

    func testRegistrationIsPublishedBeforeAttachmentFailure() throws {
        let api = FaceRegistrationStub()
        api.failAttach = true
        var registeredCount = 0
        let workflow = api.makeWorkflow()
        XCTAssertThrowsError(try result(workflow.save(selection: .new("Family")) { registeredCount += 1 }))
        XCTAssertEqual(registeredCount, 1)
        api.failAttach = false
        _ = try result(workflow.save(selection: .new("Family")) { registeredCount += 1 })
        XCTAssertEqual(registeredCount, 1)
    }

    private func result<Value>(_ request: Single<Value>) throws -> Value {
        let finished = expectation(description: "Request completes")
        var outcome: Result<Value, Error>?
        let disposable = request.subscribe(
            onSuccess: {
                outcome = .success($0)
                finished.fulfill()
            },
            onFailure: {
                outcome = .failure($0)
                finished.fulfill()
            }
        )
        defer { disposable.dispose() }
        wait(for: [finished], timeout: 2)
        return try XCTUnwrap(outcome).get()
    }
}
