//
//  CircleIconControl.swift
//  SmartYard
//
//  Created by Александр Попов on 30.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

final class CircleIconControl: UIControl {
    private let imageView = UIImageView()
    private(set) var style: CircleIconStyle?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    convenience init(style: CircleIconStyle, frame: CGRect = .zero) {
        self.init(frame: frame)
        apply(style: style)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func apply(style: CircleIconStyle) {
        self.style = style
        setup(with: style)
    }

    private func commonInit() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    private func setup(with style: CircleIconStyle) {
        backgroundColor = style.circleColor
        layer.borderColor = style.borderColor?.cgColor
        layer.borderWidth = style.borderWidth

        imageView.image = style.image?.withRenderingMode(.alwaysOriginal)
        imageView.tintColor = style.iconColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }

    override var isHighlighted: Bool {
        didSet {
            let alpha: CGFloat = isHighlighted ? 0.6 : 1.0
            let scale: CGFloat = isHighlighted ? 0.92 : 1.0

            UIView.animate(
                withDuration: 0.12,
                delay: 0,
                usingSpringWithDamping: 0.7,   // пружинистость
                initialSpringVelocity: 0.5,    // скорость отскока
                options: [.allowUserInteraction, .curveEaseOut],
                animations: {
                    self.alpha = alpha
                    self.transform = CGAffineTransform(scaleX: scale, y: scale)
                },
                completion: nil
            )
        }
    }

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.4
            isUserInteractionEnabled = isEnabled
        }
    }
}

extension Reactive where Base: CircleIconControl {
    var tap: ControlEvent<Void> {
        controlEvent(.touchUpInside)
    }
}
