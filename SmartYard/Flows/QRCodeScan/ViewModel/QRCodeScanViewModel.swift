//
//  QRCodeScanViewModel.swift
//  SmartYard
//
//  Created by admin on 19/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxCocoa
import RxSwift
import AVFoundation
import XCoordinator

protocol QRCodeScanViewModelDelegate: AnyObject {
    
    func qrCodeScanViewModel(_ viewModel: QRCodeScanViewModel, didExtractCode: String)
    
}

final class QRCodeScanViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    
    private weak var delegate: QRCodeScanViewModelDelegate?
    
    init(router: WeakRouter<HomeRoute>, delegate: QRCodeScanViewModelDelegate) {
        self.router = router
        self.delegate = delegate
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        // MARK: Если попытаться вернуть QR-код до того, как будет завершен транзишен, может произойти глич
        // Поэтому последовательность такая:
        // 1. Ждем, пока полностью завершится транзишен показа экрана QRCodeScan
        // 2. Начинаем сканирование, возвращаем результат
        // 3. Закрываем экран QRCodeScan. Ждем, пока полностью завершится транзишен скрытия экрана
        // 4. Делаем все остальное
        
        let isTransitionCompleted = BehaviorSubject<Bool>(value: false)
        
        input.viewDidAppearTrigger
            .drive(
                onNext: { _ in
                    isTransitionCompleted.onNext(true)
                }
            )
            .disposed(by: disposeBag)
        
        let readableObjectsProxy = BehaviorSubject<[AVMetadataMachineReadableCodeObject]>(value: [])
        
        input.readableObjects
            .drive(
                onNext: { objects in
                    readableObjectsProxy.onNext(objects)
                }
            )
            .disposed(by: disposeBag)
        
        Driver
            .combineLatest(
                isTransitionCompleted.asDriverOnErrorJustComplete(),
                readableObjectsProxy.asDriverOnErrorJustComplete()
            )
            .flatMap { args -> Driver<[AVMetadataMachineReadableCodeObject]> in
                let (isTransitionCompleted, objects) = args
                
                guard isTransitionCompleted else {
                    return .empty()
                }
                
                return .just(objects)
            }
            .map { [weak self] readableObjects -> String? in
                guard let self = self else {
                    return nil
                }
                
                return readableObjects.compactMap { object in
                    self.extractCode(from: object)
                }.first
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] code in
                    guard let self = self else {
                        return
                    }
                    
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    
                    self.delegate?.qrCodeScanViewModel(self, didExtractCode: code)
                }
            )
            .disposed(by: disposeBag)
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        input.cameraFailureTrigger
            .drive(
                onNext: { [weak self] in
                    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                        self?.router.trigger(.back)
                    }
                    
                    let message = NSError.GenericError.cameraSetupFailed.localizedDescription
                    
                    self?.router.trigger(.dialog(
                        title: NSLocalizedString("Error", comment: ""),
                        message: message,
                        actions: [okAction]
                    ))
                }
            )
            .disposed(by: disposeBag)
        
        return Output()
    }
    
    private func extractCode(from readableObject: AVMetadataMachineReadableCodeObject) -> String? {
        // MARK: Я думал, тут будет какая-то клиент-сайд валидация, но тут нет вообще ничего
        
        return readableObject.stringValue
    }
    
}

extension QRCodeScanViewModel {
    
    struct Input {
        let viewDidAppearTrigger: Driver<Bool>
        let readableObjects: Driver<[AVMetadataMachineReadableCodeObject]>
        let backTrigger: Driver<Void>
        let cameraFailureTrigger: Driver<Void>
    }
    
    struct Output {
    }
    
}
