//
//  AddressConfirmationViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import JGProgressHUD

final class AddressConfirmationViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var headerView: HeaderView!
    @IBOutlet private weak var segmentControlContainerView: UIView!
    @IBOutlet private weak var officeView: ServiceFromOfficeView!
    @IBOutlet private weak var courierView: ServiceFromCourierView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!

    var loader: JGProgressHUD?

    private let viewModel: AddressConfirmationViewModel

    init(viewModel: AddressConfirmationViewModel) {
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

    private func configureUI() {
        headerView.setText(
            L10n.Address.Confirmation.title,
            subtitle: L10n.Address.Confirmation.subtitle
        )
    }

    private func updateUI(with config: DeliveryTabsConfig) {
        segmentControlContainerView.isHidden = !config.layoutVisible

        let segmentControlView: (UIView & SmartYardSegmentControlViewProtocol)
        if #available (iOS 26.0, *) {
            segmentControlView = SmartYardSegmentControlView()
        } else {
            segmentControlView = SmartYardUnderlineSegmentedControlView()
        }

        var titles: [String] = []
        config.visibleTabs.forEach { titles.append($0.title) }
        segmentControlView.titles = titles

        segmentControlView.translatesAutoresizingMaskIntoConstraints = false
        segmentControlContainerView.addSubview(segmentControlView)
        segmentControlView.alignToView(segmentControlContainerView)

        segmentControlView.segmentControl.rx.selectedSegmentIndex.asDriver()
            .drive(
                onNext: { [weak self] index in
                    self?.applyTab(index: index)
                }
            )
            .disposed(by: disposeBag)
    }

    private func applyTab(index: Int) {
        let isCourier = (index == 0)
        courierView.isHidden = !isCourier
        officeView.isHidden = isCourier
    }

    private func bind() {
        let input = AddressConfirmationViewModel.Input(
            confirmByCourierTapped: courierView.rx.requestButtonTapped.asDriverOnErrorJustComplete(),
            confirmInOfficeTrigger: officeView.rx.doSoButtonTapped.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)

        output.offices
            .drive(
                onNext: { [weak self] offices in
                    self?.officeView.setOffices(offices: offices)
                }
            )
            .disposed(by: disposeBag)

        output.deliveryTabsConfig
            .drive(
                onNext: { [weak self] config in
                    self?.updateUI(with: config)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
