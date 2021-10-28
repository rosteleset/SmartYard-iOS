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

class HistoryTableViewCell: UITableViewCell {
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
            titleLabel.text = "Звонок в домофон"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsDomophone")
            description = ""
        case .unanswered:
            titleLabel.text = "Звонок в домофон"
            titleLabel.textColor = UIColor(named: "incorrectDataRed")
            iconImage.image = UIImage(named: "LogsDomophone")
            description = ""
        case .rfid:
            titleLabel.text = "Открывание ключом"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsKey")
            description = ""
        case .app:
            titleLabel.text = "Открытие из приложения"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsApp")
            description = ""
        case .face:
            titleLabel.text = "Открывание по лицу"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsFace")
            description = ""
        case .passcode:
            titleLabel.text = "Открытие по коду"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsCode")
            description = ""
        case .call:
            titleLabel.text = "Открытие ворот по звонку"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsCall")
            description = ""
        case .plate:
            titleLabel.text = "Открытие ворот по номеру"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsWicket")
            description = ""
        case .unknown:
            titleLabel.text = "Неизвестное событие"
            titleLabel.textColor = UIColor(named: "incorrectDataRed")
            iconImage.image = UIImage(named: "LogsApp")
            description = ""
        }
        
        // настраиваем отображение поля с описанием
        descriptionView.isHidden = description.isEmpty
        descriptionLabel.text = description
        
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        timeLabel.text = df.string(from: value.date)
        
    }
    
}
