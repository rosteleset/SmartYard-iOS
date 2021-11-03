//
//  MainMenuViewModel.swift
//  SmartYard
//
//  Created by Александр Васильев on 06.01.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import XCoordinator
import RxSwift
import RxCocoa

struct MenuItemsList: Decodable {
    let label: String
    let iconName: String
    let triger: String
}

class MainMenuViewModel: BaseViewModel {
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<MainMenuRoute>
    
    private let items = BehaviorSubject<[MenuItemsList]>(
        value: [
            MenuItemsList(label: "Городские камеры", iconName: "PublicCamsMenuIcon", triger: "publicCams"),
            MenuItemsList(label: "Настройки адресов", iconName: "HomeIcon", triger: "settings"),
            MenuItemsList(label: "Общие настройки", iconName: "SettingsMenuIcon", triger: "profile")
        ]
    )
    private let bottomItemTrigger = MainMenuRoute.callSupport
    
    init(
        apiWrapper: APIWrapper,
        router: WeakRouter<MainMenuRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.router = router
    }
    
    func transform(_ input: Input) -> Output {
        
        input.itemSelected
            .withLatestFrom(items.asDriver(onErrorJustReturn: [MenuItemsList]())) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (indexPath, items) = args
                    
                    switch items[indexPath.row].triger {
                    case "settings": self?.router.trigger(.settings)
                    case "profile": self?.router.trigger(.profile)
                    case "publicCams": self?.router.trigger(.cityCams)
                    
                    default: self?.router.trigger(.settings)
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
            items: items.asDriverOnErrorJustComplete()
        )
    }
    
}
extension MainMenuViewModel {
    
    struct Input {
        let itemSelected: Driver<IndexPath>
        let bottomButton: Driver<Void>
        /*
        let backTrigger: Driver<Void>
        let downloadTrigger: Driver<Void>
        let periodSelectedTrigger: Driver<ArchiveVideoPreviewPeriod?>
        let startEndSelectedTrigger: Driver<(Date, Date)>
        let screenshotTrigger: Driver<Date>
        */
    }
    
    struct Output {
        let items: Driver<[MenuItemsList]>
        /*
        let date: Driver<Date?>
        let periodConfiguration: Driver<[ArchiveVideoPreviewPeriod]>
        let rangeBounds: Driver<(lower: Date, upper: Date)?>
        let videoData: Driver<([URL], VideoThumbnailConfiguration)?>
        let screenshotURL: Driver<URL?>
        let isLoading: Driver<Bool>
        */
    }
    
}
