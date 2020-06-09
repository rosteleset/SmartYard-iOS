import UIKit
import AVKit
import Kingfisher

// swiftlint:disable all

@objc public protocol SimpleVideoRangeSliderDelegate: class {
    func didChangeValue(videoRangeSlider: SimpleVideoRangeSlider, startTime: Float64, endTime: Float64)
    
    @objc optional func sliderGesturesBegan()
    @objc optional func sliderGesturesEnded()
}

public class SimpleVideoRangeSlider: UIView, UIGestureRecognizerDelegate {

    private enum DragHandleChoice {
        case start
        case end
    }
    
    public weak var delegate: SimpleVideoRangeSliderDelegate? = nil

    private let startIndicator = ABStartIndicator()
    private let endIndicator = ABEndIndicator()
    
    private let startCropBlurView = UIView()
    private let endCropBlurView = UIView()
    private let fakeThumbnailsContainer = UIView()
    private var fakeThumbnailImageViews = [UIImageView]()

    private let startTimeView = ABTimeView(size: .zero)
    private let endTimeView = ABTimeView(size: .zero)
    
    private var duration: Float64 = 0.0
    private var startPercentage: CGFloat = 0         // Represented in percentage
    private var endPercentage: CGFloat = 100       // Represented in percentage
    private var isReceivingGesture: Bool = false

    public var minSpace: Float = 1              // In Seconds
    public var maxSpace: Float = 0              // In Seconds

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setup(){
        layer.cornerRadius = 3
        layer.borderColor = UIColor(hex: 0xffe38e)?.cgColor
        layer.borderWidth = 1
        
        self.isUserInteractionEnabled = true

        // Setup Start Indicator
        let startDrag = UIPanGestureRecognizer(
            target: self,
            action: #selector(startDragged(recognizer:))
        )
        
        startIndicator.layer.anchorPoint = CGPoint(x: 1, y: 0.5)
        startIndicator.addGestureRecognizer(startDrag)
        self.addSubview(startIndicator)

        // Setup End Indicator

        let endDrag = UIPanGestureRecognizer(
            target: self,
            action: #selector(endDragged(recognizer:))
        )
        
        endIndicator.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        endIndicator.addGestureRecognizer(endDrag)
        self.addSubview(endIndicator)

        // Setup time labels
        
        self.addSubview(startTimeView)
        self.addSubview(endTimeView)
        
        // Setup fake previews
        
        startCropBlurView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        endCropBlurView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        
        fakeThumbnailsContainer.addSubview(startCropBlurView)
        fakeThumbnailsContainer.addSubview(endCropBlurView)
        
        addSubview(fakeThumbnailsContainer)
        sendSubviewToBack(fakeThumbnailsContainer)
        fakeThumbnailsContainer.cornerRadius = 3
        
        let imageViews = [UIImageView(), UIImageView(), UIImageView(), UIImageView(), UIImageView()]
        
        imageViews.forEach {
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
            fakeThumbnailsContainer.addSubview($0)
            fakeThumbnailsContainer.sendSubviewToBack($0)
        }
        
        self.fakeThumbnailImageViews = imageViews
    }
    
    public func moveEndIndicatorByValueInSeconds(_ value: Double) {
        guard !isReceivingGesture, duration > 0 else {
            return
        }
        
        let currentEndIndicatorTime = secondsFromValue(value: endPercentage)
        let preferredEndIndicatorTime = currentEndIndicatorTime + value
        
        let newPreferredPercentage = valueFromSeconds(seconds: Float(preferredEndIndicatorTime))
        let minPossiblePercentage = startPercentage + valueFromSeconds(seconds: minSpace)
        let maxPossiblePercentage: CGFloat = 100
        
        endPercentage = max(minPossiblePercentage, min(newPreferredPercentage, maxPossiblePercentage))

        let startSeconds = secondsFromValue(value: self.startPercentage)
        let endSeconds = secondsFromValue(value: self.endPercentage)
        
        self.delegate?.didChangeValue(videoRangeSlider: self, startTime: startSeconds, endTime: endSeconds)
        
        layoutSubviews()
    }

    public func setVideoURL(videoURL: URL?) {
        let duration: Double = {
            guard let url = videoURL else {
                return 0
            }
            
            let source = AVURLAsset(url: url)
            return CMTimeGetSeconds(source.duration)
        }()
        
        self.duration = duration
        
        self.layoutSubviews()
        self.superview?.layoutSubviews()
    }
    
    public func setFakeThumbnailURL(thumbnailURL: URL?) {
        fakeThumbnailImageViews.forEach {
            $0.kf.setImage(with: thumbnailURL)
        }
    }

    // MARK: - Private functions

    // MARK: - Crop Handle Drag Functions
    @objc private func startDragged(recognizer: UIPanGestureRecognizer){
        self.processHandleDrag(
            recognizer: recognizer,
            drag: .start,
            currentPositionPercentage: self.startPercentage,
            currentIndicator: self.startIndicator
        )
    }
    
    @objc private func endDragged(recognizer: UIPanGestureRecognizer){
        self.processHandleDrag(
            recognizer: recognizer,
            drag: .end,
            currentPositionPercentage: self.endPercentage,
            currentIndicator: self.endIndicator
        )
    }

    private func processHandleDrag(
        recognizer: UIPanGestureRecognizer,
        drag: DragHandleChoice,
        currentPositionPercentage: CGFloat,
        currentIndicator: UIView
    ) {
        guard duration > 0 else {
            return
        }
        
        self.updateGestureStatus(recognizer: recognizer)
        
        let translation = recognizer.translation(in: self)
        
        var position: CGFloat = positionFromValue(value: currentPositionPercentage) // self.startPercentage or self.endPercentage
        
        position = position + translation.x
        
        if position < startIndicator.bounds.width { position = startIndicator.bounds.width }
        
        if position > self.frame.size.width - endIndicator.bounds.width {
            position = self.frame.size.width - endIndicator.bounds.width
        }

        let positionLimits = getPositionLimits(with: drag)
        position = checkEdgeCasesForPosition(with: position, and: positionLimits.min, and: drag)

        if Float(self.duration) > self.maxSpace && self.maxSpace > 0 {
            if drag == .start {
                if position < positionLimits.max {
                    position = positionLimits.max
                }
            } else {
                if position > positionLimits.max {
                    position = positionLimits.max
                }
            }
        }
        
        recognizer.setTranslation(CGPoint.zero, in: self)
        
        currentIndicator.center = CGPoint(x: position , y: currentIndicator.center.y)
        
        let percentage = valueFromPosition(position: currentIndicator.center.x)
        
        let startSeconds = secondsFromValue(value: self.startPercentage)
        let endSeconds = secondsFromValue(value: self.endPercentage)
        
        self.delegate?.didChangeValue(videoRangeSlider: self, startTime: startSeconds, endTime: endSeconds)
        
        if drag == .start {
            self.startPercentage = percentage
        } else {
            self.endPercentage = percentage
        }
        
        layoutSubviews()
    }
    
    // MARK: - Drag Functions Helpers
    private func positionFromValue(value: CGFloat) -> CGFloat {
        let startPosition = startIndicator.bounds.width
        let endPosition = frame.size.width - endIndicator.bounds.width
        let neededPosition = startPosition + value * (endPosition - startPosition) / 100

        return neededPosition
    }
    
    private func valueFromPosition(position: CGFloat) -> CGFloat {
        let startPosition = startIndicator.bounds.width
        let endPosition = frame.size.width - endIndicator.bounds.width
        
        return (position - startPosition) * 100 / (endPosition - startPosition)
    }
    
    private func getPositionLimits(with drag: DragHandleChoice) -> (min: CGFloat, max: CGFloat) {
        if drag == .start {
            return (
                positionFromValue(value: self.endPercentage - valueFromSeconds(seconds: self.minSpace)),
                positionFromValue(value: self.endPercentage - valueFromSeconds(seconds: self.maxSpace))
            )
        } else {
            return (
                positionFromValue(value: self.startPercentage + valueFromSeconds(seconds: self.minSpace)),
                positionFromValue(value: self.startPercentage + valueFromSeconds(seconds: self.maxSpace))
            )
        }
    }
    
    private func checkEdgeCasesForPosition(with position: CGFloat, and positionLimit: CGFloat, and drag: DragHandleChoice) -> CGFloat {
        if drag == .start {
            if Float(self.duration) < self.minSpace {
                return 0
            } else {
                if position > positionLimit {
                    return positionLimit
                }
            }
        } else {
            if Float(self.duration) < self.minSpace {
                return self.frame.size.width
            } else {
                if position < positionLimit {
                    return positionLimit
                }
            }
        }
        
        return position
    }
    
    private func secondsFromValue(value: CGFloat) -> Float64{
        return duration * Float64((value / 100))
    }

    private func valueFromSeconds(seconds: Float) -> CGFloat{
        return CGFloat(seconds * 100) / CGFloat(duration)
    }
    
    private func updateGestureStatus(recognizer: UIGestureRecognizer) {
        if recognizer.state == .began {
            
            self.isReceivingGesture = true
            self.delegate?.sliderGesturesBegan?()
            
        } else if recognizer.state == .ended {
            
            self.isReceivingGesture = false
            self.delegate?.sliderGesturesEnded?()
        }
    }

    // MARK: -

    override public func layoutSubviews() {
        super.layoutSubviews()

        startTimeView.timeLabel.text = self.secondsToFormattedString(totalSeconds: secondsFromValue(value: self.startPercentage))
        endTimeView.timeLabel.text = self.secondsToFormattedString(totalSeconds: secondsFromValue(value: self.endPercentage))

        let startPosition = positionFromValue(value: self.startPercentage)
        let endPosition = positionFromValue(value: self.endPercentage)

        startIndicator.center = CGPoint(x: startPosition, y: startIndicator.center.y)
        startIndicator.size = CGSize(width: 12, height: bounds.height)
        
        endIndicator.center = CGPoint(x: endPosition, y: endIndicator.center.y)
        endIndicator.size = CGSize(width: 12, height: bounds.height)
        
        UIView.animate(withDuration: 0.05) { [weak self] in
            guard let self = self else {
                return
            }
            
            let startTimeViewX = self.startIndicator.frame.origin.x
            let startTimeViewWidth = self.startTimeView.intrinsicContentSize.width
            let startTimeViewHeight = self.startTimeView.intrinsicContentSize.height

            // Update time view
            self.startTimeView.frame = CGRect(
                x: startTimeViewX,
                y: -self.startTimeView.intrinsicContentSize.height - 7,
                width: startTimeViewWidth,
                height: startTimeViewHeight
            )
            
            let endTimeViewX = self.endIndicator.frame.origin.x + self.endIndicator.frame.width - self.endTimeView.intrinsicContentSize.width
            
            let endTimeViewY: CGFloat = {
                guard endTimeViewX >= startTimeViewX + startTimeViewWidth + 7 else {
                    return -self.endTimeView.intrinsicContentSize.height - 7 - startTimeViewHeight - 7
                }
                
                return -self.endTimeView.intrinsicContentSize.height - 7
            }()
            
            self.endTimeView.frame = CGRect(
                x: endTimeViewX,
                y: endTimeViewY,
                width: self.endTimeView.intrinsicContentSize.width,
                height: self.endTimeView.intrinsicContentSize.height
            )
        }
        
        // Update fake thumbnails frames
        
        startCropBlurView.frame = CGRect(
            x: 0,
            y: 0,
            width: startIndicator.frame.origin.x + 3,
            height: bounds.height
        )
        
        endCropBlurView.frame = CGRect(
            x: endIndicator.frame.origin.x + endIndicator.frame.size.width - 3,
            y: 0,
            width: bounds.width - (endIndicator.frame.origin.x + endIndicator.frame.size.width) + 3,
            height: bounds.height
        )
        
        fakeThumbnailsContainer.frame = bounds
        
        guard !fakeThumbnailImageViews.isEmpty else {
            return
        }
        
        let imageWidth = bounds.width / CGFloat(fakeThumbnailImageViews.count)
        
        fakeThumbnailImageViews.enumerated().forEach { offset, element in
            element.frame = CGRect(
                x: CGFloat(offset) * imageWidth,
                y: 0,
                width: imageWidth,
                height: bounds.height
            )
        }
    }

    private func secondsToFormattedString(totalSeconds: Float64) -> String{
        let hours:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
    
}

// swiftlint:enable all
