//
//  ServerFacesRepository.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import RxCocoa
import RxSwift

final class ServerFacesRepository: FacesRepository {
    private let api: APIWrapper
    private let access: AccessService
    private let flatId: Int

    var groupsEnabled: Bool { access.faceGroupsEnabled }
    var clusteringEnabled: Bool { groupsEnabled && access.faceClusteringEnabled }
    var trackingEnabled: Bool { groupsEnabled && access.eventsTrackingEnabled }
    var optionsUpdated: Observable<Void> { access.optionsUpdated.asObservable() }
    var changes: Observable<AnyObject?> {
        Observable.merge(
            NotificationCenter.default.rx.notification(.updateFaces),
            NotificationCenter.default.rx.notification(.trackedEventsChanged)
        )
        .map { $0.object as AnyObject? }
    }

    init(api: APIWrapper, access: AccessService, flatId: Int) {
        self.api = api
        self.access = access
        self.flatId = flatId
    }

    func faces() -> Single<[APIFace]> {
        api.getPersonFaces(flatId: flatId, forceRefresh: true).map { $0 ?? [] }
    }

    func groups() -> Single<[APIFaceGroup]> { api.getFaceGroups(flatId: flatId) }

    func createGroup(name: String) -> Single<Int> {
        api.createFaceGroup(flatId: flatId, name: name).map(\.groupId)
    }

    func renameGroup(_ group: APIFaceGroup, name: String) -> Single<Void> {
        api.renameFaceGroup(flatId: flatId, groupId: group.groupId, name: name)
    }

    func deleteGroup(_ group: APIFaceGroup) -> Single<Void> {
        api.deleteFaceGroup(flatId: flatId, groupId: group.groupId)
    }

    func moveFace(_ face: APIFace, to group: APIFaceGroup) -> Single<Void> {
        api.attachFaceToGroup(faceId: face.faceId, groupId: group.groupId)
    }

    func detachFace(_ face: APIFace) -> Single<Void> {
        guard let groupId = face.groupId else { return .just(()) }
        return api.detachFaceFromGroup(faceId: face.faceId, groupId: groupId)
    }

    func deleteFace(_ face: APIFace) -> Single<Void> {
        api.disLikePersonFace(flatId: flatId, faceId: face.faceId).map { _ in () }
    }

    func cluster(prefix: String) -> Single<Void> { api.clusterFaces(flatId: flatId, prefix: prefix) }

    func toggleTracking(_ group: APIFaceGroup) -> Single<Void> {
        if let watcherId = group.watcherId {
            return api.untrackEvent(watcherId: watcherId).map { _ in () }
        }
        return api
            .trackEvent(
                flatId: flatId,
                eventType: APIPlog.EventType.face.rawValue,
                eventDetail: String(group.groupId),
                comments: ""
            )
            .map { _ in () }
    }

    func didMutate(sender: AnyObject) {
        api.forceUpdateFaces = true
        NotificationCenter.default.post(name: .updateFaces, object: sender)
        NotificationCenter.default.post(name: .trackedEventsChanged, object: sender)
    }
}
