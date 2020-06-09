import UIKit

class ABEndIndicator: UIView {
    
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        
        imageView.frame = self.bounds
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
        
        imageView.frame = self.bounds
    }
    
}
