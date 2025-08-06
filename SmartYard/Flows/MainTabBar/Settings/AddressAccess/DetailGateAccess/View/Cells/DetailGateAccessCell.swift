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

final class DetailGateAccessCell: UICollectionViewCell {
    
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
    var disposeBag = DisposeBag()
    private var expireDate: Date?
    private var timerDisposeBag = DisposeBag()

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        timerDisposeBag = DisposeBag()
        remainingTimeLabel.text = nil
        expireDate = nil
    }

    // MARK: - Configuration

    func configure(with allowedCar: AllowedCar) {
        imageView.image = UIImage(named: "DefaultCarIcon")
        numberLabel.text = allowedCar.displayedNumber
        remainingTimeLabel.text = NSLocalizedString("unlimited", comment: "")
        setupMenu(for: .car)

    }

    func configure(with allowedPerson: AllowedPerson) {
        let image = allowedPerson.logoImage ?? UIImage(named: "DefaultUserIcon")
        imageView.image = image
        numberLabel.text = allowedPerson.displayedNumber
        setupMenu(for: .person)

        expireDate = allowedPerson.expire
        updateRemainingTime()
        startUpdatingTimer()
    }
    
    // MARK: - Private Methods

    private func updateRemainingTime() {
        remainingTimeLabel.text = formattedTimeLeft(until: expireDate)
    }

    private func startUpdatingTimer() {
        guard expireDate != nil else { return }

        Observable<Int>.interval(.seconds(60), scheduler: MainScheduler.instance)
            .startWith(0)
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }

                if let expire = self.expireDate, expire <= Date() {
                    self.remainingTimeLabel.text = NSLocalizedString("expired", comment: "")
                    self.remainingTimeLabel.textColor = .SmartYard.incorrectDataRed
                    self.timerDisposeBag = DisposeBag()
                } else {
                    self.updateRemainingTime()
                }
            })
            .disposed(by: timerDisposeBag)
    }

    private func formattedTimeLeft(until expireDate: Date?) -> String {
        guard let expireDate else {
            return ""
        }

        let now = Date()

        guard expireDate < now else {
            remainingTimeLabel.textColor = .SmartYard.incorrectDataRed
            return NSLocalizedString("expired", comment: "")
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .short
        formatter.maximumUnitCount = 1
        formatter.zeroFormattingBehavior = .dropAll
        formatter.calendar = Calendar.current
        formatter.calendar?.locale = Locale.current

        let timeString = formatter.string(from: now, to: expireDate) ?? ""
        let format = NSLocalizedString("TimeLeftFormat", comment: "")
        return String(format: format, timeString)
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
