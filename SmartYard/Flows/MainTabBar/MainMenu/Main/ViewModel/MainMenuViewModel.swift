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
            MenuItemsList(label: "Настройки профиля", iconName: "ProfileMenuIcon", triger: "profile"),
            MenuItemsList(label: "Общие настройки", iconName: "SettingsMenuIcon", triger: "settings")
        ]
    )
    
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
                    print(indexPath.row)
                    switch items[indexPath.row].triger  {
                        case "settings": self?.router.trigger(.settings); break;
                        case "profile": self?.router.trigger(.profile); break;
                        case "publicCams": self?.router.trigger(.safariPage(url: URL(string: "https://cam.lanta.me")!)); break;
                        
                        default: self?.router.trigger(.settings)
                    }
                    //self?.router.trigger(.settings)
                    
                    
                    /*
                     value: [
                         MenuItemsList(label: "Городские камеры", iconName: "PublicCamsMenuIcon", triger: .safariPage(url: URL(string: "https://cam.lanta.me")!)),
                         MenuItemsList(label: "Настройки профиля", iconName: "ProfileMenuIcon", triger: .settings),
                         MenuItemsList(label: "Общие настройки", iconName: "SettingsMenuIcon", triger: .profile)
                     ]
                     */
                    
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
