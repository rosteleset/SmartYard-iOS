//
//  FacesSettingsViewModel.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit
import XCoordinator

final class FacesSettingsViewModel: BaseViewModel {
    
    let faceGroups: FaceGroupsStore
    private let router: WeakRouter<SettingsRoute>
    private let flatId: Int
    private let address: String
    private let canAddFace: Bool
    
    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        router: WeakRouter<SettingsRoute>,
        flatId: Int,
        address: String,
        canAddFace: Bool,
        repository: FacesRepository? = nil
    ) {
        faceGroups = FaceGroupsStore(
            repository: repository ?? ServerFacesRepository(api: apiWrapper, access: accessService, flatId: flatId)
        )
        self.router = router
        self.flatId = flatId
        self.address = address
        self.canAddFace = canAddFace
    }

    func showRegistrationHelp() {
        guard canAddFace else { return }
        router.trigger(.showModal(withContent: .aboutFaceRegistration))
    }
    
    func transform(_ input: Input) -> Output {
        // MARK: Переход назад
        
        input.backTrigger
            .drive(with: self) { owner, _ in owner.router.trigger(.back) }
            .disposed(by: disposeBag)
        
        input.addFaceTrigger
            .drive(with: self) { owner, _ in
                guard owner.canAddFace else {
                    return
                }

                owner.router.trigger(
                    .addFace(
                        flatId: owner.flatId,
                        address: owner.address
                    )
                )
            }
            .disposed(by: disposeBag)
        
        input.deleteFaceTrigger
            .drive(with: self) { owner, value in
                owner.router.trigger(.deleteFace(image: value.1, flatId: owner.flatId, faceId: value.0))
            }
            .disposed(by: disposeBag)
        
        input.selectFaceTrigger
            .drive(with: self) { owner, value in owner.router.trigger(.showFace(image: value.1)) }
            .disposed(by: disposeBag)
        
        return Output(canAddFace: .just(canAddFace))
    }
    
}

extension FacesSettingsViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let addFaceTrigger: Driver<Void>
        let deleteFaceTrigger: Driver<(Int, UIImage?)>
        let selectFaceTrigger: Driver<(Int, UIImage?)>
        
    }
    
    struct Output {
        let canAddFace: Driver<Bool>
    }
    
}
