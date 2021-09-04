import UIKit
import AVKit

// swiftlint:disable all

protocol SimpleVideoRangeSliderDelegate: AnyObject {
    
    func didChangeDate(
        videoRangeSlider: SimpleVideoRangeSlider,
        isReceivingGesture: Bool,
        startDate: Date,
        endDate: Date,
        isLowerBoundReached: Bool,
        isUpperBoundReached: Bool,
        screenshotPolicy: SimpleVideoRangeSlider.ScreenshotPolicy
    )
    
}

class SimpleVideoRangeSlider: UIView, UIGestureRecognizerDelegate {
    
    enum ScreenshotPolicy {
        case start
        case end
        case middle
        case none
    }

    private enum DragHandleChoice {
        case start
        case end
    }
    
    weak var delegate: SimpleVideoRangeSliderDelegate? = nil

    private let startIndicator = SimpleVideoStartIndicator()
    private let endIndicator = SimpleVideoEndIndicator()
    
    private let startCropBlurView = UIView()
    private let endCropBlurView = UIView()
    
    private let thumbnailsContainer = UIView()
    private var thumbnailViews = [(UIImageView, UIActivityIndicatorView)]()

    private let startTimeView = SimpleVideoTimeView(size: .zero)
    private let endTimeView = SimpleVideoTimeView(size: .zero)
    
    private let duration: Float64 = 3600 // limiting timespan to one hour
    
    private var startPercentage: CGFloat = 0         // Represented in percentage
    private var endPercentage: CGFloat = 100       // Represented in percentage
    private var isReceivingGesture: Bool = false

    var minSpace: Float = 10              // In Seconds
    var maxSpace: Float = 0              // In Seconds

    private var visibleTimelineEndDate = Date()
    
    private var visibleTimelineStartDate: Date {
        return visibleTimelineEndDate.addingTimeInterval(-duration)
    }
    
    private var isLowerBoundReached: Bool {
        guard let lowerBound = absoluteTimelineLowerBound else {
            return false
        }
        
        return visibleTimelineStartDate <= lowerBound
    }
    
    private var isUpperBoundReached: Bool {
        guard let upperBound = absoluteTimelineUpperBound else {
            return false
        }
        
        return visibleTimelineEndDate >= upperBound
    }
    
    private var absoluteTimelineLowerBound: Date?
    private var absoluteTimelineUpperBound: Date?
    
    private var latestScreenshotPolicy: ScreenshotPolicy = .middle
    
    private var referenceCalendar = Calendar.current
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setup(){
        backgroundColor = .clear
        
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
        
        // Setup previews
        
        startCropBlurView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        endCropBlurView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        
        thumbnailsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        thumbnailsContainer.addSubview(startCropBlurView)
        thumbnailsContainer.addSubview(endCropBlurView)
        
        addSubview(thumbnailsContainer)
        sendSubviewToBack(thumbnailsContainer)
        thumbnailsContainer.cornerRadius = 3
        
        let thumbnailViews = [
            (UIImageView(), UIActivityIndicatorView()),
            (UIImageView(), UIActivityIndicatorView()),
            (UIImageView(), UIActivityIndicatorView()),
            (UIImageView(), UIActivityIndicatorView()),
            (UIImageView(), UIActivityIndicatorView())
        ]
        
        self.thumbnailViews = thumbnailViews
        
        thumbnailViews.forEach { imageView, activityIndicator in
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            
            thumbnailsContainer.addSubview(imageView)
            thumbnailsContainer.sendSubviewToBack(imageView)
            
            activityIndicator.color = .white
            
            thumbnailsContainer.insertSubview(activityIndicator, aboveSubview: imageView)
        }
    }
    
    private func shiftTimelineBackward(_ value: Double) {
        let preferredVisibleTimelineStartDate = visibleTimelineStartDate.addingTimeInterval(-value)
        
        let resultingVisibleTimelineStartDate: Date = {
            guard let lowerBound = absoluteTimelineLowerBound,
                (absoluteTimelineUpperBound ?? Date.distantFuture).timeIntervalSince(lowerBound) >= 3600 else {
                return preferredVisibleTimelineStartDate
            }
            
            return max(lowerBound, preferredVisibleTimelineStartDate)
        }()
        
        let actualShift = visibleTimelineStartDate.timeIntervalSince(resultingVisibleTimelineStartDate)

        let resultingVisibleTimelineEndDate = resultingVisibleTimelineStartDate.addingTimeInterval(3600)
        
        visibleTimelineEndDate = resultingVisibleTimelineEndDate
        
        let currentStartIndicatorTime = secondsFromValue(value: startPercentage)
        let preferredStartIndicatorTime = currentStartIndicatorTime + actualShift
        
        let currentEndIndicatorTime = secondsFromValue(value: endPercentage)
        let preferredEndIndicatorTime = currentEndIndicatorTime + actualShift
        let maxEndIndicatorTime: Double = 3600
        
        let resultingEndIndicatorTime = min(preferredEndIndicatorTime, maxEndIndicatorTime)
        
        let resultingStartIndicatorTime = min(
            resultingEndIndicatorTime - Double(minSpace),
            preferredStartIndicatorTime
        )
        
        startPercentage = valueFromSeconds(seconds: Float(resultingStartIndicatorTime))
        endPercentage = valueFromSeconds(seconds: Float(resultingEndIndicatorTime))
        
        delegate?.didChangeDate(
            videoRangeSlider: self,
            isReceivingGesture: isReceivingGesture,
            startDate: visibleTimelineStartDate.addingTimeInterval(resultingStartIndicatorTime),
            endDate: visibleTimelineStartDate.addingTimeInterval(resultingEndIndicatorTime),
            isLowerBoundReached: isLowerBoundReached,
            isUpperBoundReached: isUpperBoundReached,
            screenshotPolicy: latestScreenshotPolicy
        )
        
        layoutSubviews()
    }
    
    private func shiftTimelineForward(_ value: Double) {
        let newPreferredVisibleTimelineEndDate = visibleTimelineEndDate.addingTimeInterval(value)
        
        let resultingVisibleTimelineEndDate: Date = {
            guard let upperBound = absoluteTimelineUpperBound,
                upperBound.timeIntervalSince(absoluteTimelineLowerBound ?? Date.distantPast) >= 3600 else {
                return newPreferredVisibleTimelineEndDate
            }
            
            return min(upperBound, newPreferredVisibleTimelineEndDate)
        }()
        
        let actualShift = resultingVisibleTimelineEndDate.timeIntervalSince(visibleTimelineEndDate)
        
        visibleTimelineEndDate = resultingVisibleTimelineEndDate

        let currentStartIndicatorTime = secondsFromValue(value: startPercentage)
        let preferredStartIndicatorTime = currentStartIndicatorTime - actualShift
        let minStartIndicatorTime: Double = 0
        
        let currentEndIndicatorTime = secondsFromValue(value: endPercentage)
        let preferredEndIndicatorTime = currentEndIndicatorTime - actualShift
        
        let resultingStartIndicatorTime = max(preferredStartIndicatorTime, minStartIndicatorTime)
        
        let resultingEndIndicatorTime = max(
            resultingStartIndicatorTime + Double(minSpace),
            preferredEndIndicatorTime
        )
        
        startPercentage = valueFromSeconds(seconds: Float(resultingStartIndicatorTime))
        endPercentage = valueFromSeconds(seconds: Float(resultingEndIndicatorTime))
        
        delegate?.didChangeDate(
            videoRangeSlider: self,
            isReceivingGesture: isReceivingGesture,
            startDate: visibleTimelineStartDate.addingTimeInterval(resultingStartIndicatorTime),
            endDate: visibleTimelineStartDate.addingTimeInterval(resultingEndIndicatorTime),
            isLowerBoundReached: visibleTimelineStartDate == absoluteTimelineLowerBound,
            isUpperBoundReached: visibleTimelineEndDate == absoluteTimelineUpperBound,
            screenshotPolicy: latestScreenshotPolicy
        )
        
        layoutSubviews()
    }
    
    func shiftTimelineByValueInSeconds(_ value: Double) {
        guard !isReceivingGesture, value != 0 else {
            return
        }
        
        value < 0 ? shiftTimelineBackward(abs(value)) : shiftTimelineForward(value)
    }
    
    func setThumbnailImage(_ image: UIImage?, atIndex index: Int) {
        guard let (imageView, activityIndicator) = thumbnailViews[safe: index] else {
            return
        }
        
        imageView.image = image
        activityIndicator.stopAnimating()
    }
    
    func resetThumbnailImages() {
        thumbnailViews.forEach { imageView, _ in
            imageView.image = nil
        }
    }
    
    func setActivityIndicatorsHidden(_ isHidden: Bool) {
        thumbnailViews.forEach { _, activityIndicator in
            isHidden ? activityIndicator.stopAnimating() : activityIndicator.startAnimating()
        }
    }
    
    func setTimelineConfiguration(visibleTimelineEndDate: Date, lowerBound: Date?, upperBound: Date?) {
        self.visibleTimelineEndDate = visibleTimelineEndDate
        
        startPercentage = 0
        endPercentage = 100
        
        absoluteTimelineLowerBound = lowerBound
        absoluteTimelineUpperBound = upperBound
        
        latestScreenshotPolicy = .middle
        
        delegate?.didChangeDate(
            videoRangeSlider: self,
            isReceivingGesture: isReceivingGesture,
            startDate: visibleTimelineStartDate.addingTimeInterval(secondsFromValue(value: startPercentage)),
            endDate: visibleTimelineStartDate.addingTimeInterval(secondsFromValue(value: endPercentage)),
            isLowerBoundReached: isLowerBoundReached,
            isUpperBoundReached: isUpperBoundReached,
            screenshotPolicy: latestScreenshotPolicy
        )
        
        layoutSubviews()
    }
    
    func setReferenceCalendar(_ calendar: Calendar) {
        referenceCalendar = calendar
        
        layoutSubviews()
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
        
        if drag == .start {
            self.startPercentage = percentage
        } else {
            self.endPercentage = percentage
        }
        
        let startSeconds = negateConversionLosses(secondsFromValue(value: self.startPercentage))
        let endSeconds = negateConversionLosses(secondsFromValue(value: self.endPercentage))
        
        latestScreenshotPolicy = drag == .end ? .end : .start
        
        delegate?.didChangeDate(
            videoRangeSlider: self,
            isReceivingGesture: isReceivingGesture,
            startDate: visibleTimelineStartDate.addingTimeInterval(startSeconds),
            endDate: visibleTimelineStartDate.addingTimeInterval(endSeconds),
            isLowerBoundReached: isLowerBoundReached,
            isUpperBoundReached: isUpperBoundReached,
            screenshotPolicy: latestScreenshotPolicy
        )
        
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
    
    private func secondsFromValue(value: CGFloat) -> Float64 {
        return duration * Float64((value / 100))
    }

    private func valueFromSeconds(seconds: Float) -> CGFloat {
        guard duration > 0 else {
            return 0
        }
        
        return CGFloat(seconds * 100) / CGFloat(duration)
    }
    
    private func updateGestureStatus(recognizer: UIGestureRecognizer) {
        if recognizer.state == .began {
            self.isReceivingGesture = true
        } else if recognizer.state == .ended {
            self.isReceivingGesture = false
        }
    }

    // MARK: -

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let startEndTextValues = getStartEndIndicatorTextValues(
            startPercentage: startPercentage,
            endPercentage: endPercentage
        )
        
        startTimeView.timeLabel.text = startEndTextValues.startText
        endTimeView.timeLabel.text = startEndTextValues.endText

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
            
            let startTimeViewWidth = self.startTimeView.intrinsicContentSize.width
            let startTimeViewHeight = self.startTimeView.intrinsicContentSize.height
            
            let preferredStartTimeViewX = self.startIndicator.frame.origin.x
            let minStartTimeViewX: CGFloat = 0
            let maxStartTimeViewX = self.bounds.width - startTimeViewWidth
            let resultingStartTimeViewX = min(maxStartTimeViewX, max(minStartTimeViewX, preferredStartTimeViewX))
            
            // Update time view
            self.startTimeView.frame = CGRect(
                x: resultingStartTimeViewX,
                y: -self.startTimeView.intrinsicContentSize.height - 7,
                width: startTimeViewWidth,
                height: startTimeViewHeight
            )
            
            let endTimeViewWidth = self.endTimeView.intrinsicContentSize.width
            
            let preferredEndTimeViewX = self.endIndicator.frame.origin.x + self.endIndicator.frame.width - self.endTimeView.intrinsicContentSize.width
            let minEndTimeViewX: CGFloat = 0
            let maxEndTimeViewX = self.bounds.width - endTimeViewWidth
            let resultingEndTimeViewX = min(maxEndTimeViewX, max(minEndTimeViewX, preferredEndTimeViewX))
            
            let endTimeViewY: CGFloat = {
                guard resultingEndTimeViewX >= resultingStartTimeViewX + startTimeViewWidth + 7 else {
                    return -self.endTimeView.intrinsicContentSize.height - 7 - startTimeViewHeight - 7
                }
                
                return -self.endTimeView.intrinsicContentSize.height - 7
            }()
            
            self.endTimeView.frame = CGRect(
                x: resultingEndTimeViewX,
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
        
        thumbnailsContainer.frame = bounds
        
        guard !thumbnailViews.isEmpty else {
            return
        }
        
        let imageWidth = bounds.width / CGFloat(thumbnailViews.count)
        
        thumbnailViews.enumerated().forEach { offset, element in
            let (imageView, activityIndicator) = element
            
            imageView.frame = CGRect(
                x: CGFloat(offset) * imageWidth,
                y: 0,
                width: imageWidth,
                height: bounds.height
            )
            
            activityIndicator.center = imageView.center
        }
    }
    
    private func getStartEndIndicatorTextValues(
        startPercentage: CGFloat, endPercentage: CGFloat
    ) -> (startText: String, endText: String) {
        let startSeconds = negateConversionLosses(secondsFromValue(value: startPercentage))
        let startIndicatorDate = visibleTimelineStartDate.addingTimeInterval(startSeconds)
        
        let endSeconds = negateConversionLosses(secondsFromValue(value: endPercentage))
        let endIndicatorDate = visibleTimelineStartDate.addingTimeInterval(endSeconds)
        
        let format: String = {
            return startIndicatorDate.day == endIndicatorDate.day ? "HH:mm:ss" : "dd.MM HH:mm:ss"
        }()
        
        let formatter = DateFormatter()
        
        formatter.timeZone = referenceCalendar.timeZone
        formatter.dateFormat = format
        
        return (
            formatter.string(from: startIndicatorDate),
            formatter.string(from: endIndicatorDate)
        )
    }
    
    private func negateConversionLosses(_ value: Float64) -> Float64 {
        if abs(value.rounded() - value) < 0.00001 {
            return value.rounded()
        } else {
            return value
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedBounds = CGRect(
            x: -15,
            y: 0,
            width: self.frame.size.width + 30,
            height: self.frame.size.height
        )
        
        return extendedBounds.contains(point)
    }
    
}

// swiftlint:enable all
