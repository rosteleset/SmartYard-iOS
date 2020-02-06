//
//  UIView+KeyboardHeight.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension UIViewController {
    
    func getKeyboardHeightObservable() -> Observable<CGFloat> {
        return Observable.from(
            [
                NotificationCenter.default.rx
                    .notification(UIResponder.keyboardWillShowNotification)
                    .map { notification -> CGFloat in
                        guard let userInfo = notification.userInfo,
                              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)
                        else {
                            return 0
                        }
                        
                        return keyboardFrame.cgRectValue.height
                    },
                NotificationCenter.default.rx
                    .notification(UIResponder.keyboardWillHideNotification)
                    .map { _ -> CGFloat in
                        0
                    }
            ]
            )
            .merge()
    }
    
}
