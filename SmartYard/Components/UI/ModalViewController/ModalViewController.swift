//
//  ModalViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 01.09.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import SnapKit
import RxCocoa
import RxSwift

/// Контент модального экрана и его кодовая фабрика.
enum ModalContent {
    case aboutWhiteRabbit
    case aboutWaitingGuests
    case aboutVideoEvent
    case aboutCallKit
    case aboutAddressOrder

    func makeView() -> UIView {
        switch self {
        case .aboutWhiteRabbit:
            return WhiteRabbitModalViewContent()
        case .aboutWaitingGuests:
            return WaitingGuestModalViewContent()
        case .aboutVideoEvent:
            return VideoEventModalViewContent()
        case .aboutCallKit:
            return CallKitModalViewContent()
        case .aboutAddressOrder:
            return AddressOrderModalViewContent()
        }
    }
}

final class ModalViewController: BaseViewController {

    private let dismissCallback: () -> Void
    private let contentView: UIView

    private lazy var dismissGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.cancelsTouchesInView = false
        return gesture
    }()

    private let cancelButton = CircleIconControl(style: .Close.blue)

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .SmartYard.secondBackgroundColor
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    init(dismissCallback: @escaping () -> Void, content: ModalContent) {
        self.dismissCallback = dismissCallback
        self.contentView = content.makeView()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bindActions()
    }

    private func configureUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addGestureRecognizer(dismissGesture)

        view.addSubview(containerView) { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(5)
            make.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-16)
            make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(44)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-16)
            make.width.greaterThanOrEqualTo(100)
            make.height.greaterThanOrEqualTo(100)
        }

        view.addSubview(cancelButton) { make in
            make.width.height.equalTo(28)
            make.bottom.equalTo(containerView.snp.top).offset(-8)
            make.trailing.equalTo(containerView.snp.trailing).offset(-4)
        }

        containerView.pinSubview(contentView)
    }

    private func bindActions() {
        Driver.merge(
            dismissGesture.rx.event.asDriver().mapToVoid(),
            cancelButton.rx.tap.asDriver()
        )
        .drive(onNext: { [dismissCallback] in
            dismissCallback()
        })
        .disposed(by: disposeBag)
    }
}
