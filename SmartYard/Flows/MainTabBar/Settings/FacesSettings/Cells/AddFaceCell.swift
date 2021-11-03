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

class AddFaceCell: UICollectionViewCell {

    @IBOutlet private weak var button: UIButton!
    private(set) var disposeBag = DisposeBag()
    
    private var buttonTrigger: Driver<Void> {
        return button.rx.tap.asDriver()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
  
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    func configure(onTapHandler: @escaping () -> Void) {
        buttonTrigger
            .drive(
                onNext: { onTapHandler() }
            )
            .disposed(by: disposeBag)
    }
}
