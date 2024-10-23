//
//  CamerasListViewModel.swift
//  SmartYard
//
//  Created by Александр Васильев on 19.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import XCoordinator
import RxSwift
import RxCocoa
import UIKit

final class CamerasListViewModel: BaseViewModel {
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<HomeRoute>
    private let items: BehaviorSubject<[CamerasListItem]>
    private let houseId: String
    private let address: String
    private let path: [Int]
    private var tree: CamerasTree
    
    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        router: WeakRouter<HomeRoute>,
        houseId: String,
        address: String,
        tree: CamerasTree,
        path: [Int] = []
    ) {
        self.apiWrapper = apiWrapper
        self.router = router
        self.houseId = houseId
        self.address = address
        self.tree = tree
        self.items = BehaviorSubject<[CamerasListItem]>(
            value: CamerasListViewModel.convertList(from: tree, using: path)
        )
        self.path = path
    }
    
    fileprivate static func convertAPIToCameraObject (source: [APICCTV]?) -> [CameraObject] {
        let cameras = (source ?? []).enumerated().map { offset, element -> CameraObject in
            CameraObject(
                id: element.id,
                position: element.coordinate,
                cameraNumber: offset + 1,
                name: element.name,
                video: element.video,
                token: element.token,
                serverType: element.serverType,
                hlsMode: element.hlsMode,
                hasSound: element.hasSound
            )
        }
        return cameras
    }
    
    static func convertList(from source: CamerasTree, using path: [Int] = []) -> [CamerasListItem] {
        
        guard let source = loadTree(by: path, from: source) else { return [] }
        
        let caption = source.groupName.isNilOrEmpty ? [] : [ CamerasListItem.caption(label: source.groupName!) ]
        let groups = (source.childGroups ?? []).map { child -> CamerasListItem in
            if child.type == .list {
                return CamerasListItem.group(
                    label: child.groupName ?? "",
                    id: child.groupId ?? 0,
                    tree: child.childGroups ?? []
                )
            } else {
                return CamerasListItem.mapView(
                    label: child.groupName ?? "",
                    id: child.groupId ?? 0,
                    cameras: convertAPIToCameraObject(source: child.cameras)
                )
            }
        }
        
        let cameras = convertAPIToCameraObject(source: source.cameras).map { CamerasListItem.camera(camera: $0) }
        return caption + groups + cameras
    }
    
    static func loadTree(by path: [Int], from tree: CamerasTree) -> CamerasTree? {
        var currentTree = tree
        var success = true
        path.forEach { groupId in
            guard let nextLevel = currentTree.childGroups?.first(where: { child in child.groupId == groupId }) else {
                success = false
                return
            }
            currentTree = nextLevel
        }
        return success ? currentTree : nil
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        let activityTracker = ActivityTracker()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(
                        title: NSLocalizedString("Error", comment: ""),
                        message: error.localizedDescription
                    ))
                }
            )
            .disposed(by: disposeBag)
        
        let hasNetworkBecomeReachable = apiWrapper.isReachableObservable
            .asDriver(onErrorJustReturn: false)
            .distinctUntilChanged()
            .skip(1)
            .isTrue()
            .mapToVoid()
        
        // MARK: Запрос на обновление, который должен скрывать все происходящее за скелетоном
        let interactionBlockingRequestTracker = ActivityTracker()
        
        let blockingRefresh = hasNetworkBecomeReachable
            .flatMapLatest { [weak self] _ -> Driver<AllCCTVTreeResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.getAllTreeCCTV(houseId: self.houseId, forceRefresh: true)
                    // .trackError(errorTracker)
                    .trackActivity(interactionBlockingRequestTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
        
        blockingRefresh
            .asDriver()
            .drive(
                onNext: {  [weak self] response in
                    guard let self = self,
                          let response = response else {
                        return
                    }
                    self.tree = response
                    self.items.onNext(CamerasListViewModel.convertList(from: response, using: self.path))
                }
            )
            .disposed(by: disposeBag)

        input.itemSelected
            .withLatestFrom(items.asDriver(onErrorJustReturn: [CamerasListItem]())) { ($0, $1) }
            .drive(
                // swiftlint:disable:next closure_body_length
                onNext: { [weak self] args in
                    guard let self = self else {
                        return
                    }
                    
                    let (indexPath, items) = args
                    let item = items[indexPath.row]
                    
                    switch item {
                    case .caption:
                        break
                        
                    case .group(label: _, id: let id, tree: _):
                        let selectedPath = self.path + [ id ]
                        self.router.trigger(
                            .yardCamerasList(
                                houseId: self.houseId,
                                address: self.address,
                                tree: self.tree,
                                path: selectedPath
                            )
                        )
                        
                    case .camera(camera: let camera):
                        let currentTree = CamerasListViewModel.loadTree(by: self.path, from: self.tree)
                        let cameras = CamerasListViewModel.convertAPIToCameraObject(source: currentTree?.cameras ?? [])
                        
                        self.router.trigger(
                            .cameraContainer(
                                address: self.address,
                                cameras: cameras,
                                selectedCamera: camera
                            )
                        )
                    case .mapView(let label, _, let cameras):
                        self.router.trigger(
                            .yardCamerasMap(
                                houseId: self.houseId,
                                address: label,
                                cameras: cameras
                            )
                        )
                    }
                }
            )
            .disposed(by: disposeBag)
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            items: items.asDriverOnErrorJustComplete(),
            shouldBlockInteraction: interactionBlockingRequestTracker.asDriver(),
            isLoading: activityTracker.asDriver(),
            address: .just(self.address).asDriver()
        )
    }
    
}
extension CamerasListViewModel {
    
    struct Input {
        let itemSelected: Driver<IndexPath>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let items: Driver<[CamerasListItem]>
        let shouldBlockInteraction: Driver<Bool>
        let isLoading: Driver<Bool>
        let address: Driver<String?>
    }
    
}
