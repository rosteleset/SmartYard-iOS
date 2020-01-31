//
//  IncomingCallPreviewViewModel.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Kingfisher
import RxSwift
import RxCocoa

class IncomingCallPreviewViewModel: BaseViewModel {
    
    private let callPayload: CallPayload
    
    private let latestPreview = BehaviorSubject<UIImage?>(value: nil)
    
    init(callPayload: CallPayload) {
        self.callPayload = callPayload
    }
    
    func transform(input: Input) -> Output {
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

extension IncomingCallPreviewViewModel {
    
    struct Input {
    }
    
    struct Output {
        let preview: Driver<UIImage?>
    }
    
}
