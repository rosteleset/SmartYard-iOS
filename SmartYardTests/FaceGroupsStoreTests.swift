//
//  FaceGroupsStoreTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import RxSwift
import XCTest

private final class FaceGroupsRepositoryStub: FacesRepository {
    enum Failure: Error { case disconnected }

    let backing = MockFacesRepository()
    var groupsEnabled = true
    var clusteringEnabled = true
    var trackingEnabled = true
    let options = PublishSubject<Void>()
    let changed = PublishSubject<AnyObject?>()
    var optionsUpdated: Observable<Void> { options.asObservable() }
    var changes: Observable<AnyObject?> { changed.asObservable() }
    var calls: [String] = []
    var faceRequests: [Single<[APIFace]>] = []
    var pendingRename: Single<Void>?
    var failAfterRename = false
    var mutationNotifications = 0

    func faces() -> Single<[APIFace]> {
        .deferred {
            self.calls.append("faces")
            return self.faceRequests.isEmpty ? self.backing.faces() : self.faceRequests.removeFirst()
        }
    }

    func groups() -> Single<[APIFaceGroup]> { record("groups", backing.groups()) }
    func createGroup(name: String) -> Single<Int> { record("create", backing.createGroup(name: name)) }

    func renameGroup(_ group: APIFaceGroup, name: String) -> Single<Void> {
        record("rename", backing.renameGroup(group, name: name)).flatMap {
            if self.failAfterRename { return .error(Failure.disconnected) }
            return self.pendingRename ?? .just(())
        }
    }

    func deleteGroup(_ group: APIFaceGroup) -> Single<Void> { record("deleteGroup", backing.deleteGroup(group)) }
    func moveFace(_ face: APIFace, to group: APIFaceGroup) -> Single<Void> {
        record("move", backing.moveFace(face, to: group))
    }
    func detachFace(_ face: APIFace) -> Single<Void> { record("detach", backing.detachFace(face)) }
    func deleteFace(_ face: APIFace) -> Single<Void> { record("deleteFace", backing.deleteFace(face)) }
    func cluster(prefix: String) -> Single<Void> { record("cluster", backing.cluster(prefix: prefix)) }
    func toggleTracking(_ group: APIFaceGroup) -> Single<Void> { record("tracking", backing.toggleTracking(group)) }

    func didMutate(sender: AnyObject) {
        mutationNotifications += 1
        changed.onNext(sender)
    }

    private func record<Value>(_ name: String, _ request: Single<Value>) -> Single<Value> {
        .deferred {
            self.calls.append(name)
            return request
        }
    }
}

final class FaceGroupsStoreTests: XCTestCase {
    private func store(_ repository: FacesRepository = MockFacesRepository()) -> FaceGroupsStore {
        FaceGroupsStore(repository: repository, scheduler: CurrentThreadScheduler.instance)
    }

    func testInitialLoadAndLocalFilters() {
        let model = store()
        XCTAssertFalse(model.currentState.hasLoaded)
        model.refresh()
        XCTAssertTrue(model.currentState.hasLoaded)
        XCTAssertEqual(model.currentState.faces.count, 8)
        XCTAssertEqual(model.currentState.groups.count, 2)
        model.select(.group(1))
        XCTAssertEqual(model.currentState.visibleFaces.map(\.faceId), [1, 2])
        model.select(.ungrouped)
        XCTAssertEqual(model.currentState.visibleFaces.count, 5)
        model.select(.group(99))
        XCTAssertEqual(model.currentState.filter, .all)
    }

    func testCreateEditAndDeleteGroup() throws {
        let model = store()
        model.refresh()
        model.createGroup(name: "  Family  ", isTracked: true)
        var group = try XCTUnwrap(model.currentState.selectedGroup)
        XCTAssertEqual(group.groupName, "Family")
        XCTAssertNotNil(group.watcherId)
        model.editGroup(group, name: "  Renamed  ", isTracked: false)
        group = try XCTUnwrap(model.currentState.selectedGroup)
        XCTAssertEqual(group.groupName, "Renamed")
        XCTAssertNil(group.watcherId)
        model.deleteGroup(group)
        XCTAssertEqual(model.currentState.filter, .all)
        XCTAssertEqual(model.currentState.groups.count, 2)
    }

    func testMoveDetachAndDeleteFace() throws {
        let repository = FaceGroupsRepositoryStub()
        let model = store(repository)
        model.refresh()
        let face = try XCTUnwrap(model.currentState.faces.last)
        let group = try XCTUnwrap(model.currentState.groups.first)
        model.moveFace(face, to: group)
        XCTAssertEqual(model.currentState.faces.last?.groupId, group.groupId)
        model.detachFace(try XCTUnwrap(model.currentState.faces.last))
        XCTAssertNil(model.currentState.faces.last?.groupId)
        model.deleteFace(face)
        XCTAssertEqual(model.currentState.faces.count, 7)
        XCTAssertEqual(repository.mutationNotifications, 3)
        XCTAssertEqual(repository.calls.filter { $0 == "faces" }.count, 4)
    }

    func testDeletingSelectedGroupAlsoRemovesItsFaces() throws {
        let model = store()
        model.refresh()
        model.select(.group(1))
        model.deleteGroup(try XCTUnwrap(model.currentState.selectedGroup))
        XCTAssertEqual(model.currentState.filter, .all)
        XCTAssertEqual(model.currentState.faces.count, 6)
        XCTAssertFalse(model.currentState.faces.contains { $0.groupId == 1 })
    }

    func testClusteringOnlyRunsForNonEmptyUngroupedSelection() {
        let repository = FaceGroupsRepositoryStub()
        let model = store(repository)
        model.refresh()
        model.cluster(prefix: "Auto")
        XCTAssertFalse(repository.calls.contains("cluster"))
        model.select(.ungrouped)
        model.cluster(prefix: "   ")
        XCTAssertFalse(repository.calls.contains("cluster"))
        model.cluster(prefix: "Auto")
        XCTAssertEqual(model.currentState.groups.count, 4)
        XCTAssertTrue(model.currentState.visibleFaces.isEmpty)
        model.cluster(prefix: "Again")
        XCTAssertEqual(repository.calls.filter { $0 == "cluster" }.count, 1)
    }

    func testDisabledGroupsBlockGroupCommandsButNotFaceDeletion() throws {
        let repository = FaceGroupsRepositoryStub()
        repository.groupsEnabled = false
        let model = store(repository)
        model.refresh()
        let group = APIFaceGroup(groupId: 1, groupName: "Group")
        let face = try XCTUnwrap(model.currentState.faces.first)
        model.createGroup(name: "New")
        model.renameGroup(group, name: "Renamed")
        model.deleteGroup(group)
        model.moveFace(face, to: .init(groupId: 2, groupName: "Other"))
        model.detachFace(face)
        model.toggleTracking(group)
        model.select(.ungrouped)
        model.cluster(prefix: "Auto")
        XCTAssertEqual(repository.calls, ["faces"])
        XCTAssertEqual(model.currentState.filter, .all)
        model.deleteFace(face)
        XCTAssertEqual(model.currentState.faces.count, 7)
    }

    func testDisabledTrackingDoesNotChangeWatchersDuringRename() throws {
        let repository = FaceGroupsRepositoryStub()
        repository.trackingEnabled = false
        let model = store(repository)
        model.refresh()
        let group = try XCTUnwrap(model.currentState.groups.last)
        model.editGroup(group, name: "Renamed", isTracked: false)
        XCTAssertEqual(model.currentState.groups.last?.watcherId, group.watcherId)
        model.createGroup(name: "New", isTracked: true)
        XCTAssertNil(model.currentState.selectedGroup?.watcherId)
        XCTAssertFalse(repository.calls.contains("tracking"))
    }

    func testBlankNamesAndCommandsBeforeLoadingDoNothing() {
        let repository = FaceGroupsRepositoryStub()
        let model = store(repository)
        model.createGroup(name: "Not loaded")
        XCTAssertTrue(repository.calls.isEmpty)
        model.refresh()
        model.createGroup(name: " \n ")
        model.renameGroup(.init(groupId: 1, groupName: "Group"), name: " ")
        XCTAssertEqual(repository.calls, ["faces", "groups"])
    }

    func testLatestRefreshWins() {
        let repository = FaceGroupsRepositoryStub()
        let first = PublishSubject<[APIFace]>()
        let second = PublishSubject<[APIFace]>()
        repository.faceRequests = [first.take(1).asSingle(), second.take(1).asSingle()]
        let model = store(repository)
        model.refresh()
        model.refresh()
        second.onNext([.init(faceId: 20, image: "")])
        first.onNext([.init(faceId: 10, image: "")])
        XCTAssertEqual(model.currentState.faces.map(\.faceId), [20])
        XCTAssertFalse(model.currentState.isLoading)
    }

    func testPendingMutationBlocksDuplicateCommandsAndRefresh() throws {
        let repository = FaceGroupsRepositoryStub()
        let pending = PublishSubject<Void>()
        repository.pendingRename = pending.take(1).asSingle()
        let model = store(repository)
        model.refresh()
        let group = try XCTUnwrap(model.currentState.groups.first)
        model.renameGroup(group, name: "Renamed")
        model.renameGroup(group, name: "Duplicate")
        model.createGroup(name: "Duplicate")
        model.refresh()
        model.select(.ungrouped)
        XCTAssertTrue(model.currentState.isLoading)
        XCTAssertEqual(repository.calls, ["faces", "groups", "rename"])
        XCTAssertEqual(model.currentState.filter, .all)
        pending.onNext(())
        XCTAssertFalse(model.currentState.isLoading)
        XCTAssertEqual(model.currentState.groups.first?.groupName, "Renamed")
    }

    func testMutationFailureReconcilesServerStateAndEmitsError() throws {
        let repository = FaceGroupsRepositoryStub()
        repository.failAfterRename = true
        let model = store(repository)
        var errors: [Error] = []
        let subscription = model.errors.subscribe(onNext: { errors.append($0) })
        defer { subscription.dispose() }
        model.refresh()
        model.renameGroup(try XCTUnwrap(model.currentState.groups.first), name: "Committed before disconnect")
        XCTAssertEqual(model.currentState.groups.first?.groupName, "Committed before disconnect")
        XCTAssertFalse(model.currentState.isLoading)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(repository.calls.filter { $0 == "faces" }.count, 2)
    }

    func testLoadErrorCanBeRetriedWithoutTerminatingStateStream() {
        let repository = FaceGroupsRepositoryStub()
        repository.faceRequests = [.error(FaceGroupsRepositoryStub.Failure.disconnected)]
        let model = store(repository)
        var states: [FaceGroupsStore.State] = []
        let subscription = model.state.subscribe(onNext: { states.append($0) })
        defer { subscription.dispose() }
        model.refresh()
        XCTAssertFalse(model.currentState.hasLoaded)
        XCTAssertFalse(model.currentState.isLoading)
        model.refresh()
        XCTAssertTrue(model.currentState.hasLoaded)
        XCTAssertEqual(states.map(\.isLoading), [false, true, false, true, false])
    }

    func testRepositoryAndCapabilityChangesRefreshState() {
        let repository = FaceGroupsRepositoryStub()
        let model = store(repository)
        model.refresh()
        model.select(.group(1))
        repository.changed.onNext(nil)
        XCTAssertEqual(repository.calls.filter { $0 == "faces" }.count, 2)
        repository.groupsEnabled = false
        repository.options.onNext(())
        XCTAssertTrue(model.currentState.groups.isEmpty)
        XCTAssertEqual(model.currentState.filter, .all)
    }
}
