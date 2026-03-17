import UIKit

final class HSpacer: UIView {
    init(_ width: CGFloat = 0) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        if width > 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class VSpacer: UIView {
    init(_ height: CGFloat = 0) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        if height > 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
