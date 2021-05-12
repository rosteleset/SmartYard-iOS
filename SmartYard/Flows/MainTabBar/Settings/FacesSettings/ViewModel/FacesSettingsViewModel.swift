//
//  AdvancedSettingsViewModel.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
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
    
    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        alertService: AlertService,
        router: WeakRouter<SettingsRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        self.alertService = alertService
        self.router = router
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
        
        let registeredFaces = apiWrapper
            .getPersonFaces()
            .trackError(errorTracker)
            .trackActivity(initialLoadingTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            
            
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
                    print("AddFace pressed!!!")
                }
            )
            .disposed(by: disposeBag)
        
        input.deleteFaceTrigger
            .drive(
                onNext: { [weak self] faceId in
                    print("Delete faceId=\(faceId) pressed!!!")
                }
            )
            .disposed(by: disposeBag)
        
        input.selectFaceTrigger
            .drive(
                onNext: { [weak self] faceId in
                    print("Select faceId=\(faceId) pressed!!!")
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            shouldShowInitialLoading: initialLoadingTracker.asDriver(),
            registeredFaces: registeredFaces
        )
    }
    
}

extension FacesSettingsViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let addFaceTrigger: Driver<Void>
        let deleteFaceTrigger: Driver<Int>
        let selectFaceTrigger: Driver<Int>
        
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let shouldShowInitialLoading: Driver<Bool>
        let registeredFaces: Driver<[APIFace]>
    }
    
}
