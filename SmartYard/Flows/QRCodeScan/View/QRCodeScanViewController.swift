//
//  QRCodeScanViewController.swift
//  SmartYard
//
//  Created by admin on 19/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

class QRCodeScanViewController: BaseViewController {
    
    @IBOutlet private weak var previewContainer: UIView!
    @IBOutlet private weak var darkView: UIView!
    @IBOutlet private weak var backButton: UIButton!
    
    private let viewModel: QRCodeScanViewModel
    
    private let cameraFailureTrigger = PublishSubject<Void>()
    private let readableObjects = PublishSubject<[AVMetadataMachineReadableCodeObject]>()
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    init(viewModel: QRCodeScanViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bind()
        
        guard configureCaptureSession() else {
            cameraFailureTrigger.onNext(())
            return
        }
        
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.darkView.alpha = 0.25
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession?.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func bind() {
        let cameraFailure = cameraFailureTrigger
            .asDriverOnErrorJustComplete()
            .do(
                onNext: { [weak self] in
                    self?.captureSession?.stopRunning()
                }
            )
        
        let input = QRCodeScanViewModel.Input(
            readableObjects: readableObjects.asDriverOnErrorJustComplete(),
            backTrigger: backButton.rx.tap.asDriver(),
            cameraFailureTrigger: cameraFailure
        )
        
        _ = viewModel.transform(input: input)
    }
    
    private func configureCaptureSession() -> Bool {
        let captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return false
        }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return false
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return false
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return false
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewContainer.layer.insertSublayer(previewLayer, at: 0)
        
        self.previewLayer = previewLayer
        self.captureSession = captureSession
        
        return true
    }
    
}

extension QRCodeScanViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        let objects = metadataObjects.compactMap {
            $0 as? AVMetadataMachineReadableCodeObject
        }
        
        readableObjects.onNext(objects)
    }
    
}
