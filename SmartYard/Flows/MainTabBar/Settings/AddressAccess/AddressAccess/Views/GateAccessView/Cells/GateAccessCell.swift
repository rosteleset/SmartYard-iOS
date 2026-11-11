//
//  GateAccessCell.swift
//  SmartYard
//
//  Created by Александр Попов on 06.06.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
//

import UIKit
import SnapKit
import RxRelay
import RxCocoa
import RxSwift

final class GateAccessCell: UICollectionViewCell, HasDisposeBag {
    
    private enum CellType {
        case car
        case person
    }
    
    // MARK: - Reuse Identifier
    
    static let reuseIdentifier = "GateAccessCell"
    
    // MARK: - Outlets
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var menuButton: UIButton!
    @IBOutlet private weak var numberLabel: UILabel!
    
    // MARK: - Properties
    
    private let trackingBadge = UIImageView(image: UIImage(systemName: "eye.fill"))
    let editButtonTappedRelay = PublishRelay<Void>()
    let deleteButtonTappedRelay = PublishRelay<Void>()
    let smsButtonTappedRelay = PublishRelay<Void>()
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupConstraints()
    }

    private func setupUI() {
        trackingBadge.tintColor = .SmartYard.blue
        trackingBadge.backgroundColor = .SmartYard.secondBackgroundColor
        trackingBadge.layer.cornerRadius = 7
        trackingBadge.contentMode = .scaleAspectFit
        trackingBadge.isHidden = true
        imageView.clipsToBounds = false
    }

    private func setupConstraints() {
        imageView.addSubview(trackingBadge) { make in
            make.size.equalTo(14)
            make.trailing.bottom.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetDisposeBag()
    }
    
    // MARK: - Configuration
    
    func configure(with allowedCar: AllowedCar) {
        imageView.image = UIImage(named: "DefaultCarIcon")
        numberLabel.text = allowedCar.displayedNumber
        trackingBadge.isHidden = allowedCar.watcherId == nil
        numberLabel.textColor = allowedCar.isExpired ? .SmartYard.incorrectDataRed : .SmartYard.semiBlack
        accessibilityValue = allowedCar.validityDescription(
            timeZone: TimeZone(identifier: AccessService.shared.timeZone) ?? .current
        )
        setupMenu(for: .car)
    }

    func configure(with allowedPerson: AllowedPerson) {
        trackingBadge.isHidden = true
        accessibilityValue = nil
        numberLabel.textColor = .SmartYard.semiBlack
        imageView.image = UIImage(named: "DefaultUserIcon")
        numberLabel.text = allowedPerson.displayedNumber
        setupMenu(for: .person)
    }
    
    // MARK: - Actions
    
    private func setupMenu(for type: CellType) {
        var actions: [UIAction] = []

        if type == .car && AccessService.shared.lprsVersion == .timed {
            actions.append(UIAction(
                title: L10n.Common.edit, image: UIImage(systemName: "pencil")
            ) { [weak self] _ in
                self?.editButtonTappedRelay.accept(())
            })
        }

        if type == .person {
            let smsAction = UIAction(
                title: "SMS",
                image: UIImage(systemName: "message")
            ) { [weak self] _ in
                self?.smsButtonTappedRelay.accept(())
            }
            actions.append(smsAction)
        }

        let deleteAction = UIAction(
            title: L10n.Common.delete,
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.deleteButtonTappedRelay.accept(())
        }
        actions.append(deleteAction)

        let menu = UIMenu(title: "", children: actions)
        menuButton.menu = menu
        menuButton.showsMenuAsPrimaryAction = true
    }

}
