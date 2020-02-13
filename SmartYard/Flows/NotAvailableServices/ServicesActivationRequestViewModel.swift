//
//  ServicesActivationRequestViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import XCoordinator
import RxCocoa
import RxSwift

class ServicesActivationRequestViewModel: BaseViewModel {
    
    private let router: WeakRouter<AppRoute>
    
    private let serviceItemsSubject = BehaviorSubject<[ServiceModel]>(value: [])
    
    init(router: WeakRouter<AppRoute>) {
        self.router = router
    }
    
    func transform(input: Input) -> Output {
        input.viewWillAppearTrigger
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
                    self.serviceItemsSubject.onNext(self.getServiceModels())
                }
            )
            .disposed(by: disposeBag)
        
        input.sendRequestTapped
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
    
    private func getServiceModels() -> [ServiceModel] {
        return [
            ServiceModel(id: "0", name: "Умный домофон", description: "", state: .uncheckedActive),
            ServiceModel(id: "1", name: "Видеонаблюдение", description: "", state: .uncheckedActive),
            ServiceModel(id: "2", name: "Интернет и ТВ", description: "", state: .uncheckedActive),
            ServiceModel(id: "3", name: "Телефония", description: "", state: .uncheckedActive)
        ]
    }
    
}

extension ServicesActivationRequestViewModel {
    
    struct Input {
        let sendRequestTapped: Driver<Void>
        let serviceStateChanged: Driver<Int?>
        let viewWillAppearTrigger: Driver<Bool>
    }
    
    struct Output {
        let serviceItems: Driver<[ServiceModel]>
    }
    
}
