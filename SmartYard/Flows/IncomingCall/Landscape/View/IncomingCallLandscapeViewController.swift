//
//  IncomingCallLandscapeViewController.swift
//  SmartYard
//
//  Created by admin on 27.07.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class IncomingCallLandscapeViewController: BaseViewController {
    
    @IBOutlet private weak var previewButton: UIButton!
    @IBOutlet private weak var callButton: UIButton!
    @IBOutlet private weak var ignoreButton: UIButton!
    @IBOutlet private weak var openButton: LoadingButton!
    @IBOutlet private weak var alreadyOpenedButton: UIButton!
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageViewActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var videoPreview: UIView!
    @IBOutlet private weak var videoBackgroundBlur: UIView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    
    @IBOutlet private weak var exitFullscreenButton: UIButton!
    
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
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    private func configureButtons() {
        previewButton.setImage(UIImage(named: "PreviewUnselectedIcon"), for: .normal)
        previewButton.setImage(UIImage(named: "PreviewUnselectedIcon")?.darkened(), for: [.normal, .highlighted])
        previewButton.setImage(UIImage(named: "PreviewSelectedIcon"), for: .selected)
        previewButton.setImage(UIImage(named: "PreviewSelectedIcon")?.darkened(), for: [.selected, .highlighted])
        
        callButton.setImage(UIImage(named: "CallUnselectedIcon"), for: .normal)
        callButton.setImage(UIImage(named: "CallUnselectedIcon")?.darkened(), for: [.normal, .highlighted])
        callButton.setImage(UIImage(named: "CallSelectedIcon"), for: .selected)
        callButton.setImage(UIImage(named: "CallSelectedIcon")?.darkened(), for: [.selected, .highlighted])
        
        openButton.setImage(UIImage(named: "UnlockIcon"), for: .normal)
        
        let imageForDisabled = UIImage(color: UIColor(hex: 0x4CD964)!, size: CGSize(width: 100, height: 100))
            .withRoundedCorners(radius: 50)
        
        openButton.setImage(imageForDisabled, for: .disabled)
    }
    
    // swiftlint:disable:next function_body_length
    private func bind() {
        let callTrigger = callButton.rx.tap
            .do(
                onNext: { [weak self] _ in
                    self?.imageViewActivityIndicator.stopAnimating()
                }
            )

        let input = IncomingCallViewModel.Input(
            previewTrigger: previewButton.rx.tap.asDriver(),
            callTrigger: callTrigger.asDriverOnErrorJustComplete(),
            videoViewsTrigger: .just((videoPreview, UIView())),
            ignoreTrigger: ignoreButton.rx.tap.asDriver(),
            openTrigger: openButton.rx.tap.asDriver()
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
            .drive(
                onNext: { [weak self] state in
                    self?.applyState(state)
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
    }
    
    private func applyState(_ state: IncomingCallStateContainer) {
        view.isUserInteractionEnabled = state.callState != .callFinished
        
        previewButton.isSelected = state.previewState == .video && state.doorState == .notDetermined
        callButton.isSelected = (state.callState == .establishingConnection || state.callState == .callActive)
            && state.doorState == .notDetermined
        
        let shouldShowVideo = state.callState == .callActive && state.previewState == .video
        
        videoBackgroundBlur.isHidden = !shouldShowVideo
        videoPreview.isHidden = !shouldShowVideo
        
        imageView.isHidden = shouldShowVideo
        imageViewActivityIndicator.isHidden = shouldShowVideo
        
        alreadyOpenedButton.isHidden = state.doorState != .opened
        openButton.isHidden = state.doorState == .opened
        ignoreButton.isHidden = state.doorState == .opened
        
        switch (state.callState, state.previewState) {
        case (.callReceived, .staticImage):
            titleLabel.text = "Звонок в домофон"
            
        case (.callReceived, .video):
            titleLabel.text = "Глазок включен"
            
        case (.establishingConnection, _):
            titleLabel.text = "Соединение..."
            
        case (.callActive, _):
            titleLabel.text = "Разговор"
            
        case (.callFinished, _):
            titleLabel.text = "Звонок завершен"
        }
    }

}
