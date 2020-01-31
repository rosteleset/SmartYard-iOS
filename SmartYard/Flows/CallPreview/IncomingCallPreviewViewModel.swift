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
import UIKit

class IncomingCallPreviewViewModel: BaseViewModel {
    
    private let linphoneService: LinphoneService
    private let callPayload: CallPayload
    
    private let latestPreview = BehaviorSubject<UIImage?>(value: nil)
    
    init(linphoneService: LinphoneService, callPayload: CallPayload) {
        self.linphoneService = linphoneService
        self.callPayload = callPayload
    }
    
    func transform(input: Input) -> Output {
        input.connectTrigger
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.linphoneService.connect(
                        config: self.callPayload.sipConfig,
                        videoView: UIView(),
                        cameraView: UIView()
                    )
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

extension IncomingCallPreviewViewModel {
    
    struct Input {
        let connectTrigger: Driver<Void>
    }
    
    struct Output {
        let preview: Driver<UIImage?>
    }
    
}
