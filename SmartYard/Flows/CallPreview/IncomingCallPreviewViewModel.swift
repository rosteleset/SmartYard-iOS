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
        return Output(preview: latestPreview.asDriver(onErrorJustReturn: nil))
    }
    
}

extension IncomingCallPreviewViewModel {
    
    struct Input {
        let viewWillAppear: Driver<Bool>
    }
    
    struct Output {
        let preview: Driver<UIImage?>
    }
    
}
