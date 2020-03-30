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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        load("3beb2614f4573475b18bd25deb77f6e9", "lanta-net.ru")
    }
    
}
