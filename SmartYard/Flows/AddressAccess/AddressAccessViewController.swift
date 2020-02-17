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
        configureViews()
        bind()
    }
    
    private func configureViews() {
        print("Set view models!!!")
//        temporaryAccessView.viewModel = AccessViewModel()
//        permanentAccessView.viewModel = AccessViewModel()
    }
    
    private func bind() {
        let input = AddressAccessViewModel.Input(
            viewDidAppearTrigger: rx.viewDidAppear.asDriverOnErrorJustComplete(),
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
                    self?.permanentAccessView.viewModel.personsItemsSubject.onNext(contacts)
                }
            )
            .disposed(by: disposeBag)
        
        output.tempAccessContacts
            .drive(
                onNext: { [weak self] contacts in
                    self?.temporaryAccessView.viewModel.updateData(data: contacts)
                }
            )
            .disposed(by: disposeBag)
    }

}
