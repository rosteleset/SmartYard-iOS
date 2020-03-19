//
//  QRCodeScanViewModel.swift
//  SmartYard
//
//  Created by admin on 19/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxCocoa
import RxSwift
import AVFoundation
import XCoordinator

protocol QRCodeScanViewModelDelegate: AnyObject {
    
    func qrCodeScanViewModel(_ viewModel: QRCodeScanViewModel, didExtractCode: String)
    
}

class QRCodeScanViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    
    private weak var delegate: QRCodeScanViewModelDelegate?
    
    init(router: WeakRouter<HomeRoute>, delegate: QRCodeScanViewModelDelegate) {
        self.router = router
        self.delegate = delegate
    }
    
    func transform(input: Input) -> Output {
        input.readableObjects
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
                    self.router.trigger(.back)
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
                    
                    self?.router.trigger(.dialog(title: "Ошибка", message: message, actions: [okAction]))
                }
            )
            .disposed(by: disposeBag)
        
        return Output()
    }
    
    private func extractCode(from readableObject: AVMetadataMachineReadableCodeObject) -> String? {
        return readableObject.stringValue
    }
    
}

extension QRCodeScanViewModel {
    
    struct Input {
        let readableObjects: Driver<[AVMetadataMachineReadableCodeObject]>
        let backTrigger: Driver<Void>
        let cameraFailureTrigger: Driver<Void>
    }
    
    struct Output {
    }
    
}
