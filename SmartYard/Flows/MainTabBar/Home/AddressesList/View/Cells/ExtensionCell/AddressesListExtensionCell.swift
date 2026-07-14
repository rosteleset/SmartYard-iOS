//
//  AddressesListExtensionCell.swift
//  SmartYard
//
//  Created by Александр Попов on 14.07.2026.
//

import UIKit

// TODO: Разделить строки карточки адреса на AddressesListDisclosureCell
// для камер, событий и расширений и AddressesListObjectCell для объектов с действием «Открыть».
final class AddressesListExtensionCell: CustomBorderCollectionViewCell {

    private let iconImageView = UIImageView()
    private let captionLabel = UILabel()
    private let highlightView = UIView()
    private let arrowImageView = UIImageView(image: UIImage(named: "RightArrowIcon"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(caption: String, icon: UIImage?, isHighlighted: Bool) {
        captionLabel.text = caption
        iconImageView.image = icon
        highlightView.isHidden = !isHighlighted
    }
}

private extension AddressesListExtensionCell {
    func configureUI() {
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup UI

    func setupUI() {
        backgroundColor = .SmartYard.secondBackgroundColor
        contentView.backgroundColor = .clear

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true

        captionLabel.font = UIFont.SourceSansPro.semibold(size: 18)
        captionLabel.textColor = .SmartYard.semiBlack
        captionLabel.numberOfLines = 1

        highlightView.backgroundColor = .SmartYard.incorrectDataRed
        highlightView.layer.cornerRadius = 4
        highlightView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        highlightView.heightAnchor.constraint(equalToConstant: 8).isActive = true

        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.tintColor = UIColor.SmartYard.gray.withAlphaComponent(0.5)
        arrowImageView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        arrowImageView.heightAnchor.constraint(equalToConstant: 13).isActive = true
    }

    // MARK: - Setup Constraints

    func setupConstraints() {
        let titleStackView = UIStackView.horizontal(spacing: 8, alignment: .center).add {
            captionLabel
            highlightView
        }

        let contentStackView = UIStackView.horizontal(spacing: 15, alignment: .center).add {
            iconImageView
            titleStackView
            HSpacer()
            arrowImageView
        }

        contentView.addSubview(contentStackView) { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.centerY.equalToSuperview()
        }
    }
}
