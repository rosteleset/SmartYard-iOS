import UIKit

class ABProgressIndicator: UIView {
    
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.frame = self.bounds
        imageView.image = UIImage(named: "RangeSliderProgress")
        imageView.contentMode = .scaleToFill
        
        addSubview(imageView)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = self.bounds
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let frame = CGRect(
            x: -self.frame.size.width / 2,
            y: 0,
            width: self.frame.size.width * 2,
            height: self.frame.size.height
        )
        
        return frame.contains(point) ? self : nil
    }
    
}
