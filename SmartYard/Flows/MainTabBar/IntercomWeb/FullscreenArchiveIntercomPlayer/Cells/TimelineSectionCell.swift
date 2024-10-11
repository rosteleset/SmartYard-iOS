//
//  TimelineSectionCell.swift
//  SmartYard
//
//  Created by devcentra on 13.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum TimelineCellOrder: Equatable {
    case big
    case middle
    case small
}

class TimelineSectionCell: UICollectionViewCell {
    
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var bigTimeCell: UIView!
    @IBOutlet private weak var middleTimeCell: UIView!
    @IBOutlet private weak var smallTimeCell: UIView!
    @IBOutlet private weak var bigTimeLabel: UILabel!
    @IBOutlet private weak var eventLineView: UIView!
    @IBOutlet private weak var eventMarkerView: UIView!
    @IBOutlet private weak var previewCameraHandler: UIView!
    @IBOutlet private weak var previewCameraImage: UIImageView!
    @IBOutlet private weak var multiEventsView: UIView!
    @IBOutlet private weak var viewEventView: UIView!
    @IBOutlet private weak var imageEventView: UIImageView!
    
    @IBOutlet private weak var eventMarkerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var previewCameraImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var multiEventsViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var centerXPreviewConstraint: NSLayoutConstraint!
    @IBOutlet private weak var centerXMultiConstraint: NSLayoutConstraint!

    private var formatter = DateFormatter()
    private var widthThumb: CGFloat = 80
    private var thumbVisibled = false
    private var cellEvent: APIPlog?
    private var cellDate: Date?
    private var eventsCount: Int = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
        formatter.locale = Calendar.novokuznetskCalendar.locale

    }

    func reConfigureCell(_ todate: Date, delta: Int, itemHeight: CGFloat) {
        guard let date = cellDate, let isEvent = cellEvent else {
            return
        }
        let dateinterval = abs(todate.timeIntervalSince(date))
        let height = Double(100 / itemHeight)
        if dateinterval < Double(delta) * height {
            let width = widthThumb * (1.3 - 0.3 * dateinterval / Double(delta) / height)
            UIView.animate(
                withDuration: 0.2,
                animations: {
                    self.centerXPreviewConstraint.constant = width / 2
                    self.previewCameraImageWidthConstraint.constant = width
                    if self.eventsCount > 1 {
                        self.centerXMultiConstraint.constant = width / 2 + 4
                        self.multiEventsViewWidthConstraint.constant = width
                    }
                }
            )
        } else {
            centerXPreviewConstraint.constant = widthThumb / 2
            previewCameraImageWidthConstraint.constant = widthThumb
            if eventsCount > 1 {
                centerXMultiConstraint.constant = widthThumb / 2 + 4
                multiEventsViewWidthConstraint.constant = widthThumb
            }
        }
    }
    
    func configureCell(_ input: Input) {
        cellDate = input.time
        widthThumb = input.widthin
        thumbVisibled = false
        cellEvent = input.event
        previewCameraHandler.isHidden = !input.showThumb
        multiEventsView.isHidden = true
        eventsCount = 0

        if cellEvent != nil,
           let height = input.height {
            eventMarkerView.isHidden = false
            eventMarkerViewHeightConstraint.constant = height
            
            if input.showThumb {
                switch input.event?.event {
                case .answered:
                    imageEventView.image = UIImage(named: "EventAnswered")
                    viewEventView.isHidden = false
                case .app, .link:
                    imageEventView.image = UIImage(named: "EventApp")
                    viewEventView.isHidden = false
                case .call:
                    imageEventView.image = UIImage(named: "EventCall")
                    viewEventView.isHidden = false
                case .face:
                    imageEventView.image = UIImage(named: "EventFace")
                    viewEventView.isHidden = false
                case .passcode:
                    imageEventView.image = UIImage(named: "EventCode")
                    viewEventView.isHidden = false
                case .rfid:
                    imageEventView.image = UIImage(named: "EventKey")
                    viewEventView.isHidden = false
                case .unanswered:
                    imageEventView.image = UIImage(named: "EventNoAnswered")
                    viewEventView.isHidden = false
                default:
                    viewEventView.isHidden = true
                }
                eventsCount = input.countEvents
                if let date = input.todate {
                    reConfigureCell(date, delta: input.delta, itemHeight: input.itemHeight)
                } else {
                    centerXPreviewConstraint.constant = widthThumb / 2
                    previewCameraImageWidthConstraint.constant = widthThumb
                    if eventsCount > 1 {
                        centerXMultiConstraint.constant = widthThumb / 2 + 4
                        multiEventsViewWidthConstraint.constant = widthThumb
                    }
                }
                if let url = input.url {
                    if let image = input.cache.object(forKey: NSString(string: url.absoluteString)) {
                        previewCameraImage.image = image
                    } else {
                        previewCameraImage.image = nil
                        ScreenshotHelper.generateThumbnailFromVideoUrlAsync(
                            url: url,
                            forTime: .zero
                        ) { [weak self] cgImage in
                            guard let cgImage = cgImage else {
                                return
                            }
                            
                            DispatchQueue.main.async {
                                let image = UIImage(cgImage: cgImage)
                                self?.previewCameraImage.image = image
                                input.cache.setObject(image, forKey: NSString(string: url.absoluteString))
                            }
                        }
                    }
                }
            }
        } else {
            eventMarkerView.isHidden = true
        }
        eventLineView.backgroundColor = input.isInArchive ? UIColor.darkGray : UIColor.SmartYard.textAddon
        switch input.state {
        case .big:
            bigTimeLabel.text = formatter.string(from: input.time)
            bigTimeCell.isHidden = false
            middleTimeCell.isHidden = true
            smallTimeCell.isHidden = true
            bigTimeCell.backgroundColor = input.isInArchive ? .white : UIColor.darkGray
            bigTimeLabel.textColor = input.isInArchive ? .white : UIColor.darkGray
        case .middle:
            bigTimeLabel.text = ""
            bigTimeCell.isHidden = true
            middleTimeCell.isHidden = false
            smallTimeCell.isHidden = true
            middleTimeCell.backgroundColor = input.isInArchive ? .white : UIColor.darkGray
        case .small:
            bigTimeLabel.text = ""
            bigTimeCell.isHidden = true
            middleTimeCell.isHidden = true
            smallTimeCell.isHidden = false
            smallTimeCell.backgroundColor = input.isInArchive ? .white : UIColor.darkGray
        }
    }
}

extension TimelineSectionCell {
    struct Input {
        let time: Date
        let state: TimelineCellOrder
        let event: APIPlog?
        let showThumb: Bool
        let countEvents: Int
        let height: CGFloat?
        let widthin: CGFloat
        let url: URL?
        let isInArchive: Bool
        let todate: Date?
        let delta: Int
        let itemHeight: Double
        let cache: NSCache<NSString, UIImage>
    }
}
