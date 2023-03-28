//
//  ChatwootViewModel.swift
//  SmartYard
//
//  Created by devcentra on 20.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class ChatwootPreviewModel: BaseViewModel {
    
    private let router: WeakRouter<ChatwootRoute>

    init(
        router: WeakRouter<ChatwootRoute>
    ) {
        self.router = router

        super.init()
        
    }
    
    func transform(_ input: Input) -> Output {
        input.chatViewTapped
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.main)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
        )
    }

}

extension ChatwootPreviewModel {
    
    struct Input {
        let chatViewTapped: Driver<Void>
    }
    
    struct Output {
    }

}
