//
//  UserNameViewModel.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class UserNameViewModel: BaseViewModel {
    
    let router: WeakRouter<AppRoute>
    
    init(router: WeakRouter<AppRoute>) {
        self.router = router
    }
    
    func transform(input: Input) -> Output {
        let isAbleToContinue = input.name
            .map { !$0.isNilOrEmpty }
        
        input.continueTrigger
            .withLatestFrom(input.name)
            .withLatestFrom(input.middleName) { ($0, $1) }
            .flatMap { name, middleName -> Driver<(String, String?)> in
                guard let unwrappedName = name else {
                    return .empty()
                }
                
                return .just((unwrappedName, middleName))
            }
            .drive(
                onNext: { _ in
                    // TODO: Добавить переход
                }
            )
            .disposed(by: disposeBag)
        
        return Output(isAbleToContinue: isAbleToContinue)
    }
    
}

extension UserNameViewModel {
    
    struct Input {
        let name: Driver<String?>
        let middleName: Driver<String?>
        let continueTrigger: Driver<Void>
    }
    
    struct Output {
        let isAbleToContinue: Driver<Bool>
    }
    
}
