//
//  SimpleVideoProgressSlider.swift
//  SmartYard
//
//  Created by admin on 08.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import AVKit
import Kingfisher

// swiftlint:disable all

@objc public protocol SimpleVideoProgressSliderDelegate: class {
    func indicatorDidChangePosition(videoRangeSlider: SimpleVideoProgressSlider, position: Float64)
    
    @objc optional func sliderGesturesBegan()
    @objc optional func sliderGesturesEnded()
}

public class SimpleVideoProgressSlider: UIView, UIGestureRecognizerDelegate {
    
    public weak var delegate: SimpleVideoProgressSliderDelegate? = nil
    
    private let progressTimeView = ABTimeView(size: .zero)
    private let progressIndicator = ABProgressIndicator()

    private let fakeThumbnailsContainer = UIView()
    private var fakeThumbnailImageViews = [UIImageView]()
    
    private var duration: Float64 = 0
    private var progressPercentage: CGFloat = 0         // Represented in percentage
    private var isReceivingGesture: Bool = false

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

        // Setup Progress Indicator

        let progressDrag = UIPanGestureRecognizer(
            target:self,
            action: #selector(progressDragged(recognizer:))
        )
        
        progressIndicator.addGestureRecognizer(progressDrag)
        self.addSubview(progressIndicator)

        // Setup time labels
        
        self.addSubview(progressTimeView)
        
        // Setup fake previews
        
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
    
    public func setCurrentTime(_ time: CMTime) {
        guard !isReceivingGesture, time.seconds <= duration else {
            return
        }
        
        self.progressPercentage = self.valueFromSeconds(seconds: Float(time.seconds))

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

        let progressSeconds = secondsFromValue(value: progressPercentage)

        self.delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: progressSeconds)

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

    override public func layoutSubviews() {
        super.layoutSubviews()

        progressTimeView.timeLabel.text = self.secondsToFormattedString(
            totalSeconds: secondsFromValue(value: self.progressPercentage)
        )
        
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
