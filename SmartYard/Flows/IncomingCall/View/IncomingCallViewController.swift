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

class IncomingCallViewController: BaseViewController {
    
    @IBOutlet private weak var previewButton: UIButton!
    @IBOutlet private weak var callButton: UIButton!
    @IBOutlet private weak var ignoreButton: UIButton!
    @IBOutlet private weak var openButton: UIButton!
    
    @IBOutlet private weak var alreadyOpenedButtonContainer: UIView!
    @IBOutlet private weak var openButtonContainer: UIView!
    @IBOutlet private weak var ignoreButtonContainer: UIView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var ignoreButtonLabel: UILabel!
    
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
    
    private func configureButtons() {
        previewButton.setImage(UIImage(named: "PreviewUnselectedIcon"), for: .normal)
        previewButton.setImage(UIImage(named: "PreviewUnselectedIcon")?.darkened(), for: [.normal, .highlighted])
        previewButton.setImage(UIImage(named: "PreviewSelectedIcon"), for: .selected)
        previewButton.setImage(UIImage(named: "PreviewSelectedIcon")?.darkened(), for: [.selected, .highlighted])
        
        callButton.setImage(UIImage(named: "CallUnselectedIcon"), for: .normal)
        callButton.setImage(UIImage(named: "CallUnselectedIcon")?.darkened(), for: [.normal, .highlighted])
        callButton.setImage(UIImage(named: "CallSelectedIcon"), for: .selected)
        callButton.setImage(UIImage(named: "CallSelectedIcon")?.darkened(), for: [.selected, .highlighted])
    }
    
    private func bind() {
        let callTrigger = callButton.rx.tap
            .flatMap { [weak self] _ -> Driver<(UIView, UIView)> in
                guard let self = self else {
                    return .empty()
                }
                
                return .just((self.imageView, UIView()))
            }
            .do(
                onNext: { [weak self] _ in
                    self?.imageViewActivityIndicator.stopAnimating()
                }
            )
        
        let input = IncomingCallViewModel.Input(
            previewTrigger: previewButton.rx.tap.asDriver(),
            callTrigger: callTrigger.asDriverOnErrorJustComplete(),
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
                    guard let self = self else {
                        return
                    }
                    
                    let (callState, doorState) = state
                    
                    self.view.isUserInteractionEnabled = doorState == .notDetermined
                    self.previewButton.isSelected = callState == .callPreviewed && doorState == .notDetermined
                    self.callButton.isSelected = callState == .callAccepted && doorState == .notDetermined
                    
                    self.alreadyOpenedButtonContainer.isHidden = doorState != .opened
                    self.openButtonContainer.isHidden = doorState == .opened
                    self.ignoreButtonContainer.isHidden = doorState == .opened
                    
                    self.ignoreButtonLabel.text = callState == .callAccepted ? "Отклонить" : "Игнорировать"
                    
                    self.titleLabel.text = {
                        switch callState {
                        case .callReceived: return "Звонок в домофон"
                        case .callPreviewed: return "Глазок включен"
                        case .establishingConnection: return "Соединение..."
                        case .callAccepted: return "Разговор"
                        }
                    }()
                }
            )
            .disposed(by: disposeBag)
    }
    
}

