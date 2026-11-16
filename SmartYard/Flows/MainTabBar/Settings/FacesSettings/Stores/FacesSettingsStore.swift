//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Observation
import RxCocoa
import RxRelay
import RxSwift
import UIKit

@MainActor
@Observable
final class FacesSettingsStore {
    struct LoadError: Equatable {
        let id = UUID()
        let message: String
    }

    private(set) var state = FaceGroupsStore.State()
    private(set) var canAddFace = false
    private(set) var groupsEnabled = false
    private(set) var clusteringEnabled = false
    private(set) var trackingEnabled = false
    private(set) var loadError: LoadError?

    var faces: [APIFace] { state.faces }
    var visibleFaces: [APIFace] { state.visibleFaces }
    var hasReceivedFaces: Bool { state.hasLoaded }
    var isLoading: Bool { state.isLoading }
    var canCluster: Bool { clusteringEnabled && state.filter == .ungrouped && !visibleFaces.isEmpty && !isLoading }
    var selectedGroup: APIFaceGroup? { state.selectedGroup }
    var filterTitle: String {
        switch state.filter {
        case .all: return L10n.Settings.Faces.Groups.all
        case .ungrouped: return L10n.Settings.Faces.Groups.ungrouped
        case .group: return selectedGroup?.groupName ?? L10n.Settings.Faces.Groups.all
        }
    }
    private(set) var images: [Int: UIImage] = [:]
    private(set) var loadingImages: Set<Int> = []

    @ObservationIgnored private let viewModel: FacesSettingsViewModel
    @ObservationIgnored private let back = PublishRelay<Void>()
    @ObservationIgnored private let add = PublishRelay<Void>()
    @ObservationIgnored private let delete = PublishRelay<(Int, UIImage?)>()
    @ObservationIgnored private let select = PublishRelay<(Int, UIImage?)>()
    @ObservationIgnored private let disposeBag = DisposeBag()
    @ObservationIgnored private var imageURLs: [Int: String] = [:]
    @ObservationIgnored private var hasStarted = false

    init(viewModel: FacesSettingsViewModel) {
        self.viewModel = viewModel
        state = viewModel.faceGroups.currentState
        groupsEnabled = viewModel.faceGroups.groupsEnabled
        clusteringEnabled = viewModel.faceGroups.clusteringEnabled
        trackingEnabled = viewModel.faceGroups.trackingEnabled
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        let output = viewModel.transform(.init(
            backTrigger: back.asDriverOnErrorJustComplete(),
            addFaceTrigger: add.asDriverOnErrorJustComplete(),
            deleteFaceTrigger: delete.asDriverOnErrorJustComplete(),
            selectFaceTrigger: select.asDriverOnErrorJustComplete()
        ))
        viewModel.faceGroups.state
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, state in
                MainActor.assumeIsolated {
                    owner.updateFaces(state.faces)
                    owner.state = state
                    owner.groupsEnabled = owner.viewModel.faceGroups.groupsEnabled
                    owner.clusteringEnabled = owner.viewModel.faceGroups.clusteringEnabled
                    owner.trackingEnabled = owner.viewModel.faceGroups.trackingEnabled
                }
            }
            .disposed(by: disposeBag)
        viewModel.faceGroups.errors
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, error in
                MainActor.assumeIsolated { owner.loadError = LoadError(message: error.localizedDescription) }
            }
            .disposed(by: disposeBag)
        output.canAddFace
            .distinctUntilChanged()
            .drive(with: self) { owner, value in MainActor.assumeIsolated { owner.canAddFace = value } }
            .disposed(by: disposeBag)
        refresh()
    }

    func refresh() { viewModel.faceGroups.refresh() }
    func dismissLoadError() { loadError = nil }
    func selectGroup(_ filter: FaceGroupFilter) { viewModel.faceGroups.select(filter) }
    func createGroup(name: String, isTracked: Bool) { viewModel.faceGroups.createGroup(name: name, isTracked: isTracked) }
    func editGroup(_ group: APIFaceGroup, name: String, isTracked: Bool) {
        viewModel.faceGroups.editGroup(group, name: name, isTracked: isTracked)
    }
    func setTracking(_ isTracked: Bool, for groupId: Int) {
        viewModel.faceGroups.setTracking(isTracked, for: groupId)
    }
    func deleteGroup(_ group: APIFaceGroup) { viewModel.faceGroups.deleteGroup(group) }
    func moveFace(_ face: APIFace, to group: APIFaceGroup) { viewModel.faceGroups.moveFace(face, to: group) }
    func detachFace(_ face: APIFace) { viewModel.faceGroups.detachFace(face) }
    func cluster(prefix: String) { viewModel.faceGroups.cluster(prefix: prefix) }

    func goBack() { back.accept(()) }
    func addFace() { add.accept(()) }
    func showRegistrationHelp() { viewModel.showRegistrationHelp() }
    func selectFace(_ face: APIFace) { select.accept((face.faceId, images[face.faceId])) }
    func deleteFace(_ face: APIFace) { delete.accept((face.faceId, images[face.faceId])) }

    /// A cell task owns each request; removing a cell cancels it. No UIKit control is wrapped.
    func loadImage(for face: APIFace) async {
        guard imageURLs[face.faceId] == face.image else { return }
        if images[face.faceId] != nil { return }
        if let cached = imagesCache.object(forKey: face.image as NSString) {
            images[face.faceId] = cached
            return
        }
        guard let url = URL(string: face.image) else { return }
        loadingImages.insert(face.faceId)
        defer {
            if imageURLs[face.faceId] == face.image { loadingImages.remove(face.faceId) }
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled,
                  imageURLs[face.faceId] == face.image,
                  let response = response as? HTTPURLResponse,
                  response.statusCode == 200,
                  response.mimeType?.hasPrefix("image") == true,
                  let image = UIImage(data: data) else { return }
            imagesCache.setObject(image, forKey: face.image as NSString)
            images[face.faceId] = image
        } catch {
            // The old thumbnail leaves its background visible after a failed image request.
        }
    }

    private func updateFaces(_ newFaces: [APIFace]) {
        let remainingIDs = Set(newFaces.map(\.faceId))
        images = images.filter { remainingIDs.contains($0.key) }
        loadingImages.formIntersection(remainingIDs)
        for face in newFaces where imageURLs[face.faceId] != face.image {
            images.removeValue(forKey: face.faceId)
            loadingImages.remove(face.faceId)
        }
        imageURLs = newFaces.reduce(into: [:]) { $0[$1.faceId] = $1.image }
    }
}
