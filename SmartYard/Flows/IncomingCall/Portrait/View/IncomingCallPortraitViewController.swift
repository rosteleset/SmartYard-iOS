//
//  IncomingCallViewController.swift
//  SmartYard
//
//  Created by admin on 04/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD
import AVKit

class IncomingCallPortraitViewController: BaseViewController {
    
    @IBOutlet private weak var previewButton: UIButton!
    @IBOutlet private weak var callButton: UIButton!
    @IBOutlet private weak var ignoreButton: UIButton!
    @IBOutlet private weak var openButton: LoadingButton!
    
    @IBOutlet private weak var alreadyOpenedButtonContainer: UIView!
    @IBOutlet private weak var openButtonContainer: UIView!
    @IBOutlet private weak var ignoreButtonContainer: UIView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var ignoreButtonLabel: UILabel!
    @IBOutlet private weak var previewButtonLabel: UILabel!
    
    @IBOutlet private weak var videoBackgroundBlur: UIView!
    @IBOutlet private weak var videoPreview: UIView!
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageViewActivityIndicator: UIActivityIndicatorView!
    
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
        configureButtons()
        bind()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // MARK: После ухода с экрана, меняем категорию AVAudioSession с разговора на просмотр видео
        // Не знаю, нужно ли, но по идее если мы зайдем на экран видео, а потом нам придет звонок - пропадет звук видео
        // Из-за того, что тип сессии поменялся с просмотра видео на разговор
        // Потом чекнем, нужно или нет
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let targetHeight: CGFloat = 720
        let scaleRatio = imageView.bounds.height / targetHeight + 0.001
        
        videoPreview.transform = CGAffineTransform(scaleX: scaleRatio, y: scaleRatio)
        videoPreview.cornerRadius = 24 / scaleRatio
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
        
        alreadyOpenedButtonContainer.isHidden = state.doorState != .opened
        openButtonContainer.isHidden = state.doorState == .opened
        ignoreButtonContainer.isHidden = state.doorState == .opened
        
        switch (state.callState, state.previewState) {
        case (.callReceived, .staticImage):
            titleLabel.text = "Звонок в домофон"
            ignoreButtonLabel.text = "Игнорировать"
            previewButtonLabel.text = "Глазок"
            
        case (.callReceived, .video):
            titleLabel.text = "Глазок включен"
            ignoreButtonLabel.text = "Игнорировать"
            previewButtonLabel.text = "Глазок"
            
        case (.establishingConnection, _):
            titleLabel.text = "Соединение..."
            ignoreButtonLabel.text = "Отклонить"
            previewButtonLabel.text = "Видео"
            
        case (.callActive, _):
            titleLabel.text = "Разговор"
            ignoreButtonLabel.text = "Отклонить"
            previewButtonLabel.text = "Видео"
            
        case (.callFinished, _):
            titleLabel.text = "Звонок завершен"
        }
    }
    
}
