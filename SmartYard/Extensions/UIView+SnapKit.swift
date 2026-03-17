import SnapKit
import UIKit

extension UIView {
    func addSubview(_ view: UIView, _ constraintsClosure: (_ make: ConstraintMaker) -> Void) {
        addSubview(view)
        view.snp.makeConstraints(constraintsClosure)
    }

    func pinSubview(_ view: UIView, with insets: UIEdgeInsets = .zero) {
        addSubview(view) { make in
            make.top.equalToSuperview().inset(insets.top)
            make.bottom.equalToSuperview().inset(insets.bottom)
            make.leading.equalToSuperview().inset(insets.left)
            make.trailing.equalToSuperview().inset(insets.right)
        }
    }

    @discardableResult func add(insets: UIEdgeInsets) -> UIView {
        let view = UIView()
        view.pinSubview(self, with: insets)
        return view
    }

    func insets(_ insets: UIEdgeInsets) -> UIView { add(insets: insets) }
}
