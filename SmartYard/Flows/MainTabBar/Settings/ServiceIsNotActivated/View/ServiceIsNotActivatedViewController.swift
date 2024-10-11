//
//  ServiceIsNotActivatedViewController.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD

class ServiceIsNotActivatedViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var sendRequestButton: BlueButton!
    @IBOutlet private weak var backgroundView: UIView!
    
    private let viewModel: ServiceIsNotActivatedViewModel
    
    var loader: JGProgressHUD?
    
    init(viewModel: ServiceIsNotActivatedViewModel) {
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
        closeButton.setImage(UIImage(named: "closeIcon-1"), for: .normal)
        closeButton.setImage(UIImage(named: "closeIcon-1")?.darkened(), for: .highlighted)
    }
    
    private func bind() {
        let dismissGesture = UITapGestureRecognizer()
        dismissGesture.cancelsTouchesInView = false
        backgroundView.addGestureRecognizer(dismissGesture)
        
        let dismissTrigger = Driver.merge(
            dismissGesture.rx.event.asDriver().mapToVoid(),
            closeButton.rx.tap.asDriver()
        )
        
        let input = ServiceIsNotActivatedViewModel.Input(
            dismissTrigger: dismissTrigger,
            sendRequestTrigger: sendRequestButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.service
            .drive(
                onNext: { [weak self] service in
                    self?.titleLabel.text = "Услуга \"\(service.localizedTitle)\" не подключена"
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
                    
                    self?.updateLoader(isEnabled: isLoading, detailText: "Создание заявки")
                }
            )
            .disposed(by: disposeBag)
    }
    
}
