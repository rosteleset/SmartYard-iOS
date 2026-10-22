//
//  FacesRepository.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import RxSwift

protocol FacesRepository: AnyObject {
    var groupsEnabled: Bool { get }
    var clusteringEnabled: Bool { get }
    var trackingEnabled: Bool { get }
    var optionsUpdated: Observable<Void> { get }
    var changes: Observable<AnyObject?> { get }

    func faces() -> Single<[APIFace]>
    func groups() -> Single<[APIFaceGroup]>
    func createGroup(name: String) -> Single<Int>
    func renameGroup(_ group: APIFaceGroup, name: String) -> Single<Void>
    func deleteGroup(_ group: APIFaceGroup) -> Single<Void>
    func moveFace(_ face: APIFace, to group: APIFaceGroup) -> Single<Void>
    func detachFace(_ face: APIFace) -> Single<Void>
    func deleteFace(_ face: APIFace) -> Single<Void>
    func cluster(prefix: String) -> Single<Void>
    func toggleTracking(_ group: APIFaceGroup) -> Single<Void>
    func didMutate(sender: AnyObject)
}

extension FacesRepository {
    var changes: Observable<AnyObject?> { .empty() }
}
