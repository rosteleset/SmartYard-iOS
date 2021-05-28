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

class DeleteFaceViewController: BaseViewController {

    @IBOutlet private weak var imageView: ScaledHeightImageView!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var deleteButton: UIButton!
    
    private let router: WeakRouter<SettingsRoute>
    private let image: UIImage?
    private let faceId: Int
    private let flatId: Int
    private let apiWrapper: APIWrapper
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(router: WeakRouter<SettingsRoute>, apiWrapper: APIWrapper, image: UIImage?, flatId: Int, faceId: Int) {
        self.router = router
        self.image = image
        self.faceId = faceId
        self.flatId = flatId
        self.apiWrapper = apiWrapper
        
        super.init(nibName: nil, bundle: nil)
        
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let dismissGesture = UITapGestureRecognizer()
        dismissGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissGesture)
        
        Driver.merge(
            dismissGesture.rx.event.asDriver().mapToVoid(),
            cancelButton.rx.tap.asDriver()
        )
        .drive(
            onNext: {
                router.trigger(.dismiss)
            }
        )
        .disposed(by: disposeBag)
        
        deleteButton.rx.tap.asDriver()
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return apiWrapper.disLikePersonFace(flatId: self.flatId, faceId: self.faceId)
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: {
                    NotificationCenter.default.post(.init(name: .updateFaces, object: nil))
                    router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = image
    }

}
