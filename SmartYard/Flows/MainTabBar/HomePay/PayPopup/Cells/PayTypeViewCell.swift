//
//  PayTypeViewCell.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 08.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PayTypeViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var iconView: UIView!
    @IBOutlet private weak var iconImage: UIImageView!
    @IBOutlet private weak var iconLabel: UILabel!
    @IBOutlet private weak var stateMarker: RadioBoxView!
    @IBOutlet private weak var deleteButtonView: UIView!
    @IBOutlet private weak var deleteButton: UIButton!
    
    @IBOutlet private weak var leadingIconViewConstraint: NSLayoutConstraint!
    @IBOutlet private weak var trailingIconViewConstraint: NSLayoutConstraint!

    @IBAction private func deleteCardAction(_ sender: AnyObject) {
        guard let button = sender as? UIButton else {
            return
        }
        self.delegate?.didTapDeleteCard(for: self)
    }
    
    weak var delegate: PayTypeViewCellProtocol?

    private let leftPositionSubject = BehaviorSubject<CGFloat>(value: 0)

    private var isDeleteButtonActive: Bool = false
    var tapGesture: UILongPressGestureRecognizer?
    var payType: PayTypeObject?

    let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    private var dragPosition: CGFloat?
    private var leftPosition: CGFloat = 0

    @objc func handleLongGesture(_ gesture: UILongPressGestureRecognizer) {
        switch (gesture.state) {
        case .began:
            guard let pay = payType, pay.paymentWay == .CARD else {
                break
            }
            let gesturelocation = gesture.location(in: iconView)
            dragPosition = gesturelocation.x
            leftPosition = isDeleteButtonActive ? 72 : 0
        case .changed:
            guard let dragPosition = dragPosition else {
                break
            }
            var gesturelocation = gesture.location(in: iconView)
            gesturelocation.y = 0
            
            self.dragPosition = gesturelocation.x
            leftPosition += gesturelocation.x - dragPosition
            if leftPosition > 0, leftPosition < 90, !isDeleteButtonActive {
                leftPositionSubject.onNext(leftPosition)
            } else if leftPosition > 0, leftPosition < 90, isDeleteButtonActive {
                leftPositionSubject.onNext(leftPosition)
            }
        case .ended, .cancelled:
            dragPosition = nil
            if isDeleteButtonActive {
                if leftPosition < 36 {
                    leftPositionSubject.onNext(0)
                    isDeleteButtonActive = false
                } else {
                    leftPositionSubject.onNext(72)
                }
            } else {
                if leftPosition > 36 {
                    leftPositionSubject.onNext(72)
                    isDeleteButtonActive = true
                } else {
                    leftPositionSubject.onNext(0)
                }
            }
        default:
            dragPosition = nil
        }
    }

    func configureCell(
        payType: PayTypeObject,
        isDeletable: Bool = false
    ) {
        self.payType = payType
        iconLabel.text = payType.label
        iconImage.image = payType.paymentSystem.iconSelected
        iconLabel.textColor = payType.paymentSystem.labelSelectedColor
        iconView.layerBorderColor = payType.isSelected ? payType.paymentSystem.borderSelectedColor : payType.paymentSystem.borderUnselectedColor
        stateMarker.setState(state: payType.isSelected ? .checked : .unchecked)
        leftPositionSubject.onNext(0)
        isDeleteButtonActive = false
        if isDeletable {
            tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture(_:)))
            iconView.addGestureRecognizer(tapGesture!)
            tapGesture?.minimumPressDuration = 0.3
            deleteButtonView.isHidden = false
            leftPositionSubject.asDriverOnErrorJustComplete()
                .drive(
                    onNext: { [weak self] position in
                        guard let self = self else {
                            return
                        }
                        UIView.animate(
                            withDuration: 0.5,
                            animations: {
                                self.leadingIconViewConstraint.constant = position
                                self.trailingIconViewConstraint.constant = -position
                                if position > 0 {
                                    self.tapGesture?.minimumPressDuration = 0
                                } else {
                                    self.tapGesture?.minimumPressDuration = 0.3
                                }
                            }
                        )
                    }
                )
                .disposed(by: disposeBag)
        } else {
            iconView.removeGestureRecognizers()
            deleteButtonView.isHidden = true
        }
    }
}
