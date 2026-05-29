//
//  TrackedEventCell.swift
//  SmartYard
//
//  Created by Александр Попов on 29.05.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

final class TrackedEventCell: UITableViewCell {
    static let reuseIdentifier = String(describing: TrackedEventCell.self)

    private let cardView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let commentsLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        titleLabel.text = nil
        commentsLabel.text = nil
        commentsLabel.isHidden = true
    }

    func configure(with event: APITrackedEvent) {
        let comments = event.normalizedComments

        iconImageView.image = icon(for: event.eventType)
        titleLabel.text = ParanoidEventTracking.title(for: event.eventType)
        commentsLabel.text = comments
        commentsLabel.isHidden = comments.isEmpty
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cardView.addBorder(dynamicColor: .SmartYard.grayBorder)
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = .SmartYard.secondBackgroundColor
        cardView.layerCornerRadius = 12
        cardView.addBorder(dynamicColor: .SmartYard.grayBorder)

        iconImageView.contentMode = .scaleAspectFit

        titleLabel.font = .SourceSansPro.semibold(size: 16)
        titleLabel.textColor = .SmartYard.semiBlack
        titleLabel.numberOfLines = 0

        commentsLabel.font = .SourceSansPro.regular(size: 14)
        commentsLabel.textColor = .SmartYard.gray
        commentsLabel.numberOfLines = 0
        commentsLabel.isHidden = true
    }

    private func setupConstraints() {
        let textStackView = UIStackView.vertical(spacing: 2).add {
            titleLabel
            commentsLabel
        }

        let contentStackView = UIStackView.horizontal(spacing: 10, alignment: .top).add {
            iconImageView
            textStackView
        }

        contentView.pinSubview(cardView, with: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        cardView.pinSubview(contentStackView, with: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20))

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    private func icon(for eventType: Int) -> UIImage? {
        let imageName: String
        switch eventType {
        case APIPlog.EventType.rfid.rawValue:
            imageName = "LogsKey"
        case APIPlog.EventType.app.rawValue:
            imageName = "LogsApp"
        case APIPlog.EventType.passcode.rawValue:
            imageName = "LogsCode"
        case APIPlog.EventType.plate.rawValue:
            imageName = "LogsBarrier"
        default:
            imageName = "EventsIcon"
        }

        return UIImage(named: imageName)
    }
}
