//
//  SimpleVideoProgressSlider.swift
//  SmartYard
//
//  Created by admin on 08.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import AVKit

// swiftlint:disable all

@objc protocol SimpleVideoProgressSliderDelegate: AnyObject {
    
    func indicatorDidChangePosition(
        videoRangeSlider: SimpleVideoProgressSlider,
        isReceivingGesture: Bool,
        position: Float64
    )
    
    @objc optional func sliderGesturesBegan()
    @objc optional func sliderGesturesEnded()
    
}

class SimpleVideoProgressSlider: UIView, UIGestureRecognizerDelegate {
    
    weak var delegate: SimpleVideoProgressSliderDelegate? = nil
    
    private let progressTimeView = SimpleVideoTimeView(size: .zero)
    private let progressIndicator = SimpleVideoProgressIndicator()

    private let thumbnailsContainer = UIView()
    private var thumbnailViews = [(UIImageView, UIActivityIndicatorView)]()
    
    private var duration: Float64 = 0
    
    private var progressPercentage: CGFloat = 0         // Represented in percentage
    
    public var isReceivingGesture: Bool = false
    
    private var relativeStartDate: Date?
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

        // Setup Progress Indicator

        let progressDrag = UIPanGestureRecognizer(
            target:self,
            action: #selector(progressDragged(recognizer:))
        )
        
        progressIndicator.addGestureRecognizer(progressDrag)
        self.addSubview(progressIndicator)

        // Setup time labels
        
        self.addSubview(progressTimeView)
        
        // Setup previews
        
        thumbnailsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.5)
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
            
            thumbnailsContainer.addSubview(activityIndicator)
        }
    }
    
    func setCurrentTime(_ time: CMTime) {
        guard !isReceivingGesture, time.seconds <= duration else {
            return
        }
        
        self.progressPercentage = self.valueFromSeconds(seconds: Float(time.seconds))

        layoutSubviews()
    }
    
    func setVideoDuration(_ duration: Double) {
        self.duration = duration
        
        self.layoutSubviews()
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
    
    func setRelativeStartDate(_ date: Date?) {
        relativeStartDate = date
        
        layoutSubviews()
    }
    
    func setReferenceCalendar(_ calendar: Calendar) {
        referenceCalendar = calendar
        
        layoutSubviews()
    }

    // MARK: - Private functions
    
    @objc func progressDragged(recognizer: UIPanGestureRecognizer) {
        guard duration > 0 else {
            return
        }
        
        updateGestureStatus(recognizer: recognizer)
        
        let translation = recognizer.translation(in: self)

        let positionLimitStart  = positionFromValue(value: 0)
        let positionLimitEnd    = positionFromValue(value: 100)

        var position = positionFromValue(value: self.progressPercentage)
        position = position + translation.x

        if position < positionLimitStart {
            position = positionLimitStart
        }

        if position > positionLimitEnd {
            position = positionLimitEnd
        }

        recognizer.setTranslation(CGPoint.zero, in: self)

        progressIndicator.center = CGPoint(x: position , y: progressIndicator.center.y)

        let percentage = valueFromPosition(position: progressIndicator.center.x)

        let progressSeconds = negateConversionLosses(secondsFromValue(value: progressPercentage))
        
        self.delegate?.indicatorDidChangePosition(
            videoRangeSlider: self,
            isReceivingGesture: isReceivingGesture,
            position: progressSeconds
        )

        self.progressPercentage = percentage

        layoutSubviews()
    }
    
    // MARK: - Drag Functions Helpers
    private func positionFromValue(value: CGFloat) -> CGFloat {
        let startPosition = progressIndicator.bounds.width / 2
        let endPosition = frame.size.width - progressIndicator.bounds.width / 2
        let neededPosition = startPosition + value * (endPosition - startPosition) / 100

        return neededPosition
    }
    
    private func valueFromPosition(position: CGFloat) -> CGFloat {
        let startPosition = progressIndicator.bounds.width / 2
        let endPosition = frame.size.width - progressIndicator.bounds.width / 2
        
        return (position - startPosition) * 100 / (endPosition - startPosition)
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
            self.delegate?.sliderGesturesBegan?()
            
        } else if recognizer.state == .ended {
            
            self.isReceivingGesture = false
            self.delegate?.sliderGesturesEnded?()
        }
    }

    // MARK: -

    override func layoutSubviews() {
        super.layoutSubviews()
        
        progressTimeView.timeLabel.text = getProgressTextValue(percentage: progressPercentage)
        
        let progressPosition = positionFromValue(value: self.progressPercentage)
        
        progressIndicator.frame = CGRect(
            x: progressPosition - 1.5,
            y: 1,
            width: 3,
            height: self.frame.size.height - 2
        )

        progressIndicator.center = CGPoint(x: progressPosition, y: progressIndicator.center.y)
        
        UIView.animate(withDuration: 0.05) { [weak self] in
            guard let self = self else {
                return
            }
            
            let timeViewWidth = self.progressTimeView.intrinsicContentSize.width
            let timeViewHeight = self.progressTimeView.intrinsicContentSize.height
            
            let preferredX = self.progressIndicator.center.x - timeViewWidth / 2
            let minPossibleX: CGFloat = 0
            let maxPossibleX = self.bounds.width - timeViewWidth
            let resultingX = min(max(minPossibleX, preferredX), maxPossibleX)
            
            self.progressTimeView.frame = CGRect(
                x: resultingX,
                y: -timeViewHeight - 7,
                width: timeViewWidth,
                height: timeViewHeight
            )
        }
        
        // Update fake thumbnails frames
        
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
    
    private func getProgressTextValue(percentage: CGFloat) -> String {
        let progressSeconds = negateConversionLosses(secondsFromValue(value: percentage))
        
        guard let relativeStartDate = relativeStartDate else {
            let hours:Int = Int(progressSeconds.truncatingRemainder(dividingBy: 86400) / 3600)
            let minutes:Int = Int(progressSeconds.truncatingRemainder(dividingBy: 3600) / 60)
            let seconds:Int = Int(progressSeconds.truncatingRemainder(dividingBy: 60))
            
            if hours > 0 {
                return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
            } else {
                return String(format: "%02i:%02i", minutes, seconds)
            }
        }
        
        let progressIndicatorDate = relativeStartDate.addingTimeInterval(progressSeconds)
        
        let formatter = DateFormatter()
        
        formatter.timeZone = referenceCalendar.timeZone
        formatter.dateFormat = "HH:mm:ss"
        
        return formatter.string(from: progressIndicatorDate)
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
