//
//  ModalViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 01.09.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import XCoordinator

/// перечень xib файлов, с содержимым модальных окон
enum ModalContent: String {
    case aboutWhiteRabbit = "WhiteRabbitModalViewContent"
    case aboutWaitingGuests = "WaitingGuestModalViewContent"
    case aboutVideoEvent = "VideoEventModalViewContent"
    case aboutCallKit = "CallKitModalViewContent"
    case aboutAddressOrder = "AddressOrderModalViewContent"
}

/// чтобы не делать 100500 классов для очень похожих модальных окошек с крестиком в правом верхнем углу,
/// я решил сделать один общий класс,
/// который в инициализаторе принимает название файла с содержимым
final class ModalViewController: BaseViewController {
    
    @IBOutlet private weak var cancelButton: CircleIconControl!
    @IBOutlet private weak var containerView: UIView!
    private let content: ModalContent
    private let contentView: UIView
    
    init (dismissCallback: (@escaping () -> Void), content: ModalContent) {
        
        let nib = Bundle.main.loadNibNamed(content.rawValue, owner: nil, options: nil)
        self.content = content
        self.contentView = nib?.first as? UIView ?? UIView()
        let dismissGesture = UITapGestureRecognizer()
        super.init(nibName: nil, bundle: nil)

        dismissGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissGesture)
        
        Driver.merge(
            dismissGesture.rx.event.asDriver().mapToVoid(),
            cancelButton.rx.tap.asDriver()
        )
        .drive(
            onNext: { dismissCallback() }
        )
        .disposed(by: disposeBag)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelButton.style = .Close.blue
        self.containerView.addSubview(self.contentView)
        contentView.alignToView(containerView)
    }
}

final class AddressOrderModalViewContent: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var resetHintLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    private func configureUI() {
        titleLabel.text = L10n.Settings.Common.AddressOrder.title
        descriptionLabel.text = L10n.Settings.Common.AddressOrder.description
        resetHintLabel.text = L10n.Settings.Common.AddressOrder.resetHint
    }
}

final class CallKitModalViewContent: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    private func configureUI() {
        titleLabel.text = L10n.Settings.Common.CallKitInfo.title
        descriptionLabel.text = L10n.Settings.Common.CallKitInfo.description
    }
}

final class VideoEventModalViewContent: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var gesturesTitleLabel: UILabel!
    @IBOutlet private weak var swipeHintLabel: UILabel!
    @IBOutlet private weak var rewindHintLabel: UILabel!
    @IBOutlet private weak var forwardHintLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    private func configureUI() {
        titleLabel.text = L10n.History.VideoEventInfo.title
        descriptionLabel.text = L10n.History.VideoEventInfo.description
        gesturesTitleLabel.text = L10n.History.VideoEventInfo.gesturesTitle
        swipeHintLabel.text = L10n.History.VideoEventInfo.swipeGestureHint
        rewindHintLabel.text = L10n.History.VideoEventInfo.rewindGestureHint
        forwardHintLabel.text = L10n.History.VideoEventInfo.forwardGestureHint
    }
}

final class WaitingGuestModalViewContent: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var validityLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    private func configureUI() {
        titleLabel.text = L10n.Settings.AddressAccess.WaitingGuestInfo.title
        messageLabel.text = L10n.Settings.AddressAccess.WaitingGuestInfo.message
        validityLabel.text = L10n.Settings.AddressAccess.WaitingGuestInfo.validity
    }
}

final class WhiteRabbitModalViewContent: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var validityHintLabel: UILabel!
    @IBOutlet private weak var stepsTitleLabel: UILabel!
    @IBOutlet private weak var stepOneLabel: UILabel!
    @IBOutlet private weak var stepTwoLabel: UILabel!
    @IBOutlet private weak var stepThreeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    private func configureUI() {
        titleLabel.text = L10n.Settings.Address.WhiteRabbitInfo.title
        descriptionLabel.text = L10n.Settings.Address.WhiteRabbitInfo.description
        validityHintLabel.text = L10n.Settings.Address.WhiteRabbitInfo.validityHint
        stepsTitleLabel.text = L10n.Settings.Address.WhiteRabbitInfo.stepsTitle
        stepOneLabel.text = L10n.Settings.Address.WhiteRabbitInfo.step1
        stepTwoLabel.text = L10n.Settings.Address.WhiteRabbitInfo.step2
        stepThreeLabel.text = L10n.Settings.Address.WhiteRabbitInfo.step3
    }
}
