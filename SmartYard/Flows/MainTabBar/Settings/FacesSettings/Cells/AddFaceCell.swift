//
//  AddFaceCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 12.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class AddFaceCell: UICollectionViewCell, HasDisposeBag {

    @IBOutlet private weak var button: UIButton!
    
    private var buttonTrigger: Driver<Void> {
        return button.rx.tap.asDriver()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
  
    override func prepareForReuse() {
        super.prepareForReuse()
        resetDisposeBag()
    }
    
    func configure(onTapHandler: @escaping () -> Void) {
        buttonTrigger
            .drive(
                onNext: { onTapHandler() }
            )
            .disposed(by: disposeBag)
    }
}
