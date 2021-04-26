//
//  HistoryCollectionViewCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 24.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class HistoryCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var actionsContainer: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var image: SafeCachedImageView!
    @IBOutlet private weak var openAccessButton: UIButton!
    @IBOutlet private weak var denyAccessButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(value: APIPlog, using cache: NSCache<NSString, UIImage>) {
        scrollView.contentOffset = .zero
        
        let df = DateFormatter()
        df.dateFormat = "EEEE, d MMMM HH:mm"
        dateLabel.text = df.string(from: value.date)
        
        //настраиваем отображение поля с описанием
        descriptionLabel.text = value.detail
        descriptionLabel.isHidden = (descriptionLabel.text ?? "").isEmpty
        
        addressLabel.text = value.mechanizmaDescription
        
        switch value.event {
        case .answered:
            titleLabel.text = "Звонок в домофон"
            titleLabel.textColor = UIColor(named: "semiBlack")
        case .unanswered:
            titleLabel.text = "Звонок в домофон"
            titleLabel.textColor = UIColor(named: "incorrectDataRed")
        case .rfid:
            titleLabel.text = "Открывание ключом"
            titleLabel.textColor = UIColor(named: "semiBlack")
        case .app:
            titleLabel.text = "Открытие из приложения"
            titleLabel.textColor = UIColor(named: "semiBlack")
        case .face:
            titleLabel.text = "Открывание по лицу"
            titleLabel.textColor = UIColor(named: "semiBlack")
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
        
        if value.previewImage == nil {
            image.loadImageUsingUrlString(urlString: value.previewURL ?? "", cache: cache)
        } else {
            image.image = value.previewImage
        }
        
        actionsContainer.isHidden = true
        
    }

}
