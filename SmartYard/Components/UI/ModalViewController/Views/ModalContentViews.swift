//
//  ModalContentViews.swift
//  SmartYard
//

import UIKit
import SnapKit

// MARK: - AddressOrder

final class AddressOrderModalViewContent: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func configureUI() {
        backgroundColor = .SmartYard.grayBorder

        let titleLabel = UILabel.make(.modalTitle, text: L10n.Settings.Common.AddressOrder.title)
        let descriptionLabel = UILabel.make(.modalBody, text: L10n.Settings.Common.AddressOrder.description)
        let resetHintLabel = UILabel.make(.modalBodySemibold, text: L10n.Settings.Common.AddressOrder.resetHint)

        let stackView = UIStackView.vertical(spacing: 10).add {
            titleLabel
            descriptionLabel
            resetHintLabel
        }

        pinSubview(stackView, with: .init(inset: 24))
    }
}

final class CallKitModalViewContent: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func configureUI() {
        backgroundColor = .SmartYard.grayBorder

        let titleLabel = UILabel.make(.modalTitle, text: L10n.Settings.Common.CallKitInfo.title)
        let descriptionLabel = UILabel.make(.modalBody, text: L10n.Settings.Common.CallKitInfo.description)

        let stackView = UIStackView.vertical(spacing: 10).add {
            titleLabel
            descriptionLabel
        }

        pinSubview(stackView, with: .init(inset: 24))
    }
}

final class VideoEventModalViewContent: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func configureUI() {
        backgroundColor = .SmartYard.grayBorder

        let titleLabel = UILabel.make(.modalTitle, text: L10n.History.VideoEventInfo.title)
        let descriptionLabel = UILabel.make(.modalBody, text: L10n.History.VideoEventInfo.description)
        let gesturesTitleLabel = UILabel.make(.modalBody, text: L10n.History.VideoEventInfo.gesturesTitle)
        let swipeHintView = ModalBulletRowView(text: L10n.History.VideoEventInfo.swipeGestureHint)
        let rewindHintView = ModalBulletRowView(text: L10n.History.VideoEventInfo.rewindGestureHint)
        let forwardHintView = ModalBulletRowView(text: L10n.History.VideoEventInfo.forwardGestureHint)

        let stackView = UIStackView.vertical(spacing: 10).add {
            titleLabel
            descriptionLabel
            gesturesTitleLabel
            swipeHintView
            rewindHintView
            forwardHintView
        }

        pinSubview(stackView, with: .init(inset: 24))
    }
}

// MARK: - WaitingGuest

final class WaitingGuestModalViewContent: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func configureUI() {
        backgroundColor = .SmartYard.grayBorder

        let titleLabel = UILabel.make(.modalTitle, text: L10n.Settings.AddressAccess.WaitingGuestInfo.title)
        let messageLabel = UILabel.make(.modalBody, text: L10n.Settings.AddressAccess.WaitingGuestInfo.message)
        let validityLabel = UILabel.make(.modalBodySemibold, text: L10n.Settings.AddressAccess.WaitingGuestInfo.validity)

        let stackView = UIStackView.vertical(spacing: 10).add {
            titleLabel
            messageLabel
        }

        pinSubview(stackView, with: .init(inset: 24))
    }
}

// MARK: - WhiteRabbit

final class WhiteRabbitModalViewContent: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func configureUI() {
        backgroundColor = .SmartYard.grayBorder

        let titleLabel = UILabel.make(.modalTitle, text: L10n.Settings.Address.WhiteRabbitInfo.title)
        let descriptionLabel = UILabel.make(.modalBody, text: L10n.Settings.Address.WhiteRabbitInfo.description)
        let validityHintLabel = UILabel.make(.modalBodySemibold, text: L10n.Settings.Address.WhiteRabbitInfo.validityHint)
        let stepsTitleLabel = UILabel.make(.modalBody, text: L10n.Settings.Address.WhiteRabbitInfo.stepsTitle)
        let stepOneView = ModalBulletRowView(text: L10n.Settings.Address.WhiteRabbitInfo.step1)
        let stepTwoView = ModalBulletRowView(text: L10n.Settings.Address.WhiteRabbitInfo.step2)
        let stepThreeView = ModalBulletRowView(text: L10n.Settings.Address.WhiteRabbitInfo.step3)

        let stackView = UIStackView.vertical(spacing: 10).add {
            titleLabel
            descriptionLabel
            stepsTitleLabel
            stepOneView
            stepTwoView
            stepThreeView
            validityHintLabel
        }

        pinSubview(stackView, with: .init(inset: 24))
    }
}

// MARK: - BulletRow

private final class ModalBulletRowView: UIView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }

    init(text: String) {
        super.init(frame: .zero)
        configureUI(text: text)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func configureUI(text: String) {
        let label = UILabel.make(.modalBody, text: text)
        let dotView: UIView = {
            if let image = UIImage(named: "blueDot") {
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                return imageView
            }

            let view = UIView()
            view.backgroundColor = .SmartYard.blue
            view.layer.cornerRadius = 2
            return view
        }()

        addSubview(label) { make in
            make.top.bottom.trailing.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }

        addSubview(dotView) { make in
            make.leading.equalToSuperview()
            make.top.equalTo(label.snp.top).offset(9)
            make.width.height.equalTo(4)
        }
    }
}

// MARK: - Extension

private extension LabelConfig {
    static let modalTitle = LabelConfig(
        font: .SourceSansPro.bold(size: 28),
        color: .SmartYard.semiBlack,
        alignment: .center,
        numberOfLines: 0,
        lineBreakMode: .byWordWrapping,
        adjustsFontSizeToFitWidth: false,
        minimumScaleFactor: 0
    )

    static let modalBody = LabelConfig(
        font: .SourceSansPro.regular(size: 14),
        color: .SmartYard.semiBlack,
        alignment: .left,
        numberOfLines: 0,
        lineBreakMode: .byWordWrapping,
        adjustsFontSizeToFitWidth: false,
        minimumScaleFactor: 0
    )

    static let modalBodySemibold = LabelConfig(
        font: .SourceSansPro.semibold(size: 14),
        color: .SmartYard.semiBlack,
        alignment: .left,
        numberOfLines: 0,
        lineBreakMode: .byWordWrapping,
        adjustsFontSizeToFitWidth: false,
        minimumScaleFactor: 0
    )
}
