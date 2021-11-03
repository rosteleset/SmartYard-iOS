//
//  AdvancedSettingsViewModel.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxCocoa
import RxSwift
import XCoordinator
import SmartYardSharedDataFramework

class FacesSettingsViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let alertService: AlertService
    private let router: WeakRouter<SettingsRoute>
    private let flatId: Int
    private let address: String
    
    private let registeredFaces = PublishSubject<[APIFace]>()
    
    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        alertService: AlertService,
        router: WeakRouter<SettingsRoute>,
        flatId: Int,
        address: String
    ) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        self.alertService = alertService
        self.router = router
        self.flatId = flatId
        self.address = address
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: ActivityTracker для изначальной загрузки с показом скелетонов
        
        let initialLoadingTracker = ActivityTracker()
        
        // MARK: Загрузка лиц
        
        apiWrapper.getPersonFaces(flatId: flatId)
            .trackError(errorTracker)
            .trackActivity(initialLoadingTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] faces in
                    self?.registeredFaces.onNext(faces)
                }
            )
            .disposed(by: disposeBag)
            
        // MARK: Переход назад
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        input.addFaceTrigger
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.router.trigger(.addFace(flatId: self.flatId, address: self.address))
                }
            )
            .disposed(by: disposeBag)
        
        input.deleteFaceTrigger
            .drive(
                onNext: { [weak self] faceId, image in
                    guard let self = self else {
                        return
                    }
                    self.router.trigger(.deleteFace(image: image, flatId: self.flatId, faceId: faceId))
                }
            )
            .disposed(by: disposeBag)
        
        input.selectFaceTrigger
            .drive(
                onNext: { [weak self] _, image in
                    self?.router.trigger(.showFace(image: image))
                }
            )
            .disposed(by: disposeBag)
        
        // это событие прилетает, когда пользователь удалил лицо и надо обновить список лиц
        NotificationCenter.default.rx.notification(.updateFaces)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            .delay(.milliseconds(500))
            .flatMapLatest { [weak self] _ -> Driver<GetPersonFacesResponseData> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.getPersonFaces(flatId: self.flatId, forceRefresh: true)
                    .trackError(errorTracker)
                    .trackActivity(initialLoadingTracker)
                    .asDriver(onErrorJustReturn: nil)
                    .ignoreNil()
            }
            .drive(
                onNext: { [weak self] faces in
                    self?.registeredFaces.onNext(faces)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            shouldShowInitialLoading: initialLoadingTracker.asDriver(),
            registeredFaces: self.registeredFaces.asDriver(onErrorJustReturn: [])
        )
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
        let isLoading: Driver<Bool>
        let shouldShowInitialLoading: Driver<Bool>
        let registeredFaces: Driver<[APIFace]>
    }
    
}
