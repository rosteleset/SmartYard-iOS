import UIKit

class SimpleVideoProgressIndicator: UIView {
    
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.frame = bounds
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
        
        imageView.frame = bounds
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedBounds = CGRect(
            x: -15 - frame.size.width / 2,
            y: 0,
            width: frame.size.width * 2 + 30,
            height: frame.size.height
        )
        
        return extendedBounds.contains(point)
    }
    
}
