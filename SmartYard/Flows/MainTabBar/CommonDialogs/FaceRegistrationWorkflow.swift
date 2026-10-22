//
//  FaceRegistrationWorkflow.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation
import RxSwift

/// Keeps confirmed steps across retries. A face registration cannot be rolled back locally.
final class FaceRegistrationWorkflow {
    enum Selection: Equatable {
        case ungrouped
        case existing(APIFaceGroup)
        case new(String)
    }

    enum Failure: Error, Equatable {
        case missingFaceIdentifier
        case groupsUnavailable
        case invalidGroup
        case invalidGroupName
        case operationInProgress
    }

    struct Dependencies {
        let register: () -> Single<Int?>
        let createGroup: (String) -> Single<APIFaceGroup>
        let attach: (Int, Int) -> Single<Void>
        let detach: (Int, Int) -> Single<Void>
        let faces: () -> Single<[APIFace]>
    }

    private(set) var isRegistered = false
    private(set) var faceId: Int?
    private var createdGroups: [String: APIFaceGroup] = [:]
    private var didAttemptAssignment = false
    private let dependencies: Dependencies
    private let groupsEnabled: () -> Bool
    private let scheduler: ImmediateSchedulerType
    private var activeOperation: UUID?

    init(
        dependencies: Dependencies,
        groupsEnabled: @escaping () -> Bool = { true },
        scheduler: ImmediateSchedulerType = MainScheduler.instance
    ) {
        self.dependencies = dependencies
        self.groupsEnabled = groupsEnabled
        self.scheduler = scheduler
    }

    func createdGroup(named name: String) -> APIFaceGroup? { createdGroups[name] }

    func save(selection: Selection, onRegistered: @escaping () -> Void) -> Single<APIFaceGroup?> {
        Single.deferred { [self] in
            guard activeOperation == nil else { return .error(Failure.operationInProgress) }
            guard selection == .ungrouped || groupsEnabled() else { return .error(Failure.groupsUnavailable) }
            let normalized: Selection
            switch selection {
            case .new(let name):
                let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return .error(Failure.invalidGroupName) }
                normalized = .new(name)
            case .existing(let group):
                guard group.groupId > 0 else { return .error(Failure.invalidGroup) }
                normalized = selection
            case .ungrouped:
                normalized = selection
            }
            return performSave(selection: normalized, onRegistered: onRegistered)
        }
        .subscribe(on: scheduler)
    }

    private func performSave(selection: Selection, onRegistered: @escaping () -> Void) -> Single<APIFaceGroup?> {
        let operation = UUID()
        activeOperation = operation
        let register: Single<Void> =
            isRegistered
            ? .just(())
            : dependencies.register()
                .observe(on: scheduler)
                .do(onSuccess: { [weak self] faceId in
                    self?.isRegistered = true
                    self?.faceId = faceId
                    onRegistered()
                })
                .map { _ in () }
        return register.flatMap { [self] _ in assign(selection) }
            .observe(on: scheduler)
            .do(
                onSuccess: { [weak self] _ in self?.finish(operation) },
                onError: { [weak self] _ in self?.finish(operation) },
                onDispose: { [weak self] in self?.finish(operation) }
            )
    }

    private func finish(_ operation: UUID) {
        if activeOperation == operation { activeOperation = nil }
    }

    private func assign(_ selection: Selection) -> Single<APIFaceGroup?> {
        if selection == .ungrouped { return leaveUngrouped() }
        guard let faceId else { return .error(Failure.missingFaceIdentifier) }

        let group: Single<APIFaceGroup>
        switch selection {
        case .ungrouped:
            return .just(nil)
        case .existing(let selected):
            group = .just(selected)
        case .new(let name):
            if let created = createdGroups[name] {
                group = .just(created)
            } else {
                group = dependencies.createGroup(name)
                    .observe(on: scheduler)
                    .do(onSuccess: { [weak self] group in self?.createdGroups[name] = group })
            }
        }
        return group.flatMap { [self] group in
            didAttemptAssignment = true
            return dependencies.attach(faceId, group.groupId).map { group }
        }
    }

    private func leaveUngrouped() -> Single<APIFaceGroup?> {
        guard didAttemptAssignment, let faceId else { return .just(nil) }
        // A timed-out attach may have succeeded. Read back before honouring "Ungrouped".
        return dependencies.faces()
            .flatMap { [dependencies] faces -> Single<APIFaceGroup?> in
                guard let groupId = faces.first(where: { $0.faceId == faceId })?.groupId else {
                    return .just(nil)
                }
                return dependencies.detach(faceId, groupId).map { nil }
            }
    }
}
