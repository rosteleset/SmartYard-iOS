//
//  DetailsViewTableCell.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 18.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit

class DetailsViewTableCell: UITableViewCell {
    
    @IBOutlet private weak var detailImage: UIImageView!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var detailSummaLabel: UILabel!
    @IBOutlet private weak var detailDateLabel: UILabel!
 
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with detail: DetailObject) {
        detailImage.image = detail.type.icon
        detailLabel.text = detail.title

        let formattedBalance = detail.summa == 0 ? "0" : String(format: "%.0f", detail.summa)
        detailSummaLabel.text = formattedBalance + "₽"
        
        let formatter = DateFormatter()

        formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
        formatter.dateFormat = "dd.MM.yyyy"
        
        detailDateLabel.text = formatter.string(from: detail.date)
    }
    
}
