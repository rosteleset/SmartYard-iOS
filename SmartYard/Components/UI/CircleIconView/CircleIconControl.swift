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
    var style: CircleIconStyle? {
        didSet {
            setup()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { super.init(coder: coder) }

    private func setup() {
        guard let style else { return }
        backgroundColor = style.circleColor
        layer.borderColor = style.borderColor?.cgColor
        layer.borderWidth = style.borderWidth

        imageView.image = style.image?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = style.iconColor
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
