//
//  PlayArchiveVideoViewModel.swift
//  SmartYard
//
//  Created by admin on 02.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import XCoordinator
import RxSwift
import RxCocoa

class PlayArchiveVideoViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    
    private let date: BehaviorSubject<Date?>
    
    init(date: Date, router: WeakRouter<HomeRoute>) {
        self.router = router
        
        self.date = BehaviorSubject<Date?>(value: date)
    }
    
    func transform(_ input: Input) -> Output {
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(date: date.asDriver(onErrorJustReturn: nil))
    }
    
}

extension PlayArchiveVideoViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let date: Driver<Date?>
    }
    
}
