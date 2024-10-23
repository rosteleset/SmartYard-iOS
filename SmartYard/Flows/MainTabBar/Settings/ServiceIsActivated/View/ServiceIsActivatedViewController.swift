//
//  ServiceIsActivatedViewController.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD

final class ServiceIsActivatedViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var changePlanButton: BlueButton!
    @IBOutlet private weak var backgroundView: UIView!
    
    private let viewModel: ServiceIsActivatedViewModel
    
    var loader: JGProgressHUD?
    
    init(viewModel: ServiceIsActivatedViewModel) {
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
    
    private func configureView() {
        closeButton.setImage(UIImage(named: "CloseIcon"), for: .normal)
        closeButton.setImage(UIImage(named: "CloseIcon")?.darkened(), for: .highlighted)
    }
    
    private func bind() {
        let dismissGesture = UITapGestureRecognizer()
        dismissGesture.cancelsTouchesInView = false
        backgroundView.addGestureRecognizer(dismissGesture)
        
        let dismissTrigger = Driver.merge(
            dismissGesture.rx.event.asDriver().mapToVoid(),
            closeButton.rx.tap.asDriver()
        )
        
        let input = ServiceIsActivatedViewModel.Input(
            dismissTrigger: dismissTrigger,
            changePlanTrigger: changePlanButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.service
            .drive(
                onNext: { [weak self] service in
                    let text = String.localizedStringWithFormat(
                        NSLocalizedString("Service \"%@\" is connected", comment: ""),
                        "\(service.localizedTitle)"
                    )
                    self?.titleLabel.text = text
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.view.endEditing(true)
                    }
                    let text = NSLocalizedString("Create a request", comment: "")
                    self?.updateLoader(isEnabled: isLoading, detailText: text)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
