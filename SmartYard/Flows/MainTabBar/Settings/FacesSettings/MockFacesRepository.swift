//
//  MockFacesRepository.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

#if DEBUG
import RxSwift

/// In-memory fixtures only. Clustering uses fixture identities, not face recognition.
final class MockFacesRepository: FacesRepository {
    let groupsEnabled = true
    let clusteringEnabled = true
    let trackingEnabled = true
    var optionsUpdated: Observable<Void> { .empty() }
    private var storedFaces: [APIFace]
    private var storedGroups: [APIFaceGroup]
    private var nextGroupId = 3
    private(set) var nextFaceId = 9

    init(groupPrefix: String = "Group") {
        storedGroups = [
            .init(groupId: 1, groupName: "\(groupPrefix) 1"),
            .init(groupId: 2, groupName: "\(groupPrefix) 2", watcherId: 2)
        ]
        storedFaces = (1...8).map { id in
            .init(faceId: id, image: "", groupId: id <= 2 ? 1 : (id == 3 ? 2 : nil))
        }
    }

    func faces() -> Single<[APIFace]> { .deferred { .just(self.storedFaces) } }
    func groups() -> Single<[APIFaceGroup]> { .deferred { .just(self.storedGroups) } }

    func registerFixture() -> Single<Int> {
        .deferred {
            let id = self.nextFaceId
            self.nextFaceId += 1
            self.storedFaces.append(.init(faceId: id, image: ""))
            return .just(id)
        }
    }

    func createGroup(name: String) -> Single<Int> {
        .deferred {
            let id = self.insertGroup(name: name)
            return .just(id)
        }
    }

    func renameGroup(_ group: APIFaceGroup, name: String) -> Single<Void> {
        change {
            self.storedGroups = self.storedGroups.map {
                $0.groupId == group.groupId ? .init(groupId: $0.groupId, groupName: name, watcherId: $0.watcherId) : $0
            }
        }
    }

    func deleteGroup(_ group: APIFaceGroup) -> Single<Void> {
        change {
            self.storedGroups.removeAll { $0.groupId == group.groupId }
            // Match server semantics: deleting a group also removes its registered faces.
            self.storedFaces.removeAll { $0.groupId == group.groupId }
        }
    }

    func moveFace(_ face: APIFace, to group: APIFaceGroup) -> Single<Void> {
        change { self.assign(faceId: face.faceId, groupId: group.groupId) }
    }

    func detachFace(_ face: APIFace) -> Single<Void> {
        change { self.assign(faceId: face.faceId, groupId: nil) }
    }

    func deleteFace(_ face: APIFace) -> Single<Void> {
        change { self.storedFaces.removeAll { $0.faceId == face.faceId } }
    }

    func cluster(prefix: String) -> Single<Void> {
        change {
            let ungrouped = self.storedFaces.filter { $0.groupId == nil }
            for face in ungrouped {
                let identity = Self.identity(face.faceId)
                let matchingGroup = self.storedFaces.first {
                    Self.identity($0.faceId) == identity && $0.groupId != nil
                }?.groupId
                let groupId = matchingGroup ?? self.insertGroup(name: "\(prefix) \(self.nextGroupId)")
                self.assign(faceId: face.faceId, groupId: groupId)
            }
        }
    }

    func toggleTracking(_ group: APIFaceGroup) -> Single<Void> {
        change {
            self.storedGroups = self.storedGroups.map {
                guard $0.groupId == group.groupId else { return $0 }
                return .init(groupId: $0.groupId, groupName: $0.groupName, watcherId: $0.watcherId == nil ? $0.groupId : nil)
            }
        }
    }

    // Never broadcast changes into the live account or touch its caches/preferences.
    func didMutate(sender: AnyObject) {}

    private func change(_ body: @escaping () -> Void) -> Single<Void> {
        .deferred {
            body()
            return .just(())
        }
    }

    private func insertGroup(name: String) -> Int {
        let id = nextGroupId
        nextGroupId += 1
        storedGroups.append(.init(groupId: id, groupName: name))
        return id
    }

    private func assign(faceId: Int, groupId: Int?) {
        storedFaces = storedFaces.map {
            $0.faceId == faceId ? .init(faceId: $0.faceId, image: $0.image, groupId: groupId) : $0
        }
    }

    private static func identity(_ faceId: Int) -> Int { ((faceId - 1) / 2) % 4 }

}
#endif
