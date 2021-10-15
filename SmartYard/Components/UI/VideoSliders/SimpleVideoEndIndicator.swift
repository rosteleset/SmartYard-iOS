import UIKit

class SimpleVideoEndIndicator: UIView {
    
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isUserInteractionEnabled = true
        
        imageView.frame = bounds
        imageView.image = UIImage(named: "RangeSliderEnd")
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
            x: 0,
            y: 0,
            width: frame.size.width + 15,
            height: frame.size.height
        )
        
        return extendedBounds.contains(point)
    }
    
}
