//
//  FaceGroupsStore.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation
import RxSwift

/// UI-independent state and commands. Call commands on the injected serial scheduler.
final class FaceGroupsStore {
    struct State {
        var faces: [APIFace] = []
        var groups: [APIFaceGroup] = []
        var filter: FaceGroupFilter = .all
        var isLoading = false
        var hasLoaded = false

        var visibleFaces: [APIFace] { faces.filter(filter.includes) }
        var selectedGroup: APIFaceGroup? {
            guard case .group(let id) = filter else { return nil }
            return groups.first { $0.groupId == id }
        }
    }

    private(set) var currentState = State()
    var state: Observable<State> { stateSubject.asObservable() }
    var errors: Observable<Error> { errorSubject.asObservable() }
    var groupsEnabled: Bool { repository.groupsEnabled }
    var clusteringEnabled: Bool { groupsEnabled && repository.clusteringEnabled }
    var trackingEnabled: Bool { groupsEnabled && repository.trackingEnabled }

    private let repository: FacesRepository
    private let scheduler: ImmediateSchedulerType
    private let stateSubject = BehaviorSubject(value: State())
    private let errorSubject = PublishSubject<Error>()
    private let loading = SerialDisposable()
    private let disposeBag = DisposeBag()
    private var isMutating = false

    init(repository: FacesRepository, scheduler: ImmediateSchedulerType = MainScheduler.instance) {
        self.repository = repository
        self.scheduler = scheduler
        loading.disposed(by: disposeBag)
        Observable.merge(repository.optionsUpdated.map { _ -> AnyObject? in nil }, repository.changes)
            .filter { [weak self] sender in sender !== self }
            .observe(on: scheduler)
            .subscribe(with: self) { owner, _ in owner.refresh() }
            .disposed(by: disposeBag)
    }

    func refresh() {
        guard !isMutating else { return }
        loading.disposable = Disposables.create()
        update { $0.isLoading = true }
        let groups = groupsEnabled ? repository.groups() : .just([])
        loading.disposable = Single.zip(repository.faces(), groups)
            .observe(on: scheduler)
            .subscribe(
                with: self,
                onSuccess: { owner, result in
                    owner.update {
                        $0.faces = result.0
                        $0.groups = result.1
                        $0.filter = owner.groupsEnabled ? $0.filter.resolved(in: result.1) : .all
                        $0.hasLoaded = true
                        $0.isLoading = false
                    }
                },
                onFailure: { owner, error in
                    owner.update { $0.isLoading = false }
                    owner.errorSubject.onNext(error)
                }
            )
    }

    func select(_ filter: FaceGroupFilter) {
        guard !currentState.isLoading else { return }
        update { $0.filter = groupsEnabled ? filter.resolved(in: $0.groups) : .all }
    }

    func createGroup(name: String, isTracked: Bool = false) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        mutate {
            self.repository.createGroup(name: name)
                .do(onSuccess: { [weak self] groupId in self?.update { $0.filter = .group(groupId) } })
                .flatMap { [repository, trackingEnabled] groupId -> Single<Void> in
                    guard trackingEnabled, isTracked else { return .just(()) }
                    return repository.toggleTracking(.init(groupId: groupId, groupName: name))
                }
        }
    }

    func renameGroup(_ group: APIFaceGroup, name: String) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != group.groupName else { return }
        mutate { self.repository.renameGroup(group, name: name) }
    }

    func editGroup(_ group: APIFaceGroup, name: String, isTracked: Bool) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        mutate {
            let rename: Single<Void> = name == group.groupName
                ? .just(()) : self.repository.renameGroup(group, name: name)
            return rename.flatMap { [repository, trackingEnabled] in
                guard trackingEnabled, isTracked != (group.watcherId != nil) else { return .just(()) }
                return repository.toggleTracking(group)
            }
        }
    }

    func deleteGroup(_ group: APIFaceGroup) {
        mutate { self.repository.deleteGroup(group) }
    }

    func moveFace(_ face: APIFace, to group: APIFaceGroup) {
        guard face.groupId != group.groupId else { return }
        // The server replaces membership atomically; do not detach first.
        mutate { self.repository.moveFace(face, to: group) }
    }

    func detachFace(_ face: APIFace) {
        guard face.groupId != nil else { return }
        mutate { self.repository.detachFace(face) }
    }

    func deleteFace(_ face: APIFace) {
        mutate(requiresGroups: false) { self.repository.deleteFace(face) }
    }

    func cluster(prefix: String) {
        let prefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clusteringEnabled, !prefix.isEmpty, currentState.filter == .ungrouped,
              !currentState.visibleFaces.isEmpty else { return }
        mutate { self.repository.cluster(prefix: prefix) }
    }

    func toggleTracking(_ group: APIFaceGroup) {
        guard trackingEnabled else { return }
        mutate { self.repository.toggleTracking(group) }
    }

    private func mutate(requiresGroups: Bool = true, _ request: () -> Single<Void>) {
        guard !requiresGroups || groupsEnabled, currentState.hasLoaded, !currentState.isLoading else { return }
        isMutating = true
        update { $0.isLoading = true }
        request().observe(on: scheduler)
            .subscribe(
                with: self,
                onSuccess: { owner, _ in owner.finishMutation() },
                onFailure: { owner, error in
                    owner.finishMutation()
                    owner.errorSubject.onNext(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func finishMutation() {
        // Changes carry their sender so our own notification cannot schedule a second refresh.
        repository.didMutate(sender: self)
        isMutating = false
        // A failed request can still have reached the server. Always reconcile.
        refresh()
    }

    private func update(_ change: (inout State) -> Void) {
        change(&currentState)
        stateSubject.onNext(currentState)
    }
}
