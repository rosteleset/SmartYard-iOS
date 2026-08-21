//
//  HistoryCollectionViewCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 24.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

final class HistoryCollectionViewCell: UICollectionViewCell, HasDisposeBag {
    private var camera: CameraObject? // APICamMap?
    private var itIsMe: Bool?
    private var event: APIPlog?
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeShift: Double = 0.0
    
    private var doubleTap: UITapGestureRecognizer!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var actionsContainer: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var image: SafeCachedImageView!
    @IBOutlet private weak var underImageLabel: UILabel!
    @IBOutlet private weak var openAccessButton: UIButton!
    @IBOutlet private weak var denyAccessButton: UIButton!
    @IBOutlet private weak var videoPlayerViewContainer: UIView!
    @IBOutlet private weak var callStatusView: UIStackView!
    @IBOutlet private weak var callStatusIcon: UIImageView!
    @IBOutlet private weak var callStatusLabel: UILabel!
    @IBOutlet private weak var actionsDescriptionLabel: UILabel!
    @IBOutlet private weak var questionMark: CircleIconControl!
    @IBOutlet private weak var descriptionContainer: UIView!
    @IBOutlet private weak var mainStackView: UIStackView!

    private let trackingActionsStackView = UIStackView.vertical(spacing: 8)
    private let trackingContainerView = UIView()
    private let trackingSwitch = UISwitch()
    private let trackingTitleLabel = UILabel()
    private let trackingCommentsLabel = UILabel()
    
    /*private var videoURL: String? {
        guard let eventDate = event?.date else {
            return nil
        }
        return self.getVideoUrl(from: eventDate)
    }*/
    
    
    var itsMeTrigger: Driver<APIPlog> {
        return openAccessButton.rx.tap
            .map { [weak self] in self?.event }
            .ignoreNil()
            .asDriverOnErrorJustComplete()
    }
    
    var itsNotMeTrigger: Driver<APIPlog> {
        return denyAccessButton.rx.tap
            .map { [weak self] in self?.event }
            .ignoreNil()
            .asDriverOnErrorJustComplete()
    }
    
    var displayHintTrigger: Driver<Void> {
        return questionMark.rx.tap.asDriver()
    }

    var trackingToggleChanged: Driver<(APIPlog, Bool)> {
        return trackingSwitch.rx.controlEvent(.valueChanged)
            .map { [weak self] _ -> (APIPlog, Bool)? in
                guard let self = self, let event = self.event else { return nil }
                return (event, self.trackingSwitch.isOn)
            }
            .ignoreNil()
            .asDriverOnErrorJustComplete()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapOnVideo))
        doubleTap.numberOfTapsRequired = 2
        videoPlayerViewContainer.addGestureRecognizer(doubleTap)
        descriptionContainer.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
        setupTrackingView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resetDisposeBag()
        trackingContainerView.isHidden = true
        trackingCommentsLabel.text = nil
        trackingCommentsLabel.isHidden = true
    }
    
    @objc func doubleTapOnVideo(_ sender: UITapGestureRecognizer) {
        
        guard self.player?.currentItem?.status == .readyToPlay else {
            return
        }
        
        var offset = 0
        
        if sender.location(in: videoPlayerViewContainer).x < videoPlayerViewContainer.width / 2 - 10 {
            offset = -10
        }
        
        if sender.location(in: videoPlayerViewContainer).x > videoPlayerViewContainer.width / 2 + 10 {
            offset = 10
        }
        
        if offset == 0 {
            return
        }
        
        seekVideo(offsetSeconds: offset)
        let secText = L10n.Common.Time.secondsShort
        videoPlayerViewContainer.backgroundColor = .black
        let label = (offset > 0) ? UILabel(text: "+\(abs(offset)) \(secText)") : UILabel(text: "-\(abs(offset)) \(secText)")
        label.font = UIFont(name: "System", size: 16)
        label.font = label.font.bold
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: 0, width: 100, height: 21)
        label.center = CGPoint(x: videoPlayerViewContainer.width * ((offset > 0) ? 3 : 1) / 4, y: videoPlayerViewContainer.height / 2)
        label.textColor = .SmartYard.secondBackgroundColor
        label.backgroundColor = .clear
        videoPlayerViewContainer.view.addSubview(label)
        
        UIView.animate(
            withDuration: 1.5,
            animations: {
                label.alpha = 0
            },
            completion: { [weak self] _ in
                label.removeFromSuperview()
                self?.videoPlayerViewContainer.backgroundColor = .clear
            }
        )
    }
    
    func playVideo(eventDate: Date? = nil) {
        if eventDate == nil { timeShift = 0 }
        
        guard let eventDate = eventDate ?? event?.date, let camera = self.camera else {
            return
        }
        
        let startDate = camera.seekable ? eventDate.adding(.minute, value: -5) : eventDate
        let endDate = eventDate.adding(.minute, value: 5)
        
        camera.getArchiveVideo(startDate: startDate, endDate: endDate, speed: 1.0) { [weak self] videoURL in
            // по умолчанию грузим 10 минутный интервал по 5 минут туда-сюда от события
            DispatchQueue.main.async { [weak self] in
                guard let self = self,
                      let url = URL(string: videoURL) else {
                    return
                }
                self.player = AVPlayer(url: url)
                if camera.seekable {
                    self.player?.seek(to: CMTime(seconds: 5 * 60, preferredTimescale: 1))
                }
                
                if self.playerLayer != nil {
                    self.playerLayer?.removeFromSuperlayer()
                }
                
                self.playerLayer = AVPlayerLayer(player: self.player)
                self.videoPlayerViewContainer.layer.addSublayer(self.playerLayer!)
                self.playerLayer?.frame = self.videoPlayerViewContainer.frame
                self.playerLayer?.backgroundColor = UIColor.clear.cgColor
                
                self.player?.play()
            }
        }
    }
    
    func stopVideo() {
        player?.pause()
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
        }
        player = nil
    }
    
    func seekVideo(offsetSeconds: Int) {
        guard let player = player, let camera = self.camera, let event = self.event else {
            return
        }
        
        let seekTo = player.currentTime() + CMTime(seconds: Double(offsetSeconds), preferredTimescale: 1)
        if camera.seekable {
            if seekTo > CMTime.zero && seekTo < CMTime(seconds: 10 * 60, preferredTimescale: 1) {
                player.seek(to: seekTo)
                player.play()
            }
        } else {
            stopVideo()
            timeShift += seekTo.seconds
            playVideo(eventDate: event.date.addingTimeInterval(timeShift) )
        }
        
    }
    
    /*fileprivate func getVideoUrl(from startDate: Date, duration: Int = 60) -> String? {
        
        guard let camera = self.camera else {
            return nil
        }
        
        let endDate = startDate.adding(.second, value: duration)
        
        return camera.archiveURL(startDate: startDate, endDate: endDate)
    }*/
    
    func configure(
        value: APIPlog,
        using cache: NSCache<NSString, UIImage>,
        camera: APICamMap? = nil,
        token: String? = nil,
        trackedEvent: APITrackedEvent? = nil,
        isEventTrackingEnabled: Bool = false
    ) {
        self.event = value
        
        if let camera = camera {
            self.camera = CameraObject(id: camera.id, url: camera.url, token: camera.token, serverType: camera.serverType, hlsMode: camera.hlsMode, hasSound: camera.hasSound)
        } else {
            self.camera = nil
        }

        questionMark.apply(style: .Others.question)
        configureTrackingView(
            event: value,
            trackedEvent: trackedEvent,
            isEventTrackingEnabled: isEventTrackingEnabled
        )
        callStatusView.isHidden = true
        descriptionLabel.isHidden = false
        descriptionLabel.text = ""
        
        let denyTitle = L10n.Common.deny
        let openTitle = L10n.Common.allow
        
        denyAccessButton.setTitleForAllStates(denyTitle)
        openAccessButton.setTitleForAllStates(openTitle)
        
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
        }
        player = nil
    
        scrollView.contentOffset = .zero
        
        let df = DateFormatter()
        df.timeZone = Calendar.serverCalendar.timeZone
        df.locale = Calendar.current.locale
        
        df.dateFormat = "EEEE, d MMMM HH:mm"
        dateLabel.text = df.string(from: value.date)
        
        // настраиваем отображение поля с описанием
        descriptionLabel.text = value.detail
        descriptionLabel.isHidden = (descriptionLabel.text ?? "").isEmpty
        
        addressLabel.text = value.mechanizmaDescription
        let faceFrameColor = configureTitle(for: value.event)
        resetImageView()

        if let previewImage = value.previewImage {
            image.image = previewImage
        } else if let previewURL = value.previewURL, !previewURL.isEmpty {
            image.loadImageUsingUrlString(
                urlString: previewURL,
                cache: cache,
                label: underImageLabel,
                errorMessage: L10n.History.Event.imageMissing,
                rect: value.detailX?.face?.asCGRect,
                rectColor: faceFrameColor
            )
        } else {
            configureMissingImage()
        }
        
        if let flags = value.detailX?.flags,
           ( flags.contains("canDislike") || flags.contains("canDisLike") || flags.contains("canLike") ) {
            actionsContainer.isHidden = false
            actionsDescriptionLabel.text = ""
            denyAccessButton.isHidden = true
            openAccessButton.isHidden = true

            if flags.contains("canDislike") || flags.contains("canDisLike") {
                denyAccessButton.isHidden = false
                // swiftlint:disable:next line_length
                actionsDescriptionLabel.text = L10n.History.Event.guestDeniedHint
            } else {
                openAccessButton.isHidden = false
                // swiftlint:disable:next line_length
                actionsDescriptionLabel.text = L10n.History.Event.guestAllowedHint

            }

        } else {
            // нет выбора лайк-дизлайк
            actionsContainer.isHidden = true
        }
    }

    private func configureTitle(for eventType: APIPlog.EventType) -> UIColor {
        switch eventType {
        case .answered:
            titleLabel.text = L10n.Intercom.Incoming.title
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            callStatusView.isHidden = false
            descriptionLabel.isHidden = true
            callStatusLabel.text = L10n.History.Event.answeredCall
            callStatusLabel.textColor = UIColor.SmartYard.darkGreen
            callStatusIcon.image = UIImage(named: "AnsweredCall")
            return .red
        case .unanswered:
            titleLabel.text = L10n.Intercom.Incoming.title
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            callStatusView.isHidden = false
            descriptionLabel.isHidden = true
            callStatusLabel.text = L10n.History.Event.missedCall
            callStatusLabel.textColor = UIColor.SmartYard.incorrectDataRed
            callStatusIcon.image = UIImage(named: "MissedCall")
            return .red
        case .rfid:
            titleLabel.text = L10n.History.Event.openingWithKey
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            return .red
        case .app:
            titleLabel.text = L10n.History.Event.openingFromApp
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            return .red
        case .face:
            titleLabel.text = L10n.History.Event.openingWithFaceID
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            return .green
        case .passcode:
            titleLabel.text = L10n.History.Event.openingWithCode
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            return .red
        case .call:
            titleLabel.text = L10n.History.Event.gateOpeningOnCall
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            return .red
        case .plate:
            titleLabel.text = L10n.History.Event.gateOpeningByNumberplate
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            return .red
        case .reserved, .unknown:
            titleLabel.text = L10n.History.Event.unknown
            titleLabel.textColor = UIColor.SmartYard.incorrectDataRed
            return .red
        }
    }

}

private extension HistoryCollectionViewCell {
    func resetImageView() {
        image.image = nil
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.backgroundColor = .SmartYard.grayBorder
        underImageLabel.text = nil
        underImageLabel.font = .SourceSansPro.semibold(size: 14)
        underImageLabel.textAlignment = .center
        underImageLabel.textColor = .SmartYard.semiBlack
        underImageLabel.numberOfLines = 0
        underImageLabel.superview?.bringSubviewToFront(underImageLabel)
        questionMark.superview?.bringSubviewToFront(questionMark)
    }

    func configureMissingImage() {
        underImageLabel.text = L10n.History.Event.imageMissing
    }

    func setupTrackingView() {
        guard let actionsContainer else { return }

        trackingContainerView.backgroundColor = .SmartYard.secondBackgroundColor
        trackingContainerView.layer.cornerRadius = 12
        trackingContainerView.clipsToBounds = true
        trackingContainerView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
        trackingContainerView.isHidden = true

        trackingTitleLabel.font = .SourceSansPro.regular(size: 14)
        trackingTitleLabel.textColor = .SmartYard.semiBlack
        trackingTitleLabel.numberOfLines = 0
        trackingTitleLabel.text = L10n.History.EventTracking.toggleTitle

        trackingSwitch.onTintColor = .SmartYard.darkGreen

        trackingCommentsLabel.font = .SourceSansPro.regular(size: 12)
        trackingCommentsLabel.textColor = .SmartYard.gray
        trackingCommentsLabel.numberOfLines = 0
        trackingCommentsLabel.isHidden = true

        let row = UIStackView.horizontal(spacing: 12, alignment: .center).add {
            trackingTitleLabel
            trackingSwitch
        }

        let stack = UIStackView.vertical(spacing: 8).add {
            row
            trackingCommentsLabel
        }

        trackingContainerView.pinSubview(stack, with: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20))

        let insertIndex = min(7, mainStackView.arrangedSubviews.count)
        mainStackView.removeArrangedSubview(actionsContainer)
        actionsContainer.removeFromSuperview()
        trackingActionsStackView.add {
            trackingContainerView
            actionsContainer
        }
        mainStackView.insert(at: insertIndex) {
            trackingActionsStackView
        }
    }

    func configureTrackingView(
        event: APIPlog,
        trackedEvent: APITrackedEvent?,
        isEventTrackingEnabled: Bool
    ) {
        let canTrack = isEventTrackingEnabled && ParanoidEventTracking.isSupported(event)
        trackingContainerView.isHidden = !canTrack

        guard canTrack else { return }

        trackingSwitch.setOn(trackedEvent != nil, animated: false)
        let comments = trackedEvent?.normalizedComments ?? ""
        trackingCommentsLabel.text = comments
        trackingCommentsLabel.isHidden = comments.isEmpty
    }
}

extension HistoryCollectionViewCell {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        descriptionContainer.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }
    
}
