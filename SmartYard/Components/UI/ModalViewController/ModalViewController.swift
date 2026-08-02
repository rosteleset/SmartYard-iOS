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
    case paranoid(ParanoidPushPayload)
    case whatsNew(WhatsNewRelease)

    var showsCloseButton: Bool {
        switch self {
        case .whatsNew:
            return false
        default:
            return true
        }
    }

    var usesReadableWidth: Bool {
        switch self {
        case .whatsNew:
            return true
        default:
            return false
        }
    }

    func makeView(dismissCallback: @escaping () -> Void) -> UIView {
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
        case let .paranoid(payload):
            return ParanoidPushModalViewContent(payload: payload)
        case let .whatsNew(release):
            return WhatsNewModalViewContent(
                release: release,
                dismissCallback: dismissCallback
            )
        }
    }
}

final class ModalViewController: BaseViewController, UIGestureRecognizerDelegate {

    private let dismissCallback: () -> Void
    private let contentView: UIView
    private let showsCloseButton: Bool
    private let usesReadableWidth: Bool

    private lazy var dismissGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
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
        self.showsCloseButton = content.showsCloseButton
        self.usesReadableWidth = content.usesReadableWidth
        self.contentView = content.makeView(dismissCallback: dismissCallback)
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
            make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide)
                .offset(showsCloseButton ? 44 : 16)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-16)

            if usesReadableWidth {
                make.leading.trailing.equalTo(view.readableContentGuide)
            } else {
                make.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(16)
                make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-16)
            }
        }

        if showsCloseButton {
            view.addSubview(cancelButton) { make in
                make.width.height.equalTo(28)
                make.bottom.equalTo(containerView.snp.top).offset(-8)
                make.trailing.equalTo(containerView.snp.trailing).offset(-4)
            }
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

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard gestureRecognizer === dismissGesture, let touchedView = touch.view else {
            return true
        }

        return !touchedView.isDescendant(of: containerView)
            && !touchedView.isDescendant(of: cancelButton)
    }
}
