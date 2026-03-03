//
//  DetailGateAccessCell.swift
//  SmartYard
//
//  Created by Александр Попов on 22.07.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit
import RxRelay
import RxCocoa
import RxSwift

final class DetailGateAccessCell: UICollectionViewCell, HasDisposeBag {

    private enum CellType {
        case car
        case person
    }

    // MARK: - Reuse Identifier

    static let reuseIdentifier = "DetailGateAccessCell"

    // MARK: - Outlets

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var numberLabel: UILabel!
    @IBOutlet private weak var remainingTimeLabel: UILabel!
    @IBOutlet private weak var menuButton: UIButton!

    // MARK: - Properties

    let deleteButtonTappedRelay = PublishRelay<Void>()
    let smsButtonTappedRelay = PublishRelay<Void>()

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    // MARK: - Configuration

    func configure(with allowedCar: AllowedCar) {
        imageView.image = UIImage(named: "DefaultCarIcon")
        numberLabel.text = allowedCar.displayedNumber
        remainingTimeLabel.text = NSLocalizedString("unlimited", comment: "")
        remainingTimeLabel.textColor = .SmartYard.gray
        setupMenu(for: .car)
    }

    func configure(with personViewState: DetailGateAccessViewModel.PersonViewState) {
        let image = personViewState.person.logoImage ?? UIImage(named: "DefaultUserIcon")
        imageView.image = image
        numberLabel.text = personViewState.person.displayedNumber
        remainingTimeLabel.text = personViewState.remainingTimeText
        remainingTimeLabel.textColor = personViewState.isExpired
        ? .SmartYard.incorrectDataRed
        : .SmartYard.gray
        setupMenu(for: .person)
    }

    // MARK: - Actions
    
    private func setupMenu(for type: CellType) {
        if #available(iOS 14.0, *) {
            var actions: [UIAction] = []

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
                title: NSLocalizedString("Delete", comment: ""),
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.deleteButtonTappedRelay.accept(())
            }
            actions.append(deleteAction)

            let menu = UIMenu(title: "", children: actions)
            menuButton.menu = menu
            menuButton.showsMenuAsPrimaryAction = true
        } else {
            menuButton.rx.tap.bind(to: deleteButtonTappedRelay).disposed(by: disposeBag)
        }
    }

}
