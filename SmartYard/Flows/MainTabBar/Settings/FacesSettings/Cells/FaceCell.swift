//
//  FaceCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 12.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FaceCell: UICollectionViewCell {

    private(set) var disposeBag = DisposeBag()
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var imageButton: SafeCachedButton!
    
    var faceId: Int = 0
    
    var deleteButtonTrigger: Driver<Int> {
        return deleteButton.rx.tap
            .map { [weak self] in self?.faceId ?? 0 }
            .asDriver(onErrorJustReturn: 0)
    }
    
    var imageButtonTrigger: Driver<Int> {
        return imageButton.rx.tap
            .map { [weak self] in self?.faceId ?? 0 }
            .asDriver(onErrorJustReturn: 0)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

}
