//
//  PayTypeSelectViewModel.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 17.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator
import UIKit

class PayTypeSelectViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private var cards: [PayTypeObject]
    private var router: WeakRouter<HomePayRoute>
    private let merchant = BehaviorSubject<Merchant?>(value: nil)

    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()

    init(
        apiWrapper: APIWrapper,
        cards: [PayTypeObject],
        merchant: Merchant,
        router: WeakRouter<HomePayRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.cards = cards
        self.router = router
        self.merchant.onNext(merchant)
    }

    func transform(input: Input) -> Output {
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    let nsError = error as NSError

                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)

        let paytypes = BehaviorSubject<[PayTypeObject]>(value: cards)

        input.saveButtonTrigger
            .withLatestFrom(input.selectedNumberTrigger)
            .drive(
                onNext: { [weak self] number in
                    guard let number = number else {
                        return
                    }
                    NotificationCenter.default.post(name: .refreshPayCard, object: number)
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        input.deleteCardTrigger
            .withLatestFrom(merchant.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] card, merchant -> Driver<Int?> in
                guard let self = self, let card = card, let bindingId = card.bindingId, let merchant = merchant else {
                    return .empty()
                }
                return self.apiWrapper
                    .removeCard(merchant: merchant, bindingId: bindingId)
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .map { response in
                        return card.number
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .withLatestFrom(input.selectedNumberTrigger) { ($0, $1) }
            .drive(
                onNext: { [weak self] deletedNumber, selectedNumber in
                    NotificationCenter.default.post(name: .refreshPayCard, object: 0)
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            cards: paytypes.asDriver(onErrorJustReturn: [])
        )
    }
}
extension PayTypeSelectViewModel {
    
    struct Input {
        let selectedNumberTrigger: Driver<Int?>
        let deleteCardTrigger: Driver<PayTypeObject?>
        let saveButtonTrigger: Driver<Void>
    }
    
    struct Output {
        let cards: Driver<[PayTypeObject]>
//        let isAbleToProceedRequest: Driver<Bool>
    }
}
