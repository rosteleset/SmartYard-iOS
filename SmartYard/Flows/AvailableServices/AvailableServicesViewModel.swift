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

class AvailableServicesViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    
    private let apiWrapper: APIWrapper
    
    private let serviceItemsSubject = BehaviorSubject<[ServiceModel]>(value: [])
    private let addressSubject = BehaviorSubject<String?>(value: nil)
    
    private let address: String
    private let services: [ServiceModel]
    
    init(router: WeakRouter<HomeRoute>, apiWrapper: APIWrapper, address: String, services: [APIServiceModel]) {
        self.router = router
        self.apiWrapper = apiWrapper
        self.address = address
        
        var serviceModels = [ServiceModel]()
        
        services.enumerated().forEach { offset, element in
            serviceModels.append(
                ServiceModel(
                    id: String(offset),
                    name: element.title,
                    description: element.description,
                    state: element.isAvailableByDefault ? .checkedInactive : .uncheckedActive
                )
            )
        }

        self.services = serviceModels.sorted(by: { $0.state < $1.state })
    }
    
    func transform(input: Input) -> Output {
        addressSubject.onNext(address)
        serviceItemsSubject.onNext(services)
        
        input.nextTapped
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.confirmAddress)
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
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            serviceItems: serviceItemsSubject.asDriver(onErrorJustReturn: []),
            addressSubject: addressSubject.asDriver(onErrorJustReturn: nil)
        )
    }
    
}

extension AvailableServicesViewModel {
    
    struct Input {
        let nextTapped: Driver<Void>
        let serviceStateChanged: Driver<Int?>
        let viewWillAppearTrigger: Driver<Bool>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let serviceItems: Driver<[ServiceModel]>
        let addressSubject: Driver<String?>
    }
    
}
