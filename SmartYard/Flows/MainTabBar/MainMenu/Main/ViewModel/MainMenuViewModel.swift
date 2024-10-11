//
//  MainMenuViewModel.swift
//  SmartYard
//
//  Created by Александр Васильев on 06.01.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length closure_body_length

import XCoordinator
import RxSwift
import RxCocoa
import UIKit

class MainMenuViewModel: BaseViewModel {
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<MainMenuRoute>
    
    private let defaultItems = [
//        MenuListItem.essential(label: "Городские камеры", iconName: "PublicCamsMenuIcon", route: .cityCams, order: 100),
        MenuListItem.essential(label: "Настройки адресов", iconName: "HomeIcon", route: .settings, order: 200),
        MenuListItem.essential(label: "Общие настройки", iconName: "SettingsMenuIcon", route: .profile, order: 300)
    ]
    
    private let items: BehaviorSubject<[MenuListItem]>
    private let bottomItemTrigger = MainMenuRoute.callSupport
    
    init(
        apiWrapper: APIWrapper,
        router: WeakRouter<MainMenuRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.router = router
        self.items = BehaviorSubject<[MenuListItem]>(value: defaultItems)
    }
    
    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        let activityTracker = ActivityTracker()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
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
        
        let blockingRefresh = Driver
            .merge(
                hasNetworkBecomeReachable,
                .just(())
            )
            .flatMapLatest { [weak self] _ -> Driver<GetExtensionsListResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.getExtensionsList()
                    .trackError(errorTracker)
                    .trackActivity(interactionBlockingRequestTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
        
        blockingRefresh
            .asDriver()
            .drive { [weak self] extensions in
                guard let self = self,
                      let extensions = extensions else {
                    return
                }
                
                let optionalItems = extensions.map { ext -> MenuListItem in
                    return MenuListItem.optional(
                        label: ext.caption,
                        icon: ext.icon,
                        extId: ext.extId,
                        order: ext.order
                    )
                }
                
                let compiledItems = (self.defaultItems + optionalItems).sorted { $0.order < $1.order }
                
                // TODO: Удалить городские камеры при их отсутствии
                
//                let filteredItems = compiledItems.filter {
//                    var itemShow = true
//                    var camCount = 0
//                    let activityTracker = ActivityTracker()
//                    let isCityCams = ($0.label == "Городские камеры")
//                    if isCityCams {
//                        print(camCount)
//
//                        self.apiWrapper.getOverviewCCTV()
//                            .trackActivity(activityTracker)
//                            .asDriver(onErrorJustReturn: nil)
//                            .ignoreNil()
//                            .map {_ in
//                                camCount += 1
//                            }
//                            .drive(
//                                onNext: {}
//                            )
//                            .dispose()
//
//                        itemShow = !(camCount == 0)
//                    }
//                    return itemShow
//                }
                
                self.items.onNext(compiledItems)
//                self.items.onNext(filteredItems)
            }
            .disposed(by: disposeBag)

        input.itemSelected
            .withLatestFrom(items.asDriver(onErrorJustReturn: [MenuListItem]())) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    guard let self = self else {
                        return
                    }
                    
                    let (indexPath, items) = args
                    let item = items[indexPath.row]
                    
                    switch item {
                    case .essential(label: _, iconName: _, route: let route, order: _):
                        self.router.trigger(route)
                    case .optional(label: _, icon: _, extId: let extId, order: _):
                        self.apiWrapper.getExtension(extId: extId)
                            .trackError(errorTracker)
                            .trackActivity(interactionBlockingRequestTracker)
                            .asDriverOnErrorJustComplete()
                            .drive(
                                onNext: { [weak self] ext in
                                    guard let self = self else {
                                        return
                                    }
                                    self.router.trigger(
                                        .webViewFromContent(content: ext.contentHTML, baseURL: ext.basePath)
                                    )
                                }
                            )
                            .disposed(by: self.disposeBag)
                    }
                    
                }
            )
            .disposed(by: disposeBag)
        
        input.bottomButton
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.router.trigger(self.bottomItemTrigger)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            items: items.asDriverOnErrorJustComplete(),
            shouldBlockInteraction: interactionBlockingRequestTracker.asDriver(),
            isLoading: activityTracker.asDriver()
        )
    }
    
}
extension MainMenuViewModel {
    
    struct Input {
        let itemSelected: Driver<IndexPath>
        let bottomButton: Driver<Void>
    }
    
    struct Output {
        let items: Driver<[MenuListItem]>
        let shouldBlockInteraction: Driver<Bool>
        let isLoading: Driver<Bool>
        
    }
    
}
// swiftlint:enable function_body_length closure_body_length
