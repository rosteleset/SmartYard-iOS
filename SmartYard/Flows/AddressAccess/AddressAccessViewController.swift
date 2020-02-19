//
//  AddressAccessViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class AddressAccessViewController: BaseViewController {

    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var intercomAccessView: IntercomTemporaryAccessView!
    @IBOutlet private weak var temporaryAccessView: AccessView!
    @IBOutlet private weak var permanentAccessView: AccessView!
    
    private let viewModel: AddressAccessViewModel
    
    private var tempAccessViewHeightConstraint: NSLayoutConstraint!
    private var permanentAccessViewHeightConstraint: NSLayoutConstraint!
    
    init(viewModel: AddressAccessViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let temporaryViewHeight = temporaryAccessView.heightAnchor.constraint(equalToConstant: 57)
        temporaryViewHeight.isActive = true
        tempAccessViewHeightConstraint = temporaryViewHeight
        
        let permanentViewHeight = permanentAccessView.heightAnchor.constraint(equalToConstant: 57)
        permanentViewHeight.isActive = true
        permanentAccessViewHeightConstraint = permanentViewHeight
        
        temporaryAccessView.translatesAutoresizingMaskIntoConstraints = false
        permanentAccessView.translatesAutoresizingMaskIntoConstraints = false
        
        bind()
    }
    
    private func bind() {
        let input = AddressAccessViewModel.Input(
            viewDidAppearTrigger: rx.viewWillAppear.asDriverOnErrorJustComplete(),
            refreshIntercomTempCodeTrigger: intercomAccessView.rx.refreshButtonTapped.asDriverOnErrorJustComplete(),
            openGuestAccessTrigger: intercomAccessView.rx.openButtonTapped.asDriverOnErrorJustComplete(),
            smsToTempContactTrigger: temporaryAccessView.sendSmsSubject.asDriverOnErrorJustComplete(),
            smsToPermanentContactTrigger: permanentAccessView.sendSmsSubject.asDriverOnErrorJustComplete(),
            deleteTempContactTrigger: temporaryAccessView.deletePressedSubject.asDriverOnErrorJustComplete(),
            deletePermanentContactTrigger: permanentAccessView.deletePressedSubject.asDriverOnErrorJustComplete(),
            addNewTempContact: temporaryAccessView.addNewPersonSubject.asDriverOnErrorJustComplete(),
            addNewPermanentContact: permanentAccessView.addNewPersonSubject.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input: input)
        
        output.objectAddress
            .drive(
                onNext: { [weak self] address in
                    self?.addressLabel.text = address
                }
            )
            .disposed(by: disposeBag)
        
        output.permanentAccessContacts
            .drive(
                onNext: { [weak self] contacts in
                    guard let self = self else {
                        return
                    }
                    
                    self.permanentAccessView.viewModel.updateData(data: contacts)
                    
                    let newHeight = self.calculateAccessViewHeight(countItems: contacts.count)
                    self.permanentAccessViewHeightConstraint.constant = newHeight
                    self.view.layoutIfNeeded()
                }
            )
            .disposed(by: disposeBag)
        
        output.tempAccessContacts
            .drive(
                onNext: { [weak self] contacts in
                    guard let self = self else {
                        return
                    }
                    
                    self.temporaryAccessView.viewModel.updateData(data: contacts)
                    
                    let newHeight = self.calculateAccessViewHeight(countItems: contacts.count)
                    self.tempAccessViewHeightConstraint.constant = newHeight
                    self.view.layoutIfNeeded()
                }
            )
            .disposed(by: disposeBag)
    }

    private func calculateAccessViewHeight(countItems: Int) -> CGFloat {
        let addContactCellHeight = 57
        let contactCellHeight = 64
        
        return CGFloat(contactCellHeight * countItems + addContactCellHeight)
    }
    
}
