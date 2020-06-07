import UIKit

open class ABTimeView: UIView {
    
    let timeLabel = UILabel()
    let backgroundView = UIView()
    
    override open var intrinsicContentSize: CGSize {
        let height: CGFloat = 16
        let labelWidth = timeLabel.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: height)).width
        let width: CGFloat = 4 * 2 + labelWidth
        
        return CGSize(width: width, height: height)
    }
    
    public init(size: CGSize) {
        let frame = CGRect(
            x: 0,
            y: -size.height - 7,
            width: size.width,
            height: size.height
        )
        
        super.init(frame: frame)
        
        // Add Background View
        self.backgroundView.frame = self.bounds
        self.backgroundView.backgroundColor = UIColor.yellow
        self.addSubview(self.backgroundView)
        
        backgroundView.backgroundColor = .white
        backgroundView.cornerRadius = 3
        
        // Add time label
        self.timeLabel.textAlignment = .center
        self.timeLabel.textColor = UIColor(hex: 0x333333)
        self.timeLabel.font = UIFont.SourceSansPro.semibold(size: 12)
        self.addSubview(self.timeLabel)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()

        self.backgroundView.frame = self.bounds
        
        self.timeLabel.frame = CGRect(
            x: 4,
            y: 0,
            width: self.frame.width - 4 * 2,
            height: self.frame.height
        )
    }
    
    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
