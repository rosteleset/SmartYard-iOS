//
//  HistoryTableViewCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 23.03.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

enum HistoryCellOrder: Equatable {
    case first
    case last
    case regular
    case single
}

final class HistoryTableViewCell: UITableViewCell {
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var dateView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var iconImage: UIImageView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var descriptionView: UIView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var bottomSpaceForLastCell: UIView!
    @IBOutlet private weak var topSpaceForFirst: UIView!
    private var descriptionLabelHidden: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        containerView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(cellOrder: HistoryCellOrder, from value: APIPlog) {
        dateLabel.text = ""
        dateView.isHidden = true
        
        switch cellOrder {
        // настраиваем отображение скруглений и вывод даты для первого элемента
        case .first, .single:
            
            if cellOrder == .single {
                containerView.layer.maskedCorners = [.topCorners, .bottomCorners]
                separatorView.isHidden = true
                topSpaceForFirst.isHidden = false
                bottomSpaceForLastCell.isHidden = false
            } else {
                containerView.layer.maskedCorners = [.topCorners]
                separatorView.isHidden = false
                topSpaceForFirst.isHidden = false
                bottomSpaceForLastCell.isHidden = true
            }
            
            let df = DateFormatter()
            df.timeZone = Calendar.serverCalendar.timeZone
            df.locale = Calendar.current.locale
            df.dateFormat = "EEEE, d MMMM"
            dateLabel.text = df.string(from: value.date)
            dateView.isHidden = false
            
        case .regular:
            separatorView.isHidden = false
            containerView.layer.maskedCorners = []
            dateLabel.text = ""
            dateView.isHidden = true
            topSpaceForFirst.isHidden = true
            bottomSpaceForLastCell.isHidden = true
            
        case .last:
            separatorView.isHidden = true
            containerView.layer.maskedCorners = [.bottomCorners]
            dateLabel.text = ""
            dateView.isHidden = true
            topSpaceForFirst.isHidden = true
            bottomSpaceForLastCell.isHidden = false
        }
        
        var description = value.detail
        
        // общие операции для всех ячеек, вне зависимости от их места в секции
        // настраиваем отображение иконки и заголовка
        switch value.event {
        case .answered:
            titleLabel.text = L10n.Intercom.Incoming.title
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            iconImage.image = UIImage(named: "LogsCall")
            description = ""
        case .unanswered:
            titleLabel.text = L10n.Intercom.Incoming.title
            titleLabel.textColor = UIColor.SmartYard.incorrectDataRed
            iconImage.image = UIImage(named: "LogsCall")
            description = ""
        case .rfid:
            titleLabel.text = L10n.History.Event.openingWithKey
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            iconImage.image = UIImage(named: "LogsKey")
            description = ""
        case .app:
            titleLabel.text = L10n.History.Event.openingFromApp
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            iconImage.image = UIImage(named: "LogsApp")
            description = ""
        case .face:
            titleLabel.text = L10n.History.Event.openingWithFaceID
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            iconImage.image = UIImage(named: "LogsFace")
            description = ""
        case .passcode:
            titleLabel.text = L10n.History.Event.openingWithCode
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            iconImage.image = UIImage(named: "LogsCode")
            description = ""
        case .call:
            titleLabel.text = L10n.History.Event.gateOpeningOnCall
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            iconImage.image = UIImage(named: "LogsWicket")
            description = ""
        case .plate:
            titleLabel.text = L10n.History.Event.gateOpeningByNumberplate
            titleLabel.textColor = UIColor.SmartYard.semiBlack
            iconImage.image = UIImage(named: "LogsWicket")
            description = ""
        case .unknown:
            titleLabel.text = L10n.History.Event.unknown
            titleLabel.textColor = UIColor.SmartYard.incorrectDataRed
            iconImage.image = UIImage(named: "LogsApp")
            description = ""
        }
        
        // настраиваем отображение поля с описанием
        descriptionView.isHidden = description.isEmpty
        descriptionLabel.text = description
        
        let df = DateFormatter()
        df.timeZone = Calendar.serverCalendar.timeZone
        df.locale = Calendar.current.locale
        df.dateFormat = "HH:mm"
        timeLabel.text = df.string(from: value.date)
        
    }
    
}

extension HistoryTableViewCell {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        containerView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }
        
}
