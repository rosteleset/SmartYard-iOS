//
//  ChatViewController.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import OnlineChatSdk

class ChatViewController: ChatController {
    
    private let disposeBag = DisposeBag()
    private let viewModel: ChatViewModel
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bind()
    }
    
    private func bind() {
        let input = ChatViewModel.Input()
        
        let output = viewModel.transform(input)
        
        output.chatConfiguration
            .drive(
                onNext: { [weak self] config in
                    self?.load(config.id, config.domain, config.language ?? "", config.clientId ?? "")
                }
            )
            .disposed(by: disposeBag)
        
//        if let phone = userPhone {
//            callJsSetClientInfo("{phone: \"\("8" + phone)\"}")
//        }
    }
    
}
