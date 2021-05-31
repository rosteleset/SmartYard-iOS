//
//  FaceViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 13.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import XCoordinator

class FaceViewController: BaseViewController {

    @IBOutlet private weak var imageView: ScaledHeightImageView!
    @IBOutlet private weak var closeButton: UIButton!
    
    private let router: WeakRouter<SettingsRoute>
    private let image: UIImage?
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(router: WeakRouter<SettingsRoute>, image: UIImage?) {
        self.router = router
        self.image = image
        
        super.init(nibName: nil, bundle: nil)
        
        let dismissGesture = UITapGestureRecognizer()
        dismissGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissGesture)
        
        Driver.merge(
            dismissGesture.rx.event.asDriver().mapToVoid(),
            closeButton.rx.tap.asDriver()
        )
        .drive(
            onNext: {
                router.trigger(.dismiss)
            }
        )
        .disposed(by: disposeBag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.sizeToFit()
    }

}
