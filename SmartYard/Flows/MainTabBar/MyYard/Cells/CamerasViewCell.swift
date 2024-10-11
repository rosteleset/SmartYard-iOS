//
//  CamerasViewCell.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 08.04.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit
import Lottie
import Kingfisher

class CamerasViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var previewImage: UIImageView!
    @IBOutlet private weak var loadingAnimationView: LottieAnimationView!
    @IBOutlet private weak var imageTimeLabel: UILabel!

    weak var delegate: MyYardCellProtocol?
    private var urlString: String?
    var camera: CameraExtendedObject?
    private let downloader = ImageDownloader.default
    private let cache = ImageCache.default
    private var downloadTask: DownloadTask?
    private var dateTimeOriginal: Date?
    private var timer: Timer?
    private var timerInterval: Timer?
    private var dateCache: NSCache<NSString, NSDate>?
    private let formatterIntervalDay = DateComponentsFormatter()
    private let formatterIntervalHour = DateComponentsFormatter()
    private let formatterIntervalMinute = DateComponentsFormatter()
    private let formatterInterval = DateComponentsFormatter()
    private var intervalText: String?
    private var updateLock: Bool = false

    func stopAllRefresh() {
        downloadTask?.cancel()
        timer?.invalidate()
        timerInterval?.invalidate()
        updateLock = true
        previewImage.kf.cancelDownloadTask()

        guard let urlString = urlString, cache.isCached(forKey: urlString), let url = URL(string: urlString) else {
            return
        }
        
        downloadTask = previewImage.kf.setImage(with: url)
    }
    
    func restoreAllRefresh() {
        updateLock = false
    }
    
    private func setup() {
        previewImage.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapImage(_:)))
        previewImage.addGestureRecognizer(tapGesture)
        
        formatterInterval.unitsStyle = .short
        formatterInterval.calendar?.locale = .current
        formatterInterval.allowedUnits = [.second]

        formatterIntervalMinute.unitsStyle = .short
        formatterIntervalMinute.calendar?.locale = .current
        formatterIntervalMinute.allowedUnits = [.minute]

        formatterIntervalHour.unitsStyle = .short
        formatterIntervalHour.calendar?.locale = .current
        formatterIntervalHour.allowedUnits = [.hour]

        formatterIntervalDay.unitsStyle = .short
        formatterIntervalDay.calendar?.locale = .current
        formatterIntervalDay.allowedUnits = [.day]
    }

    @objc func handleTapImage(_ sender: UITapGestureRecognizer) {
        self.delegate?.didTapPreviewImage(for: self)
    }
    
//    private func viewLoader() {
//        let animation = LottieAnimation.named("LoaderAnimation")
//        
//        loadingAnimationView.animation = animation
//        loadingAnimationView.loopMode = .loop
//        loadingAnimationView.backgroundBehavior = .pauseAndRestore
//    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setup()
//        viewLoader()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    func updateImage() {
        downloadTask?.cancel()
        timer?.invalidate()
        
        guard let urlString = urlString, let dateCache = dateCache, let url = URL(string: urlString), !updateLock else {
            return
        }

        let retry = DelayRetryStrategy(maxRetryCount: 5, retryInterval: .accumulated(2))
        let processor = ExifProcessor(dateCache: dateCache, urlString: urlString) |> DownsamplingImageProcessor(size: self.previewImage.size)
        let options: [KingfisherOptionsInfoItem] = [.processor(processor), .scaleFactor(UIScreen.main.scale), .forceRefresh, .retryStrategy(retry)]
        
        downloadTask = downloader.downloadImage(with: url, options: options) { [weak self] result in
            guard let self = self else {
                return
            }
            switch (result) {
            case .success(let image):
//                self.loadingAnimationView.isHidden = true
//                self.loadingAnimationView.stop()
                    
                DispatchQueue.main.async {
                    if let date = dateCache.object(forKey: urlString as NSString) as? Date {
                        self.dateTimeOriginal = date
                        self.updateInterval()
                    }
//                    let blurImage = image.image.kf.blurred(withRadius: 25)
                    self.cache.store(image.image, forKey: urlString)
                    self.previewImage.image = image.image
                    self.updateTimer(6)
                }
            case .failure(let error):
//                print(error.errorDescription)
                DispatchQueue.main.async {
                    self.updateTimer(15)
                }
            }
        }
    }
    
    private func updateInterval() {
        timerInterval?.invalidate()
        
        guard let imageDate = dateTimeOriginal else {
            imageTimeLabel.isHidden = true
            return
        }
        let interval = imageDate.distance(to: Date())
        intervalText = {
            if interval < 0 {
                return formatterInterval.string(from: 0)
            }
            switch interval {
            case 0..<60:
                return formatterInterval.string(from: interval)
            case 60..<3600:
                return formatterIntervalMinute.string(from: interval)
            case 3600..<86400:
                return formatterIntervalHour.string(from: interval)
            default:
                return formatterIntervalDay.string(from: interval)
            }
        }()
        
        DispatchQueue.main.async {
            self.imageTimeLabel.text = self.intervalText
            self.imageTimeLabel.isHidden = false
        }
        
        timerInterval = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.updateInterval()
        }
    }
    
    private func updateTimer(_ interval: TimeInterval) {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.updateImage()
        }
    }

    func configureCell(
        camera: CameraExtendedObject,
        urlString: String,
        dateCache: NSCache<NSString, NSDate>
    ) {
        loadingAnimationView.isHidden = true
        
        self.camera = camera
        self.urlString = urlString
        self.dateCache = dateCache
        self.updateLock = false
        self.dateTimeOriginal = nil
        self.timerInterval?.invalidate()
        self.imageTimeLabel.isHidden = true
        self.imageTimeLabel.layer.shadowRadius = 0.5
        self.imageTimeLabel.layer.shadowOffset = CGSizeMake(1, 1)
        self.imageTimeLabel.layer.shadowColor = UIColor.black.cgColor
        self.imageTimeLabel.layer.shadowOpacity = 1.0

        guard let url = URL(string: urlString) else {
            return
        }
        downloadTask?.cancel()
        timer?.invalidate()
        
        if cache.isCached(forKey: urlString) {
            previewImage.kf.cancelDownloadTask()
            downloadTask = previewImage.kf.setImage(with: url) { [weak self] result in
                guard let self = self else {
                    return
                }
                
                if let dateCache = self.dateCache, let date = dateCache.object(forKey: urlString as NSString) as? Date {
                    self.dateTimeOriginal = date
                    self.updateInterval()
                }
//                self.loadingAnimationView.isHidden = true
//                self.loadingAnimationView.stop()
                self.updateTimer(2)
            }
        } else {
            previewImage.image = nil
//            self.loadingAnimationView.isHidden = false
//            self.loadingAnimationView.play()
            
            let retry = DelayRetryStrategy(maxRetryCount: 5, retryInterval: .accumulated(2))
            let processor = ExifProcessor(dateCache: dateCache, urlString: urlString) |> DownsamplingImageProcessor(size: self.previewImage.size)
            let options: [KingfisherOptionsInfoItem] = [.processor(processor), .scaleFactor(UIScreen.main.scale), .cacheOriginalImage, .retryStrategy(retry)]
            downloadTask = downloader.downloadImage(with: url, options: options) { [weak self] result in
                guard let self = self else {
                    return
                }
                switch (result) {
                case .success(let image):
//                    self.loadingAnimationView.isHidden = true
//                    self.loadingAnimationView.stop()

                    DispatchQueue.main.async {
                        if let dateCache = self.dateCache, let date = dateCache.object(forKey: urlString as NSString) as? Date {
                            self.dateTimeOriginal = date
                            self.updateInterval()
                        }
                        
//                        let blurImage = image.image.kf.blurred(withRadius: 25)
                        self.cache.store(image.image, forKey: urlString)
                        self.previewImage.image = image.image
                        self.updateTimer(6)
                    }
                case .failure(let error):
//                    print(error.errorDescription)
                    DispatchQueue.main.async {
                        self.updateTimer(15)
                    }
                }
            }
        }
    }
}
