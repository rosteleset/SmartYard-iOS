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
    
    private let homeRouter: WeakRouter<HomeRoute>?
    private let settingsRouter: WeakRouter<SettingsRoute>?
    private let image: UIImage?
    private let imageURL: String?
    private let faceId: Int?
    private let flatId: Int?
    private let event: APIPlog?
    private let apiWrapper: APIWrapper
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // swiftlint:disable:next function_body_length
    init(
        homeRouter: WeakRouter<HomeRoute>? = nil,
        settingsRouter: WeakRouter<SettingsRoute>? = nil,
        apiWrapper: APIWrapper,
        image: UIImage? = nil,
        imageURL: String? = nil,
        flatId: Int? = nil,
        faceId: Int? = nil,
        event: APIPlog? = nil
    ) {
        self.homeRouter = homeRouter
        self.settingsRouter = settingsRouter
        self.image = image
        self.imageURL = imageURL
        self.faceId = faceId
        self.flatId = flatId
        self.event = event
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
                settingsRouter?.trigger(.dismiss)
                homeRouter?.trigger(.dismiss)
            }
        )
        .disposed(by: disposeBag)
        
        deleteButton.rx.tap.asDriver()
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                if let flatId = self.flatId,
                   let faceId = self.faceId {
                    return apiWrapper.disLikePersonFace(flatId: flatId, faceId: faceId)
                        .trackError(errorTracker)
                        .trackActivity(activityTracker)
                        .asDriver(onErrorJustReturn: nil)
                }
                if let uuid = self.event?.uuid {
                    return apiWrapper.disLikePersonFace(event: uuid)
                        .trackError(errorTracker)
                        .trackActivity(activityTracker)
                        .asDriver(onErrorJustReturn: nil)
                }
                return .empty()
            }
            .ignoreNil()
            .drive(
                onNext: {
                    NotificationCenter.default.post(.init(name: .updateFaces, object: nil))
                    settingsRouter?.trigger(.dismiss)
                    homeRouter?.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.image != nil {
            imageView.image = image
        } else {
            guard let url = self.imageURL else {
                return
            }
            
            imageView.loadImageUsingUrlString(urlString: url, cache: imagesCache)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //imageView.sizeToFit()
    }

}
