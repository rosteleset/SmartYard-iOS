//
//  AddressDeletionViewController.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import TouchAreaInsets

class AddressDeletionViewController: BaseViewController {
    
    @IBOutlet private weak var dontWantToManageFromAppContainer: UIView!
    @IBOutlet private weak var dontWantToManageFromAppCheckbox: SmartYardCheckBoxView!
    
    @IBOutlet private weak var wantToBreakTheContractContainer: UIView!
    @IBOutlet private weak var wantToBreakTheContractCheckbox: SmartYardCheckBoxView!
    
    @IBOutlet private weak var otherReasonContainer: UIView!
    @IBOutlet private weak var otherReasonCheckbox: SmartYardCheckBoxView!
    
    @IBOutlet private weak var deleteButton: BlueButton!
    @IBOutlet private weak var cancelButton: UIButton!
    
    private let viewModel: AddressDeletionViewModel
    
    init(viewModel: AddressDeletionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        bind()
    }
    
    private func bind() {
        let dontWantToManageFromAppGesture = UITapGestureRecognizer()
        dontWantToManageFromAppContainer.addGestureRecognizer(dontWantToManageFromAppGesture)
        
        let wantToBreakTheContractGesture = UITapGestureRecognizer()
        wantToBreakTheContractContainer.addGestureRecognizer(wantToBreakTheContractGesture)
        
        let otherReasonGesture = UITapGestureRecognizer()
        otherReasonContainer.addGestureRecognizer(otherReasonGesture)
        
        let deletionReason = Observable<AddressDeletionReason>
            .merge(
                dontWantToManageFromAppGesture.rx.event.map { _ in .dontWantToManageFromApp },
                wantToBreakTheContractGesture.rx.event.map { _ in .wantToBreakTheContract },
                otherReasonGesture.rx.event.map { _ in .other },
                .just(.dontWantToManageFromApp)
            )
            .asDriverOnErrorJustComplete()
            .distinctUntilChanged()
            .debug()
            .do(
                onNext: { [weak self] reason in
                    self?.selectReason(reason)
                }
            )
        
        let input = AddressDeletionViewModel.Input(
            cancelTrigger: cancelButton.rx.tap.asDriver(),
            deleteTrigger: deleteButton.rx.tap.asDriver(),
            deletionReason: deletionReason,
            customDescription: .just("test")
        )
        
        _ = viewModel.transform(input)
    }
    
    private func configureView() {
        selectReason(.dontWantToManageFromApp)
        
        cancelButton.touchAreaInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
    
    private func selectReason(_ reason: AddressDeletionReason) {
        [dontWantToManageFromAppCheckbox, wantToBreakTheContractCheckbox, otherReasonCheckbox].forEach {
            $0?.setState(state: .uncheckedInactive)
        }
        
        switch reason {
        case .dontWantToManageFromApp:
            dontWantToManageFromAppCheckbox.setState(state: .checkedActive)
        case .wantToBreakTheContract:
            wantToBreakTheContractCheckbox.setState(state: .checkedActive)
        case .other:
            otherReasonCheckbox.setState(state: .checkedActive)
        }
    }
    
}
