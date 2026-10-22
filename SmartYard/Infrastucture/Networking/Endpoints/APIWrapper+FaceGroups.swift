//
//  APIWrapper+FaceGroups.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation
import Moya
import RxSwift

extension APIWrapper {
    func faceRegistrationWorkflow(eventId: String, flatId: Int) -> FaceRegistrationWorkflow {
        FaceRegistrationWorkflow(
            dependencies: .init(
                register: { self.registerPersonFace(event: eventId) },
                createGroup: { name in
                    self.createFaceGroup(flatId: flatId, name: name)
                        .map { APIFaceGroup(groupId: $0.groupId, groupName: name) }
                },
                attach: { self.attachFaceToGroup(faceId: $0, groupId: $1) },
                detach: { self.detachFaceFromGroup(faceId: $0, groupId: $1) },
                faces: { self.getPersonFaces(flatId: flatId, forceRefresh: true).map { $0 ?? [] } }
            ),
            groupsEnabled: { self.accessService.faceGroupsEnabled }
        )
    }

    func getFaceGroups(flatId: Int) -> Single<[APIFaceGroup]> {
        faceGroupRequest(.list(flatId: flatId)).mapAsEmptyDataInitializableResponse()
    }

    func createFaceGroup(flatId: Int, name: String) -> Single<AddFaceGroupResponse> {
        faceGroupRequest(.create(flatId: flatId, name: name)).mapAsDefaultResponse()
    }

    func renameFaceGroup(flatId: Int, groupId: Int, name: String) -> Single<Void> {
        faceGroupRequest(.rename(flatId: flatId, groupId: groupId, name: name)).mapAsVoidResponse()
    }

    func deleteFaceGroup(flatId: Int, groupId: Int) -> Single<Void> {
        faceGroupRequest(.delete(flatId: flatId, groupId: groupId)).mapAsVoidResponse()
    }

    func attachFaceToGroup(faceId: Int, groupId: Int) -> Single<Void> {
        faceGroupRequest(.attach(faceId: faceId, groupId: groupId)).mapAsVoidResponse()
    }

    func detachFaceFromGroup(faceId: Int, groupId: Int) -> Single<Void> {
        faceGroupRequest(.detach(faceId: faceId, groupId: groupId)).mapAsVoidResponse()
    }

    func clusterFaces(flatId: Int, prefix: String) -> Single<Void> {
        faceGroupRequest(.cluster(flatId: flatId, prefix: prefix)).mapAsVoidResponse()
    }

    private func faceGroupRequest(_ operation: FaceGroupRequest.Operation) -> Single<Response> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        return provider.rx.request(.faceGroup(request: .init(accessToken: accessToken, operation: operation)))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
    }
}
