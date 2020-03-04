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
    
    private let router: WeakRouter<HomeRoute>
    
    private let apiWrapper: APIWrapper
    
    private let serviceItemsSubject = BehaviorSubject<[ServiceModel]>(value: [])

    init(router: WeakRouter<HomeRoute>, apiWrapper: APIWrapper) {
        self.router = router
        self.apiWrapper = apiWrapper
    }
    
    func transform(input: Input) -> Output {
        input.viewWillAppearTrigger
            .drive(
                onNext: { [weak self] _ in
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
                onNext: { [weak self] index in
                    guard let self = self,
                          let index = index,
                          var data = try? self.serviceItemsSubject.value()
                    else {
                        return
                    }
                    
                    data[index].toogleState()
                    
                    self.serviceItemsSubject.onNext(data)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(serviceItems: serviceItemsSubject.asDriver(onErrorJustReturn: []))
    }
    
    private func getFakeModels() -> [ServiceModel] {
        return [
            // swiftlint:disable:next line_length
            ServiceModel(id: "0", name: "Умный домофон", description: "На шлагбаум, ворота и подъезд", state: .checkedInactive),
            ServiceModel(id: "1", name: "Видеонаблюдение", description: "3 камеры", state: .checkedInactive),
            ServiceModel(id: "2", name: "Интернет и ТВ", description: "Более 250 каналов", state: .uncheckedActive),
            ServiceModel(id: "3", name: "Умный дом", description: "Дом умнее тебя", state: .uncheckedActive),
            // swiftlint:disable:next line_length
            ServiceModel(id: "4", name: "Тревожная кнопка", description: "Не верь, не бойся, не проси", state: .uncheckedActive),
            // swiftlint:disable:next line_length
            ServiceModel(id: "5", name: "Аренда оборудования", description: "Wi-Fi роутер, приставка для TV", state: .uncheckedActive),
            ServiceModel(id: "6", name: "FakeFakeFake", description: "Fake", state: .uncheckedActive)
        ]
    }
    
}

extension AvailableSericesViewModel {
    
    struct Input {
        let nextTapped: Driver<Void>
        let serviceStateChanged: Driver<Int?>
        let viewWillAppearTrigger: Driver<Bool>
    }
    
    struct Output {
        let serviceItems: Driver<[ServiceModel]>
    }
    
}
