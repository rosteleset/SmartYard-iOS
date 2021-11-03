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

    private var disposeBag = DisposeBag()
    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet private weak var imageButton: SafeCachedButton!
    
    private(set) var faceId: Int?
    
    private var deleteButtonTrigger: Driver<Void> {
        return deleteButton.rx.tap
            .asDriver()
    }
    
    private var imageButtonTrigger: Driver<Void> {
        return imageButton.rx.tap
            .asDriver()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    func reset() {
        imageButton.setImage(nil, for: .normal)
    }
    
    func getImage() -> UIImage? {
        imageButton.image(for: .normal)
    }
    func configure(
        faceId: Int,
        faceImageURL: String,
        onTapHandler: @escaping (_ faceId: Int) -> Void,
        onDeleteHandler: @escaping (_ faceId: Int) -> Void
    ) {
        imageButton.loadImageUsingUrlString(urlString: faceImageURL, cache: imagesCache)
        imageButton.contentMode = .scaleAspectFit
        self.faceId = faceId
        
        deleteButton.isHidden = false
        
        deleteButtonTrigger
            .drive(
                onNext: { [weak self] in
                    guard let faceId = self?.faceId else {
                        return
                    }
                    onDeleteHandler(faceId)
                }
            )
            .disposed(by: disposeBag)
        
        imageButtonTrigger
            .drive(
                onNext: { [weak self] in
                    guard let faceId = self?.faceId else {
                        return
                    }
                    onTapHandler(faceId)
                }
            )
            .disposed(by: disposeBag)
    }
}
