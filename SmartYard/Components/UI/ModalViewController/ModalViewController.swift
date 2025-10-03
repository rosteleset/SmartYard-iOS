//
//  ModalViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 01.09.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import XCoordinator

/// перечень xib файлов, с содержимым модальных окон
enum ModalContent: String {
    case aboutWhiteRabbit = "WhiteRabbitModalViewContent"
    case aboutWaitingGuests = "WaitingGuestModalViewContent"
    case aboutVideoEvent = "VideoEventModalViewContent"
    case aboutCallKit = "CallKitModalViewContent"
    case aboutAddressOrder = "AddressOrderModalViewContent"
}

/// чтобы не делать 100500 классов для очень похожих модальных окошек с крестиком в правом верхнем углу,
/// я решил сделать один общий класс,
/// который в инициализаторе принимает название файла с содержимым
final class ModalViewController: BaseViewController {
    
    @IBOutlet private weak var cancelButton: CircleIconControl!
    @IBOutlet private weak var containerView: UIView!
    
    private let contentView: UIView
    
    init (dismissCallback: (@escaping () -> Void), content: ModalContent) {
        
        let nib = Bundle.main.loadNibNamed(content.rawValue, owner: nil, options: nil)
        self.contentView = nib?.first as? UIView ?? UIView()
        let dismissGesture = UITapGestureRecognizer()
        super.init(nibName: nil, bundle: nil)

        dismissGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissGesture)
        
        Driver.merge(
            dismissGesture.rx.event.asDriver().mapToVoid(),
            cancelButton.rx.tap.asDriver()
        )
        .drive(
            onNext: { dismissCallback() }
        )
        .disposed(by: disposeBag)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelButton.style = .Close.blue
        self.containerView.addSubview(self.contentView)
        contentView.alignToView(containerView)
    }
}
