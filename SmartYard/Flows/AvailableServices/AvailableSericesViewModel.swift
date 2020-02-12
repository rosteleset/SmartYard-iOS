//
//  AvailableSericesViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

class AvailableSericesViewModel: BaseViewModel {
    
    private let router: WeakRouter<AppRoute>
    
    private let serviceItemsSubject = BehaviorSubject<[ServiceModel]>(value: [])
    
    private let
    init(router: WeakRouter<AppRoute>) {
        self.router = router
    }
    
    func transform(input: Input) -> Output {
        input.viewWillAppearTrigger
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.serviceItemsSubject.onNext(self.getFakeModels())
                }
            )
            .disposed(by: disposeBag)
        
        input.nextTapped
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        input.serviceStateChanged
            .drive(
                onNext: { [weak self] args in
                    
                }
            )
            .disposed(by: disposeBag)
        
        return Output(serviceItems: serviceItemsSubject.asDriver(onErrorJustReturn: []))
    }
    
    private func getFakeModels() -> [ServiceModel] {
        return [
            ServiceModel(id: "0", name: "Умный домофон", description: "На шлагбаум, ворота и подъезд", state: .checkedInactive),
            ServiceModel(id: "1", name: "Видеонаблюдение", description: "3 камеры", state: .checkedInactive),
            ServiceModel(id: "2", name: "Интернет и ТВ", description: "Более 250 каналов", state: .uncheckedActive),
            ServiceModel(id: "3", name: "Умный дом", description: "Дом умнее тебя", state: .uncheckedActive),
            ServiceModel(id: "4", name: "Тревожная кнопка", description: "Не верь, не бойся, не проси", state: .uncheckedActive)
        ]
    }
    
}

extension AvailableSericesViewModel {
    
    struct Input {
        let nextTapped: Driver<Void>
        let serviceStateChanged: Driver<(Int, ServiceState)>
        let viewWillAppearTrigger: Driver<Void>
    }
    
    struct Output {
        let serviceItems: Driver<[ServiceModel]>
    }
    
}
