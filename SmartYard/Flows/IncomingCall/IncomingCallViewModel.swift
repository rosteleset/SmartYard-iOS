//
//  IncomingCallViewModel.swift
//  SmartYard
//
//  Created by admin on 04/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Kingfisher
import RxSwift
import RxCocoa
import UIKit
import linphonesw

class IncomingCallViewModel: BaseViewModel {
    
    private let linphoneService: LinphoneService
    private let callPayload: CallPayload
    
    private let latestPreview = BehaviorSubject<UIImage?>(value: nil)
    
    init(linphoneService: LinphoneService, callPayload: CallPayload) {
        self.linphoneService = linphoneService
        self.callPayload = callPayload
    }
    
    func transform(input: Input) -> Output {
        input.acceptTrigger
            .drive(
                onNext: {
                    print("accept call here")
                }
            )
            .disposed(by: disposeBag)
        
        input.rejectTrigger
            .drive(
                onNext: {
                    print("reject call here")
                }
            )
            .disposed(by: disposeBag)
        
        guard let liveUrl = URL(string: callPayload.liveImage) else {
            return Output(preview: .just(nil))
        }
        
        let loadNextImageTrigger = PublishSubject<Void>()
        
        Observable
            .merge(
                loadNextImageTrigger,
                .just(())
            )
            .delay(.milliseconds(250), scheduler: MainScheduler.instance)
            .subscribe(
                onNext: { _ in
                    KingfisherManager.shared.retrieveImage(
                        with: liveUrl,
                        options: [.forceRefresh]
                    ) { [weak self] result in
                        if let image = try? result.get().image {
                            self?.latestPreview.onNext(image)
                        }
                        
                        loadNextImageTrigger.onNext(())
                    }
                }
            )
            .disposed(by: disposeBag)
        
        return Output(preview: latestPreview.asDriver(onErrorJustReturn: nil))
    }
    
}

extension IncomingCallViewModel {
    
    struct Input {
        let acceptTrigger: Driver<Void>
        let rejectTrigger: Driver<Void>
    }
    
    struct Output {
        let preview: Driver<UIImage?>
    }
    
}
