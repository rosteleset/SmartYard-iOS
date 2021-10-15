//
//  QRCodeScanViewController.swift
//  SmartYard
//
//  Created by admin on 19/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa
import TouchAreaInsets

class QRCodeScanViewController: BaseViewController {
    
    @IBOutlet private weak var previewContainer: UIView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var flashButton: UIButton!
    @IBOutlet private weak var scanningArea: UIView!
    
    private let viewModel: QRCodeScanViewModel
    
    private let cameraFailureTrigger = PublishSubject<Void>()
    private let readableObjects = PublishSubject<[AVMetadataMachineReadableCodeObject]>()
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var blurLayer: CAShapeLayer?
    private var whiteFrameLayer: CAShapeLayer?
    
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
        configureView()
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
        
        blurLayer?.path = createBlurPath(for: view.bounds)
        blurLayer?.frame = view.bounds
        
        whiteFrameLayer?.path = UIBezierPath(roundedRect: scanningArea.frame, cornerRadius: 20).cgPath
        whiteFrameLayer?.frame = view.bounds
    }
    
    private func configureView() {
        guard configureCaptureSession() else {
            cameraFailureTrigger.onNext(())
            return
        }
        
        configureBlurLayer()
        configureWhiteFrameLayer()
        
        backButton.touchAreaInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        flashButton.configureSelectableButton(
            imageForNormal: UIImage(named: "FlashDisabledIcon"),
            imageForSelected: UIImage(named: "FlashEnabledIcon")
        )
        
        flashButton.rx.tap.asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    let newState = !self.flashButton.isSelected
                    
                    self.toggleTorch(on: newState)
                }
            )
            .disposed(by: disposeBag)
        
        flashButton.touchAreaInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
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
            viewDidAppearTrigger: rx.viewDidAppear.asDriver(),
            readableObjects: readableObjects.asDriverOnErrorJustComplete(),
            backTrigger: backButton.rx.tap.asDriver(),
            cameraFailureTrigger: cameraFailure
        )
        
        _ = viewModel.transform(input: input)
    }
    
    private func configureCaptureSession() -> Bool {
        let captureSession = AVCaptureSession()
        let metadataOutput = AVCaptureMetadataOutput()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
            captureSession.canAddInput(videoInput),
            captureSession.canAddOutput(metadataOutput) else {
            return false
        }
        
        captureSession.addInput(videoInput)
        captureSession.addOutput(metadataOutput)
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        metadataOutput.metadataObjectTypes = [.qr]
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewContainer.layer.insertSublayer(previewLayer, at: 0)
        
        self.previewLayer = previewLayer
        self.captureSession = captureSession
        
        return true
    }
    
    // MARK: Темный слой с прозрачной дырой для сканирования
    
    private func configureBlurLayer() {
        let blurLayer = CAShapeLayer()
        
        blurLayer.path = createBlurPath(for: view.bounds)
        blurLayer.fillRule = .evenOdd
        blurLayer.fillColor = UIColor.black.cgColor
        blurLayer.opacity = 0.6
        
        previewContainer.layer.addSublayer(blurLayer)
        self.blurLayer = blurLayer
    }

    private func createBlurPath(for bounds: CGRect) -> CGPath {
        let fullPath = UIBezierPath(rect: bounds)
        let highlightedPartPath = UIBezierPath(roundedRect: scanningArea.frame, cornerRadius: 20)
        
        fullPath.append(highlightedPartPath)
        fullPath.usesEvenOddFillRule = true
        
        return fullPath.cgPath
    }
    
    // MARK: Белая рамка вокруг дыры для сканирования
    
    private func configureWhiteFrameLayer() {
        let whiteFrameLayer = CAShapeLayer()
        
        whiteFrameLayer.path = UIBezierPath(roundedRect: scanningArea.frame, cornerRadius: 20).cgPath
        whiteFrameLayer.lineWidth = 4
        whiteFrameLayer.strokeColor = UIColor.white.cgColor
        whiteFrameLayer.fillColor = UIColor.clear.cgColor
        
        previewContainer.layer.addSublayer(whiteFrameLayer)
        self.whiteFrameLayer = whiteFrameLayer
    }
    
    /// Включение / выключение фонаря
    private func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
            
            flashButton.isSelected = on
        } catch {
            print("Torch could not be used")
        }
    }
    
}

extension QRCodeScanViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let previewLayer = previewLayer else {
            return
        }
        
        // MARK: Вообще сканирование происходит всей камерой, а не только внутри какой-то рамки
        // Но раз эта рамка есть, наверное, стоит сократить область сканирования именно до нее
        // Поэтому просто фильтруем объекты, которые находятся внутри рамки
        
        let objectsInsideFrame = metadataObjects
            .filter { object in
                guard let objectBounds = previewLayer.transformedMetadataObject(for: object)?.bounds else {
                    return false
                }
                
                return scanningArea.frame.contains(objectBounds)
            }
            .compactMap { $0 as? AVMetadataMachineReadableCodeObject }
        
        readableObjects.onNext(objectsInsideFrame)
    }
    
}
