//
//  APIFaceGroup.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation

struct AddFaceGroupResponse: Decodable {
    let groupId: Int

    private enum CodingKeys: String, CodingKey { case groupId }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        groupId = try container.decodePositiveIdentifier(forKey: .groupId)
    }
}

struct LikeFaceResponse: Decodable {
    let faceId: Int?

    private enum CodingKeys: String, CodingKey { case faceId }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        faceId = try container.decodePositiveIdentifierIfPresent(forKey: .faceId)
    }
}

enum FaceGroupFilter: Equatable {
    case all
    case ungrouped
    case group(Int)

    func includes(_ face: APIFace) -> Bool {
        switch self {
        case .all: return true
        case .ungrouped: return face.groupId == nil
        case .group(let groupId): return face.groupId == groupId
        }
    }

    func resolved(in groups: [APIFaceGroup]) -> FaceGroupFilter {
        guard case .group(let groupId) = self else { return self }
        return groups.contains { $0.groupId == groupId } ? self : .all
    }
}

struct FaceGroupMetadata: Equatable {
    let groupId: Int?
    let groupName: String?

    static func resolve(
        faceId: Int?,
        groupId: Int?,
        groupName: String?,
        faces: [APIFace]?,
        groups: [APIFaceGroup]?
    ) -> FaceGroupMetadata {
        var id = groupId
        if let faces, let faceId {
            id = faces.first { $0.faceId == faceId }?.groupId
        }
        guard let id, id > 0 else { return .init(groupId: nil, groupName: nil) }
        if let groups {
            guard let group = groups.first(where: { $0.groupId == id }) else {
                return .init(groupId: nil, groupName: nil)
            }
            return .init(groupId: id, groupName: group.groupName)
        }
        return .init(groupId: id, groupName: id == groupId ? groupName : nil)
    }
}

struct APIFaceGroup: Decodable, Equatable {
    let groupId: Int
    let groupName: String
    let watcherId: Int?

    private enum CodingKeys: String, CodingKey {
        case groupId, groupName, watcherId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        groupId = try container.decodePositiveIdentifier(forKey: .groupId)
        groupName = try container.decode(String.self, forKey: .groupName)
        watcherId = try container.decodePositiveIdentifierIfPresent(forKey: .watcherId)
    }

    init(groupId: Int, groupName: String, watcherId: Int? = nil) {
        self.groupId = groupId
        self.groupName = groupName
        self.watcherId = watcherId
    }
}

extension KeyedDecodingContainer {
    /// Legacy operators send identifiers as strings. Zero and null both mean no group/watcher.
    func decodePositiveIdentifierIfPresent(forKey key: Key) throws -> Int? {
        guard contains(key), try !decodeNil(forKey: key) else { return nil }
        let value: Int
        if let number = try? decode(Int.self, forKey: key) {
            value = number
        } else if let number = Int(try decode(String.self, forKey: key)) {
            value = number
        } else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Invalid identifier")
        }
        return value > 0 ? value : nil
    }

    func decodePositiveIdentifier(forKey key: Key) throws -> Int {
        guard let value = try decodePositiveIdentifierIfPresent(forKey: key) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Missing positive identifier"
            )
        }
        return value
    }
}
