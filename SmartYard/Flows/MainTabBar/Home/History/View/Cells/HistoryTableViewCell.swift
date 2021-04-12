//
//  HistoryTableViewCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 23.03.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

enum HistoryCellOrder {
    case first
    case last
    case regular
}

class HistoryTableViewCell: UITableViewCell {
    //@IBOutlet private weak var previewImage: UIImageView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var iconImage: UIImageView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private var dateLabelConstraints: [NSLayoutConstraint]!
    @IBOutlet private var desсriptionLabelConstraints: [NSLayoutConstraint]!
    
    var cellOrder: HistoryCellOrder = .regular
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(cellOrder: HistoryCellOrder, from value: APIPlog) {
        switch cellOrder {
        //настраиваем отображение скруглений и вывод даты для первого элемента
        case .first:
            separatorView.isHidden = false
            containerView.layer.maskedCorners = [.topCorners]
            if !containerView.subviews.contains(dateLabel) {
                containerView.addSubview(dateLabel)
                dateLabelConstraints.forEach { $0.isActive = true }
            }
            
            let df = DateFormatter()
            df.dateFormat = "EEEE, d MMMM"
            dateLabel.text = df.string(from: value.date)
            
        case .regular:
            separatorView.isHidden = false
            containerView.layer.maskedCorners = []
            if containerView.subviews.contains(dateLabel) {
                dateLabel.removeFromSuperview()
            }
            
        case .last:
            separatorView.isHidden = true
            containerView.layer.maskedCorners = [.bottomCorners]
            if containerView.subviews.contains(dateLabel) {
                dateLabel.removeFromSuperview()
            }
        }
        
        //настраиваем отображение поля с описанием
        if value.detail.isEmpty {
            if containerView.subviews.contains(descriptionLabel) {
                descriptionLabel.removeFromSuperview()
            }
        } else {
            if !containerView.subviews.contains(descriptionLabel) {
                containerView.addSubview(descriptionLabel)
                desсriptionLabelConstraints.forEach { $0.isActive = true }
            }
        }
        
        //общие операции для всех ячеек, вне зависимости от их места в секции
        //настраиваем отображение иконки и заголовка
        switch value.event {
        case .answered:
            titleLabel.text = "Звонок в домофон"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsCall")
        case .unanswered:
            titleLabel.text = "Звонок в домофон"
            titleLabel.textColor = UIColor(named: "incorrectDataRed")
            iconImage.image = UIImage(named: "LogsCall")
        case .rfid:
            titleLabel.text = "Открывание ключом"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsKey")
        case .app:
            titleLabel.text = "Открытие из приложения"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsApp")
        case .face:
            titleLabel.text = "Открывание по лицу"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsFace")
        case .passcode:
            titleLabel.text = "Открытие по коду"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsKey")
        case .call:
            titleLabel.text = "Открытие ворот по звонку"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsWicket")
        case .plate:
            titleLabel.text = "Открытие ворот по номеру"
            titleLabel.textColor = UIColor(named: "semiBlack")
            iconImage.image = UIImage(named: "LogsWicket")
        case .unknown:
            titleLabel.text = "Неизвестное событие"
            titleLabel.textColor = UIColor(named: "incorrectDataRed")
            iconImage.image = UIImage(named: "LogsFace")
        }
        
        
    }
}
