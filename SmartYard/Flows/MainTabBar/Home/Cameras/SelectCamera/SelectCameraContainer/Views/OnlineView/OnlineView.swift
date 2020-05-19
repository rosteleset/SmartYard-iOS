//
//  OnlineView.swift
//  SmartYard
//
//  Created by Mad Brains on 13.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import PMNibLinkableView
import RxCocoa
import RxSwift

class OnlineView: PMNibLinkableView {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var cameraImageView: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private var collectionViewHeightConstraint: NSLayoutConstraint!
    
    private let itemsProxy = BehaviorSubject<[CameraObject]>(value: [])
    private let itemStateChanged = PublishSubject<String>()
    
    private let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(nibWithCellClass: CameraNumberCell.self)
    }
    
    func bind(with cameras: Driver<[CameraObject]>) {
        cameras
            .drive(
                onNext: { [weak self] data in
                    self?.itemsProxy.onNext(data)
                    self?.collectionView.reloadData()
                }
            )
            .disposed(by: disposeBag)
        
        collectionView.rx
            .observeWeakly(CGSize.self, "contentSize")
            .subscribe(
                onNext: { [weak self] size in
                    guard let self = self, let uSize = size else {
                        return
                    }

                    self.collectionViewHeightConstraint.constant = uSize.height                    
                    self.layoutIfNeeded()
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension OnlineView: UICollectionViewDelegate {
    
    // TODO?
    
}

extension OnlineView: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let data = try? itemsProxy.value() else {
            return 0
        }

        return data.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let data = try? itemsProxy.value() else {
            return UICollectionViewCell()
        }
        
        let cell = collectionView.dequeueReusableCell(withClass: CameraNumberCell.self, for: indexPath)
        
        cell.configure(curCamera: data[indexPath.row])
        
        return cell
    }
    
}

extension OnlineView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 36, height: 36)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 28
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 24
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 18, left: 0, bottom: 18, right: 0)
    }
    
}
