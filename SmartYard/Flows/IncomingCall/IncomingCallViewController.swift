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
    
    let viewModel: IncomingCallViewModel
    
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
        previewButton.rx.tap
            .subscribe(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    let newState = !self.previewButton.isSelected
                    self.previewButton.isSelected = newState
                }
            )
            .disposed(by: disposeBag)
        
        callButton.rx.tap
            .subscribe(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    let newState = !self.callButton.isSelected
                    self.callButton.isSelected = newState
                }
            )
            .disposed(by: disposeBag)
        
//        rejectButton.rx.tap
//            .subscribe(
//                onNext: { [weak self] in
//                    self?.dismiss(animated: true, completion: nil)
//                }
//            )
//            .disposed(by: disposeBag)
//
//        let input = IncomingCallViewModel.Input(
//            acceptTrigger: acceptButton.rx.tap.asDriver(),
//            rejectTrigger: rejectButton.rx.tap.asDriver()
//        )
//
//        let output = viewModel.transform(input: input)
//
//        output.preview
//            .drive(liveImageView.rx.image)
//            .disposed(by: disposeBag)
    }
    
}

