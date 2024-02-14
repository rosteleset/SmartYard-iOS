//
//  IncomingCallLandscapeViewController.swift
//  SmartYard
//
//  Created by admin on 27.07.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import TouchAreaInsets

class IncomingCallLandscapeViewController: BaseViewController {
    
    @IBOutlet private weak var previewButton: UIButton!
    @IBOutlet private weak var callButton: UIButton!
    @IBOutlet private weak var ignoreButton: UIButton!
    @IBOutlet private weak var openButton: LoadingButton!
    @IBOutlet private weak var alreadyOpenedButton: UIButton! 
    @IBOutlet private weak var speakerButton: UIButton!
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageViewActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var videoPreview: UIView!
    @IBOutlet private weak var gradientContainer: UIView!
    @IBOutlet private weak var webRTCView: UIView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    
    @IBOutlet private weak var exitFullscreenButton: UIButton!
    
    private var SIPHasVideo = true
    private var webRTCHasVideo = false
    
    private let viewModel: IncomingCallViewModel
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeLeft
    }
    
    init(viewModel: IncomingCallViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtons()
        configureGradient()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let videoWidth: CGFloat = 1280
        let videoHeight: CGFloat = 720

        let widthScale = UIScreen.main.bounds.width / videoWidth + 0.001
        let heightScale = UIScreen.main.bounds.height / videoHeight + 0.001

        let maxScaleForAspectFill = max(widthScale, heightScale)

        videoPreview.transform = CGAffineTransform(scaleX: maxScaleForAspectFill, y: maxScaleForAspectFill)
    }
    
    private func configureGradient() {
        let linearGradientView = LinearGradientView(frame: gradientContainer.bounds)
        linearGradientView.startPoint = CGPoint(x: 0.0, y: 0.0)
        linearGradientView.endPoint = CGPoint(x: 0.0, y: 1.0)
        linearGradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        linearGradientView.colors = [
            UIColor.black.withAlphaComponent(0.5),
            .clear,
            UIColor.black.withAlphaComponent(0.8)
        ]
        
        gradientContainer.addSubview(linearGradientView)
    }
    
    private func configureButtons() {
        previewButton.setImage(UIImage(named: "PreviewUnselectedIconL"), for: .normal)
        previewButton.setImage(UIImage(named: "PreviewUnselectedIconL")?.darkened(), for: [.normal, .highlighted])
        previewButton.setImage(UIImage(named: "PreviewSelectedIcon"), for: .selected)
        previewButton.setImage(UIImage(named: "PreviewSelectedIcon")?.darkened(), for: [.selected, .highlighted])
        
        callButton.setImage(UIImage(named: "CallUnselectedIconL"), for: .normal)
        callButton.setImage(UIImage(named: "CallUnselectedIconL")?.darkened(), for: [.normal, .highlighted])
        callButton.setImage(UIImage(named: "CallSelectedIcon"), for: .selected)
        callButton.setImage(UIImage(named: "CallSelectedIcon")?.darkened(), for: [.selected, .highlighted])
        
        speakerButton.setImage(UIImage(named: "SpeakerUnselectedIconL"), for: .normal)
        speakerButton.setImage(UIImage(named: "SpeakerUnselectedIconL")?.darkened(), for: [.normal, .highlighted])
        speakerButton.setImage(UIImage(named: "SpeakerSelectedIcon"), for: .selected)
        speakerButton.setImage(UIImage(named: "SpeakerSelectedIcon")?.darkened(), for: [.selected, .highlighted])
        
        openButton.setImage(UIImage(named: "UnlockIcon"), for: .normal)
        
        let imageForDisabled = UIImage(color: UIColor(hex: 0x4CD964)!, size: CGSize(width: 100, height: 100))
            .withRoundedCorners(radius: 50)
        
        openButton.setImage(imageForDisabled, for: .disabled)
        
        exitFullscreenButton.touchAreaInsets = UIEdgeInsets(inset: 20)
    }
    
    private func bind() {
        let callTrigger = callButton.rx.tap
            .do(
                onNext: { [weak self] _ in
                    self?.imageViewActivityIndicator.stopAnimating()
                }
            )
        
        let actualVideoViews: Driver<(UIView, UIView, UIView)> = rx.viewWillAppear.asDriver()
            .flatMap { [weak self] _ in
                guard let self = self else {
                    return .empty()
                }
                
                return .just((self.videoPreview, self.webRTCView, UIView()))
            }

        let input = IncomingCallViewModel.Input(
            previewTrigger: previewButton.rx.tap.asDriver(),
            callTrigger: callTrigger.asDriverOnErrorJustComplete(),
            videoViewsTrigger: .merge(actualVideoViews, .just((videoPreview, webRTCView, UIView()))),
            ignoreTrigger: ignoreButton.rx.tap.asDriver(),
            openTrigger: openButton.rx.tap.asDriver(),
            speakerTrigger: speakerButton.rx.tap.asDriver(),
            viewWillAppear: rx.viewWillAppear.asDriver().map { _ in .landscape }
        )

        let output = viewModel.transform(input: input)

        output.subtitle
            .drive(subtitleLabel.rx.text)
            .disposed(by: disposeBag)

        output.image
            .do(
                onNext: { [weak self] image in
                    image == nil ?
                        self?.imageViewActivityIndicator.startAnimating() :
                        self?.imageViewActivityIndicator.stopAnimating()
                }
            )
            .drive(imageView.rx.image)
            .disposed(by: disposeBag)

        output.state
            .withLatestFrom(output.image) { ($0, $1) }
            .drive(
                onNext: { [weak self] state, image in
                    self?.applyState(state, hasImage: image != nil)
                }
            )
            .disposed(by: disposeBag)
        
        output.isSIPHasVideo
            .drive(
                onNext: { [weak self] hasVideo in
                    self?.SIPHasVideo = hasVideo
                }
            )
            .disposed(by: disposeBag)
        
        output.isWebRTCHasVideo
            .drive(
                onNext: { [weak self] hasVideo in
                    self?.webRTCHasVideo = hasVideo
                }
            )
            .disposed(by: disposeBag)

        output.isDoorBeingOpened
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    isLoading ? self?.openButton.showLoading() : self?.openButton.hideLoading()
                }
            )
            .disposed(by: disposeBag)
        
        exitFullscreenButton.rx.tap
            .subscribe(
                onNext: {
                    NotificationCenter.default.post(name: .incomingCallForcePortrait, object: nil)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func applyState(_ state: IncomingCallStateContainer, hasImage: Bool) {
        view.isUserInteractionEnabled = state.callState != .callFinished
        
        previewButton.isSelected = state.previewState == .video && state.doorState == .notDetermined
        callButton.isSelected = (state.callState == .establishingConnection || state.callState == .callActive)
            && state.doorState == .notDetermined
        speakerButton.isSelected = state.soundOutputState == .speaker
        
        let shouldShowVideo = (state.callState == .callActive || state.callState == .callReceived) && state.previewState == .video
        
        videoPreview.isHidden = !shouldShowVideo || (!SIPHasVideo && webRTCHasVideo)
        webRTCView.isHidden = !shouldShowVideo || (SIPHasVideo && !webRTCHasVideo)

        imageView.isHidden = !(state.previewState == .staticImage || (state.previewState == .video && !SIPHasVideo && !webRTCHasVideo))
        imageViewActivityIndicator.isHidden = shouldShowVideo || hasImage
        
        callButton.isHidden = [.callActive, .callFinished].contains(state.callState)
        speakerButton.isHidden = [.callReceived, .establishingConnection].contains(state.callState)
        
        alreadyOpenedButton.isHidden = state.doorState != .opened
        openButton.isHidden = state.doorState == .opened
        ignoreButton.isHidden = state.doorState == .opened
        
        switch (state.callState, state.previewState) {
        case (.callReceived, .staticImage):
            titleLabel.text = NSLocalizedString("Call to intercom", comment: "")
            
        case (.callReceived, .video):
            titleLabel.text = NSLocalizedString("Peephole on", comment: "")
            
        case (.establishingConnection, _):
            titleLabel.text = NSLocalizedString("Connecting...", comment: "")
            
        case (.callActive, _):
            titleLabel.text = NSLocalizedString("Conversation", comment: "")
            
        case (.callFinished, _):
            titleLabel.text = NSLocalizedString("Call completed", comment: "")
        }
    }

}
