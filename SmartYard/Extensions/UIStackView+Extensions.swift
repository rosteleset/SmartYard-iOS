import UIKit

extension UIStackView {
    convenience init(
        axis: NSLayoutConstraint.Axis,
        distribution: UIStackView.Distribution,
        arrangedSubviews: [UIView] = [],
        paddings: NSDirectionalEdgeInsets? = nil,
        spacing: CGFloat? = nil,
        alignment: UIStackView.Alignment = .fill
    ) {
        self.init(arrangedSubviews: arrangedSubviews)
        self.axis = axis
        self.distribution = distribution
        self.alignment = alignment
        paddings.map {
            self.isLayoutMarginsRelativeArrangement = true
            self.directionalLayoutMargins = $0
        }
        spacing.map { self.spacing = $0 }
    }

    class func vertical(
        arrangedSubviews: [UIView] = [],
        paddings: NSDirectionalEdgeInsets? = nil,
        spacing: CGFloat? = nil,
        alignment: UIStackView.Alignment = .fill
    ) -> UIStackView {
        return .init(
            axis: .vertical,
            distribution: .fill,
            arrangedSubviews: arrangedSubviews,
            paddings: paddings,
            spacing: spacing,
            alignment: alignment
        )
    }

    class func horizontal(
        arrangedSubviews: [UIView] = [],
        paddings: NSDirectionalEdgeInsets? = nil,
        spacing: CGFloat? = nil,
        alignment: UIStackView.Alignment = .fill
    ) -> UIStackView {
        return .init(
            axis: .horizontal,
            distribution: .fill,
            arrangedSubviews: arrangedSubviews,
            paddings: paddings,
            spacing: spacing,
            alignment: alignment
        )
    }

    func addArrangedSubview(_ view: UIView, customSpacing: CGFloat? = nil) {
        addArrangedSubview(view)
        if let customSpacing {
            setCustomSpacing(customSpacing, after: view)
        }
    }

    func addBackground(
        color: UIColor,
        cornerRadius: CGFloat? = nil,
        cornerMask: CACornerMask? = nil
    ) {
        backgroundColor = color
        if let cornerRadius {
            layer.cornerRadius = cornerRadius
        }
        if let cornerMask {
            layer.maskedCorners = cornerMask
        }
    }
}

@resultBuilder public struct AddViewBuilder {
    public static func buildBlock(_ views: UIView...) -> [UIView] { views }
}

extension UIStackView {
    @discardableResult func add(_ views: [UIView]) -> UIView {
        views.forEach { self.addArrangedSubview($0) }
        return self
    }

    @discardableResult func add(@AddViewBuilder _ block: () -> ([UIView])) -> UIView {
        block().forEach { self.addArrangedSubview($0) }
        return self
    }

    @discardableResult func insert(at index: Int, block: () -> (UIView)) -> UIView {
        insertArrangedSubview(block(), at: index)
        return self
    }
}
