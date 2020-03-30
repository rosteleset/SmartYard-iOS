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
    
    private let userPhone: String?
    
    private let id = "3beb2614f4573475b18bd25deb77f6e9"
    private let domain = "lanta-net.ru"
    
    init(userPhone: String?) {
        self.userPhone = userPhone
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        load(id, domain)
        
        if let phone = userPhone {
            callJsSetClientInfo("{phone: \"\("8" + phone)\"}")
        }
    }
    
    private func loadWithClientId(clientId: String) {
        load(id, domain, clientId)
    }
    
}
