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
        apiWrapper: APIWrapper,
        image: UIImage? = nil,
        imageURL: String? = nil,
        flatId: Int? = nil,
        faceId: Int? = nil,
        event: APIPlog? = nil
    ) {
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
            onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
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
                onNext: { [weak self] in
                    self?.apiWrapper.forceUpdateFaces = true
                    
                    // создаю копию события, в котором меняю доступные для пользователя действия
                    if let event = self?.event,
                       let newDetailX = event.detailX,
                          var newFlags = newDetailX.flags {
                        newFlags.removeAll(where: { $0 == "canDisLike" || $0 == "canDislike" || $0 == "canLike" })
                        newFlags.append("canLike")
                        
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
                            houseId: event.houseId,
                            entranceId: event.entranceId,
                            cameraId: event.cameraId,
                            event: event.event,
                            detail: event.detail,
                            detailX: newDetailX, // заменяем только вот это поле
                            previewURL: event.previewURL,
                            previewImage: event.previewImage
                        )
                        
                        // передаю обновлённое состояние карточки через NotificationCenter для обработки контроллером
                        NotificationCenter.default.post(.init(name: .updateEvent, object: updatedEvent))
                    }
                    
                    // уведомляю контроллеры, зависимые от списка лиц (Список лиц в настройках доступа), что он требует обновление
                    NotificationCenter.default.post(.init(name: .updateFaces, object: nil))
                    self?.dismiss(animated: true, completion: nil)
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
        // imageView.sizeToFit()
    }

}
