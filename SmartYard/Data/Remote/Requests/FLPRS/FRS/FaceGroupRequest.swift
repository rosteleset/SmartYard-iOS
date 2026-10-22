//
//  FaceGroupRequest.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

struct FaceGroupRequest {
    enum Operation {
        case list(flatId: Int)
        case create(flatId: Int, name: String)
        case rename(flatId: Int, groupId: Int, name: String)
        case delete(flatId: Int, groupId: Int)
        case attach(faceId: Int, groupId: Int)
        case detach(faceId: Int, groupId: Int)
        case cluster(flatId: Int, prefix: String)
    }

    let accessToken: String
    let operation: Operation

    var path: String {
        switch operation {
        case .list: return "user/listGroups"
        case .create: return "user/addGroup"
        case .rename: return "user/updateGroup"
        case .delete: return "user/deleteGroup"
        case .attach: return "frs/attachFaceToGroup"
        case .detach: return "frs/detachFaceFromGroup"
        case .cluster: return "frs/clusterFaces"
        }
    }

    var forceRefresh: Bool {
        if case .list = operation { return true }
        return false
    }

    var requestParameters: [String: Any] {
        switch operation {
        case let .list(flatId): return ["flatId": flatId]
        case let .create(flatId, name): return ["flatId": flatId, "groupName": name]
        case let .rename(flatId, groupId, name):
            return ["flatId": flatId, "groupId": groupId, "groupName": name]
        case let .delete(flatId, groupId): return ["flatId": flatId, "groupId": groupId]
        case let .attach(faceId, groupId), let .detach(faceId, groupId):
            return ["faceId": faceId, "groupId": groupId]
        case let .cluster(flatId, prefix): return ["flatId": flatId, "prefixName": prefix]
        }
    }
}
