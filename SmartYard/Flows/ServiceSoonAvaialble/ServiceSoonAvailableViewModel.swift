//
//  ServiceSoonAvailableViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class ServiceSoonAvailableViewModel: BaseViewModel {
    
    private let router: WeakRouter<AppRoute>
    private let requestType: ServiceRequestType
    private let address: String?
    
    init(router: WeakRouter<AppRoute>, requestType: ServiceRequestType, address: String? = nil) {
        self.router = router
        self.requestType = requestType
        self.address = address
    }
    
    func transform(input: Input) -> Output {
        let titleImageTrigger = PublishSubject<UIImage?>()
        let hintTextTrigger = PublishSubject<String?>()
        let actionTextTrigger = PublishSubject<String?>()
        let changeVisibilityQrCodeElementsTrigger = PublishSubject<Bool>()
        
        input.viewWillAppearTrigger
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
                    titleImageTrigger.onNext(self.requestType.image)
                    actionTextTrigger.onNext(self.requestType.actionText)
                    changeVisibilityQrCodeElementsTrigger.onNext(self.requestType == .officeRequest)
                    
                    guard self.requestType == .courierRequest else {
                        hintTextTrigger.onNext(self.requestType.hintText)
                        return
                    }
                    
                    let hintText = self.requestType.hintText.replacingOccurrences(
                        of: "{value}", with: (self.address ?? "")
                    )
                    
                    hintTextTrigger.onNext(hintText)
                }
            )
            .disposed(by: disposeBag)
                
        input.qrCodeTapped
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        input.actionTapped
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    switch self.requestType {
                    // TODO
                    case .officeRequest: break
                    case .courierRequest: break
                    }
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            titleImageTrigger: titleImageTrigger.asDriverOnErrorJustComplete(),
            hintTextTrigger: hintTextTrigger.asDriverOnErrorJustComplete(),
            actionTextTrigger: actionTextTrigger.asDriverOnErrorJustComplete(),
            changeVisibilityQrCodeElementsTrigger: changeVisibilityQrCodeElementsTrigger.asDriverOnErrorJustComplete()
        )
    }
    
}

extension ServiceSoonAvailableViewModel {
    
    struct Input {
        let qrCodeTapped: Driver<Void>
        let actionTapped: Driver<Void>
        let viewWillAppearTrigger: Driver<Bool>
    }
    
    struct Output {
        let titleImageTrigger: Driver<UIImage?>
        let hintTextTrigger: Driver<String?>
        let actionTextTrigger: Driver<String?>
        let changeVisibilityQrCodeElementsTrigger: Driver<Bool>
    }
    
}
