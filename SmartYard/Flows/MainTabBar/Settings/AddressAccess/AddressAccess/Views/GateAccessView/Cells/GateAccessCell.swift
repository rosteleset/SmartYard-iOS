//
//  GateAccessCell.swift
//  SmartYard
//
//  Created by Александр Попов on 06.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit
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
    
    let deleteButtonTappedRelay = PublishRelay<Void>()
    let smsButtonTappedRelay = PublishRelay<Void>()
    
    
    // MARK: - Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resetDisposeBag()
    }
    
    // MARK: - Configuration
    
    func configure(with allowedCar: AllowedCar) {
        imageView.image = UIImage(named: "DefaultCarIcon")
        numberLabel.text = allowedCar.displayedNumber
        setupMenu(for: .car)
    }

    func configure(with allowedPerson: AllowedPerson) {
        imageView.image = UIImage(named: "DefaultUserIcon")
        numberLabel.text = allowedPerson.displayedNumber
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
            // Для старых iOS — оставить delete на tap
            menuButton.rx.tap.bind(to: deleteButtonTappedRelay).disposed(by: disposeBag)
        }
    }

}
