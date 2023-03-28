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

class HistoryCollectionViewCell: UICollectionViewCell {
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
    @IBOutlet private weak var questionMark: UIButton!
    
    /*private var videoURL: String? {
        guard let eventDate = event?.date else {
            return nil
        }
        return self.getVideoUrl(from: eventDate)
    }*/
    
    private(set) var disposeBag = DisposeBag()
    
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapOnVideo))
        doubleTap.numberOfTapsRequired = 2
        videoPlayerViewContainer.addGestureRecognizer(doubleTap)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
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
        videoPlayerViewContainer.backgroundColor = .black
        let label = (offset > 0) ? UILabel(text: "+\(abs(offset)) сек") : UILabel(text: "-\(abs(offset)) сек")
        label.font = UIFont(name: "System", size: 16)
        label.font = label.font.bold
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: 0, width: 100, height: 21)
        label.center = CGPoint(x: videoPlayerViewContainer.width * ((offset > 0) ? 3 : 1) / 4, y: videoPlayerViewContainer.height / 2)
        label.textColor = .white
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
        token: String? = nil
    ) {
        self.event = value
        
        if let camera = camera {
            self.camera = CameraObject(id: camera.id, url: camera.url, token: camera.token, serverType: camera.serverType)
        } else {
            self.camera = nil
        }
        
        callStatusView.isHidden = true
        descriptionLabel.isHidden = false
        descriptionLabel.text = ""
        
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
        }
        player = nil
    
        scrollView.contentOffset = .zero
        
        let df = DateFormatter()
        df.dateFormat = "EEEE, d MMMM HH:mm"
        dateLabel.text = df.string(from: value.date)
        
        // настраиваем отображение поля с описанием
        descriptionLabel.text = value.detail
        descriptionLabel.isHidden = (descriptionLabel.text ?? "").isEmpty
        
        addressLabel.text = value.mechanizmaDescription
        var faceFrameColor = UIColor.red
        
        switch value.event {
        case .answered:
            titleLabel.text = "Звонок в домофон"
            titleLabel.textColor = UIColor(named: "semiBlack")
            callStatusView.isHidden = false
            descriptionLabel.isHidden = true
            callStatusLabel.text = "Отвеченный вызов"
            callStatusLabel.textColor = UIColor(named: "darkGreen")
            callStatusIcon.image = UIImage(named: "AnsweredCall")
        case .unanswered:
            titleLabel.text = "Звонок в домофон"
            titleLabel.textColor = UIColor(named: "semiBlack")
            callStatusView.isHidden = false
            descriptionLabel.isHidden = true
            callStatusLabel.text = "Неотвеченный вызов"
            callStatusLabel.textColor = UIColor(named: "incorrectDataRed")
            callStatusIcon.image = UIImage(named: "MissedCall")
        case .rfid:
            titleLabel.text = "Открывание ключом"
            titleLabel.textColor = UIColor(named: "semiBlack")
        case .app:
            titleLabel.text = "Открытие из приложения"
            titleLabel.textColor = UIColor(named: "semiBlack")
        case .face:
            titleLabel.text = "Открывание по лицу"
            titleLabel.textColor = UIColor(named: "semiBlack")
            faceFrameColor = .green
        case .passcode:
            titleLabel.text = "Открытие по коду"
            titleLabel.textColor = UIColor(named: "semiBlack")
        case .call:
            titleLabel.text = "Открытие ворот по звонку"
            titleLabel.textColor = UIColor(named: "semiBlack")
        case .plate:
            titleLabel.text = "Открытие ворот по номеру"
            titleLabel.textColor = UIColor(named: "semiBlack")
        case .unknown:
            titleLabel.text = "Неизвестное событие"
            titleLabel.textColor = UIColor(named: "incorrectDataRed")
        }
        image.image = nil
    
        if value.previewImage == nil {
            image.loadImageUsingUrlString(
                urlString: value.previewURL ?? "",
                cache: cache,
                label: underImageLabel,
                errorMessage: "Изображение отсутствует",
                rect: value.detailX?.face?.asCGRect,
                rectColor: faceFrameColor
            )
        } else {
            image.image = value.previewImage
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
                actionsDescriptionLabel.text = "При выборе «‎Чужой»‎ мы удалим ваше зарегистрированное лицо, на какое произошло ложное срабатывание наших алгоритмов.\nВсе лица, зарегистрированные в системе, можно найти в разделе Настройки адресов -> Управление доступом -> Вход по лицу без ключа."
            } else {
                openAccessButton.isHidden = false
                // swiftlint:disable:next line_length
                actionsDescriptionLabel.text = "При выборе «‎Свой»‎ мы добавим фотографию из этого события, для дальнейшего распознавания пользователя по лицу.\nВсе лица, зарегистрированные в системе, можно найти в разделе Настройки адресов -> Управление доступом -> Вход по лицу без ключа."
                
            }
            
        } else {
            // нет выбора лайк-дизлайк
            actionsContainer.isHidden = true
        }
    }

}
