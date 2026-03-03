//
//  LicencePlateKeyboardView.swift
//  SmartYard
//
//  Created by Александр Попов on 22.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit
import PMNibLinkableView
import RxSwift
import RxCocoa

final class LicencePlateKeyboardView: PMNibLinkableView {
    
    // MARK: - Outlets

    // swiftlint:disable private_outlet
    @IBOutlet private(set) var digitButtons: [UIButton]!
    @IBOutlet private(set) var letterButtons: [UIButton]!
    @IBOutlet private(set) weak var actionButton: UIButton!
    @IBOutlet private(set) weak var deleteButton: UIButton!
    @IBOutlet private(set) weak var countryButton: UIButton!
    // swiftlint:enable private_outlet
    
    // MARK: - Properties
    
    private var allButtons: [UIButton] {
        letterButtons + digitButtons + [deleteButton, actionButton]
    }
        
    var onDeletePressed: (() -> Void)?
    var onKeyPressed: ((String) -> Void)?
    
    private(set) var currentCountryMode: LicensePlateFormat = .russia
    private let topMenuAreaHeight: CGFloat = 42
    private let letterExtraHeight: CGFloat = 4
    private let baseKeyboardHeightRatio: CGFloat = 0.22
    private let maxDigitButtonHeight: CGFloat = 44
    
    override var intrinsicContentSize: CGSize {
        let screenHeight = UIScreen.main.bounds.height
        let baseHeight = screenHeight * baseKeyboardHeightRatio
        let baseDigitHeight = (baseHeight - (4 * 6)) / 3
        let preferredDigitHeight = min(baseDigitHeight, maxDigitButtonHeight)
        let requiredHeight = (4 * 6) + topMenuAreaHeight + (3 * preferredDigitHeight) + (2 * letterExtraHeight)
        
        return CGSize(
            width: UIScreen.main.bounds.width,
            height: max(baseHeight, requiredHeight)
        )
    }
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    // MARK: - Public Methods
    
    func setEnabledKeys(letters: Bool, digits: Bool) {
        letterButtons.forEach { button in
            button.isEnabled = letters
            
            UIView.animate(withDuration: 0.3) {
                button.backgroundColor = letters ? UIColor.SYKeyboard.keyColor : UIColor.SYKeyboard.keyColor.withAlphaComponent(0.4)
                button.setTitleColor(letters ? UIColor.SYKeyboard.textKeyColor : UIColor.SYKeyboard.textKeyColor.withAlphaComponent(0.4), for: .normal)
            }
        }
        
        digitButtons.forEach { button in
            button.isEnabled = digits
            
            UIView.animate(withDuration: 0.3) {
                button.backgroundColor = digits ? UIColor.SYKeyboard.keyColor : UIColor.SYKeyboard.keyColor.withAlphaComponent(0.4)
                button.setTitleColorForAllStates(digits ? UIColor.SYKeyboard.textKeyColor : UIColor.SYKeyboard.textKeyColor.withAlphaComponent(0.4))
            }
        }
    }
    
    func setShareButton(enabled: Bool) {
        actionButton.isEnabled = enabled
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.actionButton.backgroundColor = enabled ? .SmartYard.blue : UIColor.SYKeyboard.keyColor.withAlphaComponent(0.4)
            self?.actionButton.setTitleColorForAllStates(enabled ? UIColor.SYKeyboard.textKeyColor : UIColor.SYKeyboard.textKeyColor.withAlphaComponent(0.4))
        }
    }
    
    // MARK: - Actions
    
    @objc private func buttonTapped(_ sender: UIButton) {
        guard let text = sender.titleLabel?.text else {
            return
        }
        
        switch text {
        case "⌫": onDeletePressed?()
        default: onKeyPressed?(text)
        }
    }
    
}

// MARK: - Configuration

extension LicencePlateKeyboardView {
    
    private func setupUI() {
        let targetsButtons = digitButtons + letterButtons + [deleteButton]
        targetsButtons.forEach {
            $0?.addTarget(
                self,
                action: #selector(buttonTapped(_:)),
                for: .touchUpInside
            )
        }
        
        actionButton.setTitleColor(.SYKeyboard.textKeyColor, for: .disabled)
        actionButton.setTitleColor(.white, for: .normal)

        configureCountryButton()
        
        setShadow()
        setConstraints()
    }
    
    private func setShadow() {
        allButtons.forEach {
            $0.layer.shadowColor = UIColor.SYKeyboard.shadowKeyColor.cgColor
            $0.layer.shadowRadius = 6
            $0.layer.shadowOpacity = 1
            $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        }
        
        countryButton.layer.shadowColor = UIColor.SYKeyboard.shadowKeyColor.cgColor
        countryButton.layer.shadowRadius = 6
        countryButton.layer.shadowOpacity = 1
        countryButton.layer.shadowOffset = CGSize(width: 0, height: 2)
    }
    
    private func setConstraints() {
        let inset: CGFloat = 6
        let buttons: CGFloat = 8
        let rows: CGFloat = 3
        let availableHeight = intrinsicContentSize.height - (4 * inset) - topMenuAreaHeight
        let digitHeight = (availableHeight - (2 * letterExtraHeight)) / rows
        let letterHeight = digitHeight + letterExtraHeight
        let width = (intrinsicContentSize.width - (9 * inset)) / buttons
        
        digitButtons.forEach {
            $0.heightAnchor.constraint(equalToConstant: digitHeight).isActive = true
        }
        (letterButtons + [deleteButton, actionButton]).forEach {
            $0.heightAnchor.constraint(equalToConstant: letterHeight).isActive = true
        }
        letterButtons.forEach {
            $0.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
    }
    
    private func updateAppearance() {
        digitButtons.forEach {
            $0.backgroundColor = $0.isEnabled
                ? UIColor.SYKeyboard.keyColor
                : UIColor.SYKeyboard.keyColor.withAlphaComponent(0.4)
            $0.setTitleColorForAllStates($0.isEnabled
                ? UIColor.SYKeyboard.textKeyColor
                : UIColor.SYKeyboard.textKeyColor.withAlphaComponent(0.4))
        }
        
        letterButtons.forEach {
            $0.backgroundColor = $0.isEnabled
                ? UIColor.SYKeyboard.keyColor
                : UIColor.SYKeyboard.keyColor.withAlphaComponent(0.4)
            $0.setTitleColorForAllStates($0.isEnabled
                ? UIColor.SYKeyboard.textKeyColor
                : UIColor.SYKeyboard.textKeyColor.withAlphaComponent(0.4)
            )
        }

        actionButton.backgroundColor = actionButton.isEnabled
            ? .SmartYard.blue
            : UIColor.SYKeyboard.keyColor.withAlphaComponent(0.4)
        actionButton.setTitleColorForAllStates(actionButton.isEnabled
            ? UIColor.white
            : UIColor.SYKeyboard.textKeyColor.withAlphaComponent(0.4))
        countryButton.backgroundColor = UIColor.SYKeyboard.keyColor
        countryButton.setTitleColorForAllStates(UIColor.SYKeyboard.textKeyColor)
        
        allButtons.forEach {
            $0.layer.shadowColor = UIColor.SYKeyboard.shadowKeyColor.cgColor
        }
        
        countryButton.layer.shadowColor = UIColor.SYKeyboard.shadowKeyColor.cgColor

    }

    private func configureCountryButton() {
        countryButton.backgroundColor = UIColor.SYKeyboard.keyColor
        countryButton.setTitle("🇷🇺", for: .normal)
        countryButton.titleLabel?.font = .systemFont(ofSize: 20)
        countryButton.setTitleColorForAllStates(UIColor.SYKeyboard.textKeyColor)

        if #available(iOS 14.0, *) {
            let russianAction = UIAction(title: "Русский", state: .on) { [weak self] _ in
                self?.currentCountryMode = .russia
            }
            countryButton.menu = UIMenu(title: "", children: [russianAction])
            countryButton.showsMenuAsPrimaryAction = true
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
    }

}

// MARK: - Helpers

extension LicencePlateKeyboardView {
    
    static func loadFromNib() -> LicencePlateKeyboardView {
        let nib = UINib(nibName: "LicencePlateKeyboardView", bundle: .main)
        guard let view = nib.instantiate(withOwner: nil).first as? LicencePlateKeyboardView else {
            fatalError("Не удалось загрузить LicencePlateKeyboardView из XIB")
        }
        return view
    }
    
}

// MARK: - Reactive extensions

extension Reactive where Base: LicencePlateKeyboardView {
    
    var shareButtonTapped: ControlEvent<Void> {
        return base.actionButton.rx.tap
    }
    
}
