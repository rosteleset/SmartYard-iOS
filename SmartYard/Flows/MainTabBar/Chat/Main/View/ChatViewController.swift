//
//  ChatViewController.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
//import OnlineChatSdk
import JGProgressHUD
import WebKit

class ChatViewController: BaseViewController, LoaderPresentable {
//class ChatViewController: ChatController, LoaderPresentable {
    
//    private let disposeBag = DisposeBag()
    private let viewModel: ChatViewModel
    
    var loader: JGProgressHUD?
    
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
        let input = ChatViewModel.Input(
            viewWillAppearTrigger: rx.viewWillAppear.asDriver(),
            isViewVisible: rx.isVisible.asDriver(onErrorJustReturn: false)
        )
        
        let output = viewModel.transform(input)
        
        output.chatConfiguration
            .drive(
                onNext: { [weak self] config in
//                    self?.load(
//                        config.id,
//                        config.domain,
//                        language: config.language ?? "",
//                        clientId: config.clientId ?? ""
//                    )
                }
            )
            .disposed(by: disposeBag)
        
        output.automaticMessage
            .drive(
                onNext: { [weak self] message in
//                    self?.callJsSendMessage(message)
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
                    
//                    self?.callJsSetClientInfo(finalString)
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoggingOut
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
extension ChatViewController {
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.navigationType == .linkActivated else {
            decisionHandler(WKNavigationActionPolicy.allow)
            return
        }
        
        if let url = navigationAction.request.url {
                UIApplication.shared.open(url)
        }
        
        decisionHandler(WKNavigationActionPolicy.cancel)
    }
    
}
