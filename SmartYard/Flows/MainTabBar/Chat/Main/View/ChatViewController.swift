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
                    self?.load(
                        config.id,
                        config.domain,
                        language: config.language ?? "",
                        clientId: config.clientId ?? ""
                    )
                }
            )
            .disposed(by: disposeBag)
        
        output.automaticMessage
            .drive(
                onNext: { [weak self] message in
                    self?.callJsSendMessage(message)
                }
            )
            .disposed(by: disposeBag)
        
        Driver.combineLatest(output.phone, output.name)
            .debounce(.milliseconds(100))
            .drive(
                onNext: { [weak self] args in
                    let (phone, name) = args
                    
                    var params = [String]()
                    
                    if let uName = name {
                        params.append("name: \"\(uName)\"")
                    }
                    
                    if let uPhone = phone {
                        params.append("phone: \"\(uPhone)\"")
                    }
                    
                    let finalString = "{" + params.joined(separator: ", ") + "}"
                    
                    self?.callJsSetClientInfo(finalString)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
