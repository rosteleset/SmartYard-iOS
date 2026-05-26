//
//  StoryItemCell.swift
//  SmartYard
//
//  Created by Александр Попов on 19.05.2026.
//

import UIKit
import SnapKit

final class StoryItemCell: UICollectionViewCell {

    private enum Layout {
        static let cornerRadius: CGFloat = 16
    }

    private let imageView = UIImageView()
    private let overlayView = LinearGradientView(frame: .zero)
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.setImageWithKF(from: nil)
        titleLabel.text = nil
    }

    func configure(with model: StoryItemCellModel) {
        titleLabel.text = model.title
        imageView.setImageWithKF(from: URL(string: model.imageUrl))
    }
}

private extension StoryItemCell {
    func configureUI() {
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup UI

    func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = Layout.cornerRadius
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.75).cgColor

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.18)

        overlayView.colors = [
            UIColor.black.withAlphaComponent(0),
            UIColor.black.withAlphaComponent(0.62)
        ]
        overlayView.gradientLayer.locations = [0.0, 1.0]

        titleLabel.font = UIFont.SourceSansPro.semibold(size: 13)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.82
    }

    // MARK: - Setup Constraints

    func setupConstraints() {
        contentView.pinSubview(imageView)
        contentView.pinSubview(overlayView)

        contentView.addSubview(titleLabel) { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(10)
        }
    }
}
