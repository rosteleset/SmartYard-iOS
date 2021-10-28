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

class AddFaceViewController: BaseViewController {

    @IBOutlet private weak var imageView: ScaledHeightImageView!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var addButton: UIButton!
    
    private let event: APIPlog
    private let apiWrapper: APIWrapper
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(apiWrapper: APIWrapper, event: APIPlog) {
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
            onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        )
        .disposed(by: disposeBag)
        
        addButton.rx.tap.asDriver()
            .flatMapLatest {
                apiWrapper.likePersonFace(event: event.uuid)
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] in
                    self?.apiWrapper.forceUpdateFaces = true
                    
                    // создаю копию события, в котором меняю доступные для пользователя действия
                    if let newDetailX = self?.event.detailX,
                          var newFlags = newDetailX.flags {
                        newFlags.removeAll(where: { $0 == "canDislike" || $0 == "canDisLike" || $0 == "canLike" })
                        newFlags.append("canDislike")
                        
                        let newDetailX = DetailX(
                            key: newDetailX.key,
                            face: newDetailX.face,
                            flags: newFlags, // заменяем только вот это поле
                            phone: newDetailX.phone,
                            code: newDetailX.code,
                            faceId: newDetailX.faceId
                        )
                        
                        let updatedEvent = APIPlog(
                            date: event.date,
                            uuid: event.uuid,
                            imageUuid: event.imageUuid,
                            objectId: event.objectId,
                            objectType: event.objectType,
                            objectMechanizma: event.objectMechanizma,
                            mechanizmaDescription: event.mechanizmaDescription,
                            event: event.event,
                            detail: event.detail,
                            detailX: newDetailX, // заменяем только вот это поле
                            previewURL: event.previewURL,
                            previewImage: event.previewImage
                        )
                        // передаю обновлённое состояние карточки через NotificationCenter для обработки контроллером
                        NotificationCenter.default.post(.init(name: .updateEvent, object: updatedEvent))
                    }
                    
                    // уведомляю контроллеры, зависимые от списка лиц, что он требует обновление
                    NotificationCenter.default.post(.init(name: .updateFaces, object: nil))
                    
                    self?.dismiss(animated: true, completion: nil)
                }
            )
            .disposed(by: disposeBag)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = self.event.previewURL,
              let rect = self.event.detailX?.face?.asCGRect else {
            return
        }
        
        imageView.loadImageUsingUrlString(urlString: url, cache: imagesCache, rect: rect, rectColor: .red)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // imageView.sizeToFit()
    }

}
