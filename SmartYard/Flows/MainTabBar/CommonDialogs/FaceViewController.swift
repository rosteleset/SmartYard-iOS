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

final class FaceViewController: BaseViewController {

    @IBOutlet private weak var imageView: ScaledHeightImageView!
    @IBOutlet private weak var closeButton: UIButton!
    
    private let image: UIImage?
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(image: UIImage?) {
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
            onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
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
        // imageView.sizeToFit()
    }

}
