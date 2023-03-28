//
//  ChatwootPreviewController.swift
//  SmartYard
//
//  Created by devcentra on 23.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ChatwootPreviewController: BaseViewController {
    
    @IBOutlet private weak var chatwootView: ChatwootView!

    private let viewModel: ChatwootPreviewModel

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    init(viewModel: ChatwootPreviewModel) {
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
        
        let input = ChatwootPreviewModel.Input(
            chatViewTapped: chatwootView.rx.chatButtonTapped.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
    }

}
