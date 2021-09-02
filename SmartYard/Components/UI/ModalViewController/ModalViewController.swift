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

class ModalViewController: BaseViewController {
    
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var containerView: UIView!
    private var containerViewController: UIViewController
    
    private let settingsRouter: WeakRouter<SettingsRoute>
    
    init (settingsRouter: WeakRouter<SettingsRoute>) {
        self.settingsRouter = settingsRouter
        self.containerViewController = WhiteRabbitModalViewContent()
        
        let dismissGesture = UITapGestureRecognizer()
        super.init(nibName: nil, bundle: nil)
        
        dismissGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissGesture)
        Driver.merge(
            dismissGesture.rx.event.asDriver().mapToVoid(),
            cancelButton.rx.tap.asDriver()
        )
        .drive(
            onNext: {
                settingsRouter.trigger(.dismiss)
            }
        )
        .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(self.containerViewController)
        self.containerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.containerView.addSubview(self.containerViewController.view)
        
        NSLayoutConstraint.activate([
                self.containerViewController.view.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor, constant: 0),
                self.containerViewController.view.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor, constant: 0),
                self.containerViewController.view.topAnchor.constraint(equalTo: self.containerView.topAnchor, constant: 0),
                self.containerViewController.view.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: 0)
            ])
        
        self.containerViewController.didMove(toParent: self)
    }
}
