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
        let failed = PublishSubject<Void>()
        
        let succeeded = input.readableObjects
            .map { [weak self] readableObjects in
                readableObjects.compactMap { object in
                    self?.extractCode(from: object)
                }.first
            }
            .ignoreNil()
            .map { () }
        
        input.errorData
            .drive(
                onNext: { [weak self] error in
                    failed.onNext(())
                    
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
        
        return Output(failed: failed.asDriverOnErrorJustComplete(), succeeded: succeeded)
    }
    
    private func extractCode(from readableObject: AVMetadataMachineReadableCodeObject) -> String? {
        guard let stringValue = readableObject.stringValue, let descriptor = readableObject.descriptor else {
            return nil
        }
        
        return "DEBUG"
    }
    
}

extension QRCodeScanViewModel {
    
    struct Input {
        let errorData: Driver<Error>
        let readableObjects: Driver<[AVMetadataMachineReadableCodeObject]>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let failed: Driver<Void>
        let succeeded: Driver<Void>
    }
    
}
