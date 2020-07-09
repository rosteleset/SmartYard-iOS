import UIKit

class SimpleVideoTimeView: UIView {
    
    let timeLabel = UILabel()
    let backgroundView = UIView()
    
    override var intrinsicContentSize: CGSize {
        let height: CGFloat = 16
        let labelWidth = timeLabel.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: height)).width
        let width: CGFloat = 4 * 2 + labelWidth
        
        return CGSize(width: width, height: height)
    }
    
    init(size: CGSize) {
        let frame = CGRect(
            x: 0,
            y: -size.height - 7,
            width: size.width,
            height: size.height
        )
        
        super.init(frame: frame)
        
        // Add Background View
        backgroundView.frame = bounds
        backgroundView.backgroundColor = .yellow
        addSubview(backgroundView)
        
        backgroundView.backgroundColor = .white
        backgroundView.cornerRadius = 3
        
        // Add time label
        timeLabel.textAlignment = .center
        timeLabel.textColor = UIColor(hex: 0x333333)
        timeLabel.font = UIFont.SourceSansPro.semibold(size: 12)
        addSubview(timeLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundView.frame = bounds
        
        timeLabel.frame = CGRect(
            x: 4,
            y: 0,
            width: frame.width - 4 * 2,
            height: frame.height
        )
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
