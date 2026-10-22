//
//  MockFacesRepositoryTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import RxSwift
import XCTest

final class MockFacesRepositoryTests: XCTestCase {
    func testFixtureAndDeferredMutations() throws {
        let repository = MockFacesRepository()
        XCTAssertEqual(try result(repository.faces()).count, 8)
        XCTAssertEqual(try result(repository.groups()).count, 2)
        let create = repository.createGroup(name: "Test")
        XCTAssertEqual(try result(repository.groups()).count, 2)
        XCTAssertEqual(try result(create), 3)
        XCTAssertEqual(try result(repository.groups()).last?.groupName, "Test")
    }

    func testMoveDetachRenameAndTracking() throws {
        let repository = MockFacesRepository()
        let face = try XCTUnwrap(result(repository.faces()).last)
        let group = try XCTUnwrap(result(repository.groups()).first)
        _ = try result(repository.moveFace(face, to: group))
        XCTAssertEqual(try result(repository.faces()).last?.groupId, group.groupId)
        _ = try result(repository.detachFace(face))
        XCTAssertNil(try result(repository.faces()).last?.groupId)
        _ = try result(repository.renameGroup(group, name: "Renamed"))
        _ = try result(repository.toggleTracking(group))
        let renamed = try XCTUnwrap(result(repository.groups()).first)
        XCTAssertEqual(renamed.groupName, "Renamed")
        XCTAssertNotNil(renamed.watcherId)
        _ = try result(repository.toggleTracking(renamed))
        XCTAssertNil(try result(repository.groups()).first?.watcherId)
    }

    func testClusteringReusesExistingGroupAndPairsNewIdentities() throws {
        let repository = MockFacesRepository()
        _ = try result(repository.cluster(prefix: "Auto"))
        let faces = try result(repository.faces())
        XCTAssertFalse(faces.contains { $0.groupId == nil })
        XCTAssertEqual(faces[3].groupId, 2)
        XCTAssertEqual(faces[4].groupId, faces[5].groupId)
        XCTAssertEqual(faces[6].groupId, faces[7].groupId)
        XCTAssertNotEqual(faces[4].groupId, faces[6].groupId)
        XCTAssertEqual(try result(repository.groups()).count, 4)
        _ = try result(repository.cluster(prefix: "Again"))
        XCTAssertEqual(try result(repository.groups()).count, 4)
    }

    func testDeleteGroupAlsoDeletesItsFacesAndDoesNotReuseIds() throws {
        let repository = MockFacesRepository()
        let group = try XCTUnwrap(result(repository.groups()).first)
        _ = try result(repository.deleteGroup(group))
        XCTAssertEqual(try result(repository.faces()).count, 6)
        XCTAssertFalse(try result(repository.faces()).contains { $0.groupId == group.groupId })
        let id = try result(repository.createGroup(name: "New"))
        XCTAssertGreaterThan(id, 2)
    }

    func testDeletingFaceAndFreshSessionAreIsolated() throws {
        let repository = MockFacesRepository()
        let face = try XCTUnwrap(result(repository.faces()).first)
        _ = try result(repository.deleteFace(face))
        XCTAssertEqual(try result(repository.faces()).count, 7)
        let fresh = MockFacesRepository()
        XCTAssertEqual(try result(fresh.faces()).count, 8)
        XCTAssertEqual(try result(fresh.groups()).count, 2)
    }

    func testMutationDoesNotBroadcastToLiveAccount() {
        let observer = NotificationCenter.default.addObserver(
            forName: .init("UpdateFaces"), object: nil, queue: nil
        ) { _ in XCTFail("Mock mutations must not refresh the live account") }
        defer { NotificationCenter.default.removeObserver(observer) }
        MockFacesRepository().didMutate(sender: self)
    }

    func testRegistrationIsDeferredAndAllocatesUniqueIdentifiers() throws {
        let repository = MockFacesRepository()
        let registration = repository.registerFixture()
        XCTAssertEqual(try result(repository.faces()).count, 8)
        XCTAssertEqual(try result(registration), 9)
        XCTAssertEqual(try result(repository.registerFixture()), 10)
        XCTAssertEqual(try result(repository.faces()).count, 10)
        XCTAssertNil(try result(repository.faces()).last?.groupId)
    }

    func testRegisteredFixtureCanJoinAnExistingGroupThroughClustering() throws {
        let repository = MockFacesRepository()
        _ = try result(repository.registerFixture())
        _ = try result(repository.cluster(prefix: "Auto"))
        XCTAssertEqual(try result(repository.faces()).last?.groupId, 1)
    }

    private func result<T>(_ operation: Single<T>) throws -> T {
        var received: Result<T, Error>?
        let disposable = operation.subscribe { received = $0 }
        defer { disposable.dispose() }
        return try XCTUnwrap(received).get()
    }
}
