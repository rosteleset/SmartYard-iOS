import UIKit
import RxSwift
import RxCocoa
import RxRelay

final class SmartYardHighlightSegmentedControlView: UIView {
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let highlightView: UIView = {
        let view = UIView()
        view.backgroundColor = .SmartYard.backgroundColor
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    private let highlightLabel: UILabel = {
       let label = UILabel()
       label.font = UIFont.SourceSansPro.regular(size: 14)
       label.textColor = .SmartYard.semiBlack
       label.textAlignment = .center
       return label
   }()
    
    private var buttons: [UIButton] = []
    private var selectedIndex: Int = 0
    
    private let selectedIndexRelay = PublishRelay<Int>()
    fileprivate var selectedIndexObservable: Observable<Int> {
        selectedIndexRelay.asObservable()
    }
    
    var titles: [String] = [] {
        didSet {
            setupButtons()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(stackView)
        addSubview(highlightView)
        
        backgroundColor = .SmartYard.secondBackgroundColor
        layer.cornerRadius = 12
        clipsToBounds = true

        stackView.alignToView(self)

        highlightView.addSubview(highlightLabel)
        highlightLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            highlightLabel.centerXAnchor.constraint(equalTo: highlightView.centerXAnchor),
            highlightLabel.centerYAnchor.constraint(equalTo: highlightView.centerYAnchor),
            highlightLabel.leadingAnchor.constraint(equalTo: highlightView.leadingAnchor),
            highlightLabel.trailingAnchor.constraint(equalTo: highlightView.trailingAnchor)
        ])
    }
    
    private func setupButtons() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = []
        
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setTitleColor(
                index == selectedIndex ? .SmartYard.semiBlack : .SmartYard.gray,
                for: .normal
            )
            button.titleLabel?.font = UIFont.SourceSansPro.regular(size: 14)
            button.backgroundColor = .SmartYard.secondBackgroundColor
            button.tag = index
            button.addTarget(
                self,
                action: #selector(segmentTapped(_:)),
                for: .touchUpInside
            )
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
        
        layoutIfNeeded()
        updateHighlight(animated: false)
    }
    
    @objc private func segmentTapped(_ sender: UIButton) {
        setSelected(index: sender.tag, animated: true)
        selectedIndexRelay.accept(sender.tag)
    }
    
    fileprivate func setSelected(index: Int, animated: Bool = true) {
        guard index != selectedIndex else { return }
        
        let oldIndex = selectedIndex
        selectedIndex = index
        
        buttons[oldIndex].setTitleColor(.SmartYard.gray, for: .normal)
        buttons[selectedIndex].setTitleColor(.SmartYard.semiBlack, for: .normal)
        
        updateHighlight(animated: animated)
    }
    
    private func updateHighlight(animated: Bool) {
        guard buttons.indices.contains(selectedIndex) else { return }
        
        let selectedButton = buttons[selectedIndex]
        let targetFrame = selectedButton.frame.insetBy(dx: 4, dy: 4)
       
        highlightLabel.text = titles[selectedIndex]

        if animated {
            let animator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 0.8) { [weak self] in
                self?.highlightView.frame = targetFrame
            }
            animator.startAnimation()
        } else {
            highlightView.frame = targetFrame
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateHighlight(animated: false)
    }
}

extension Reactive where Base: SmartYardHighlightSegmentedControlView {
    
    var selectedIndex: ControlEvent<Int> {
        let source = base.selectedIndexObservable
        return ControlEvent(events: source)
    }

    var setSelectedIndex: Binder<Int> {
        return Binder(base) { control, index in
            control.setSelected(index: index, animated: true)
        }
    }
    
}
