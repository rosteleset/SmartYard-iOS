//
//  IncomingCallViewController.swift
//  SmartYard
//
//  Created by admin on 04/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import TouchAreaInsets

final class IncomingCallPortraitViewController: BaseViewController {
    
    @IBOutlet private weak var previewButton: UIButton!
    @IBOutlet private weak var callButton: UIButton!
    @IBOutlet private weak var ignoreButton: UIButton!
    @IBOutlet private weak var openButton: LoadingButton!
    @IBOutlet private weak var speakerButton: UIButton!
    
    @IBOutlet private weak var alreadyOpenedButtonContainer: UIView!
    @IBOutlet private weak var openButtonContainer: UIView!
    @IBOutlet private weak var ignoreButtonContainer: UIView!
    @IBOutlet private weak var speakerButtonContainer: UIView!
    @IBOutlet private weak var callButtonContainer: UIView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var ignoreButtonLabel: UILabel!
    @IBOutlet private weak var previewButtonLabel: UILabel!
    
    @IBOutlet private weak var videoBackgroundBlur: UIView!
    @IBOutlet private weak var videoPreview: UIView!
    @IBOutlet private weak var webRTCView: UIView!
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageViewActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var fullscreenButton: UIButton!
    @IBOutlet private weak var answerButtonLabel: UILabel!
    @IBOutlet private weak var speakerButtonLabel: UILabel!
    @IBOutlet private weak var openedButtonLabel: UILabel!
    @IBOutlet private weak var openButtonLabel: UILabel!
    private let viewModel: IncomingCallViewModel
    
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
        configureUI()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let targetHeight: CGFloat = 720
        let scaleRatio = imageView.bounds.height / targetHeight + 0.001
        
        videoPreview.transform = CGAffineTransform(scaleX: scaleRatio, y: scaleRatio)
        videoPreview.layerCornerRadius = 24 / scaleRatio
    }
    
    private func configureUI() {
        titleLabel.text = L10n.Intercom.Incoming.title
        subtitleLabel.text = L10n.Intercom.Incoming.addressPlaceholder
        previewButtonLabel.text = L10n.Intercom.Incoming.previewAction
        answerButtonLabel.text = L10n.Intercom.Incoming.answerAction
        speakerButtonLabel.text = L10n.Intercom.Incoming.speakerAction
        ignoreButtonLabel.text = L10n.Intercom.Incoming.ignoreAction
        openedButtonLabel.text = L10n.Intercom.Incoming.openedStatus
        openButtonLabel.text = L10n.Common.`open`
        previewButton.setImage(UIImage(named: "PreviewUnselectedIcon"), for: .normal)
        previewButton.setImage(UIImage(named: "PreviewUnselectedIcon")?.darkened(), for: [.normal, .highlighted])
        previewButton.setImage(UIImage(named: "PreviewSelectedIcon"), for: .selected)
        previewButton.setImage(UIImage(named: "PreviewSelectedIcon")?.darkened(), for: [.selected, .highlighted])
        
        callButton.setImage(UIImage(named: "CallUnselectedIcon"), for: .normal)
        callButton.setImage(UIImage(named: "CallUnselectedIcon")?.darkened(), for: [.normal, .highlighted])
        callButton.setImage(UIImage(named: "CallSelectedIcon"), for: .selected)
        callButton.setImage(UIImage(named: "CallSelectedIcon")?.darkened(), for: [.selected, .highlighted])
        
        speakerButton.setImage(UIImage(named: "SpeakerUnselectedIcon"), for: .normal)
        speakerButton.setImage(UIImage(named: "SpeakerUnselectedIcon")?.darkened(), for: [.normal, .highlighted])
        speakerButton.setImage(UIImage(named: "SpeakerSelectedIcon"), for: .selected)
        speakerButton.setImage(UIImage(named: "SpeakerSelectedIcon")?.darkened(), for: [.selected, .highlighted])
        
        openButton.setImage(UIImage(named: "UnlockIcon"), for: .normal)
        
        let imageForDisabled = UIImage(color: UIColor(hex: 0x4CD964)!, size: CGSize(width: 100, height: 100))
            .withRoundedCorners(radius: 50)
        
        openButton.setImage(imageForDisabled, for: .disabled)
        
        fullscreenButton.touchAreaInsets = UIEdgeInsets(inset: 20)
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
            viewWillAppear: rx.viewWillAppear.asDriver().map { _ in .portrait }
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
        
        output.isDoorBeingOpened
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    isLoading ? self?.openButton.showLoading() : self?.openButton.hideLoading()
                }
            )
            .disposed(by: disposeBag)
        
        fullscreenButton.rx.tap
            .subscribe(
                onNext: {
                    NotificationCenter.default.post(name: .incomingCallForceLandscape, object: nil)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func applyState(_ state: IncomingCallStateContainer, hasImage: Bool) {
        let callState = state.callState
        let previewState = state.previewState
        let doorState = state.doorState
        let videoState = state.videoState
        let soundOutputState = state.soundOutputState
        
        view.isUserInteractionEnabled = callState != .callFinished
        
        // Buttons visibility
        previewButton.isSelected = previewState == .video && doorState == .notDetermined
        callButton.isSelected = (callState == .establishingConnection || callState == .callActive) && doorState == .notDetermined
        speakerButton.isSelected = soundOutputState == .speaker
        
        let shouldShowVideo = (callState == .callActive || callState == .callReceived) && previewState == .video
        videoBackgroundBlur.isHidden = !shouldShowVideo
        
        // Video preview and WebRTC view logic
        let isWebRTC = videoState == .webrtc
        let isInband = videoState == .inband
        let isNotWebRTCAndNotInband = !isWebRTC && !isInband
        videoPreview.isHidden = !shouldShowVideo || (!isInband && isWebRTC)
        webRTCView.isHidden = !shouldShowVideo || (isInband && !isWebRTC)
        
        // Image view visibility
        imageView.isHidden = !(previewState == .staticImage || isNotWebRTCAndNotInband)
        imageViewActivityIndicator.isHidden = shouldShowVideo || hasImage
        
        // Button containers visibility
        callButtonContainer.isHidden = [.callActive, .callFinished].contains(callState)
        speakerButtonContainer.isHidden = [.callReceived, .establishingConnection].contains(callState)
        
        alreadyOpenedButtonContainer.isHidden = doorState != .opened
        openButtonContainer.isHidden = doorState == .opened
        ignoreButtonContainer.isHidden = doorState == .opened
        
        switch (state.callState, state.previewState) {
        case (.callReceived, .staticImage):
            titleLabel.text = L10n.Intercom.Incoming.title
            ignoreButtonLabel.text = L10n.Common.ignore
            previewButtonLabel.text = L10n.Intercom.Incoming.peepholeAction
            
        case (.callReceived, .video):
            titleLabel.text = L10n.Intercom.Incoming.peepholeOnStatus
            ignoreButtonLabel.text = L10n.Common.ignore
            previewButtonLabel.text = L10n.Intercom.Incoming.peepholeAction
            
        case (.establishingConnection, _):
            titleLabel.text = L10n.Intercom.Incoming.connectingStatus
            ignoreButtonLabel.text = L10n.Intercom.Incoming.declineAction
            previewButtonLabel.text = L10n.Intercom.Incoming.videoAction
            
        case (.callActive, _):
            titleLabel.text = L10n.Intercom.Incoming.conversationStatus
            ignoreButtonLabel.text = L10n.Intercom.Incoming.declineAction
            previewButtonLabel.text = L10n.Intercom.Incoming.videoAction
            
        case (.callFinished, _):
            titleLabel.text = L10n.Intercom.Incoming.callCompletedStatus
        }
    }

}
