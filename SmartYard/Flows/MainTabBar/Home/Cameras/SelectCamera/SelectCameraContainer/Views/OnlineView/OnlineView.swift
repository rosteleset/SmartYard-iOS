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
import AVKit

protocol OnlineViewDelegate: AnyObject {
    
    func onlineView(_ onlineView: OnlineView, didSelectCamera camera: CameraObject)
    
}

class OnlineView: PMNibLinkableView {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var cameraContainer: UIView!
    
    @IBOutlet private var collectionViewHeightConstraint: NSLayoutConstraint!
    
    private var player: AVPlayer?
    private var playerView: UIView?
    
    private var cameras = [CameraObject]()
    private var selectedCameraNumber: Int?
    
    private let disposeBag = DisposeBag()
    
    weak var delegate: OnlineViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureCollectionView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        playerView?.frame = cameraContainer.bounds
    }
    
    func setPlayer(_ player: AVPlayer, playerView: UIView) {
        playerView.removeFromSuperview()

        self.player = player
        self.playerView = playerView

        cameraContainer.addSubview(playerView)
    }
    
    func setCameras(_ cameras: [CameraObject], selectedCamera: CameraObject?) {
        self.cameras = cameras
        
        collectionView.reloadData { [weak self] in
            guard let selectedCamera = selectedCamera,
                let index = cameras.firstIndex(of: selectedCamera) else {
                return
            }
            
            let indexPath = IndexPath(row: index, section: 0)
            
            self?.collectionView.selectItem(
                at: indexPath,
                animated: false,
                scrollPosition: .top
            )
            
            self?.reloadCameraIfNeeded(selectedIndexPath: indexPath)
        }
    }
    
    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(nibWithCellClass: CameraNumberCell.self)
        
        collectionView.rx
            .observeWeakly(CGSize.self, "contentSize")
            .subscribe(
                onNext: { [weak self] size in
                    guard let self = self, let uSize = size else {
                        return
                    }

                    self.collectionViewHeightConstraint.constant = uSize.height
                    self.setNeedsLayout()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func reloadCameraIfNeeded(selectedIndexPath: IndexPath) {
        let camera = cameras[selectedIndexPath.row]
        
        print("Selected Camera #\(camera.cameraNumber)")
        
        guard camera.cameraNumber != selectedCameraNumber else {
            return
        }
        
        selectedCameraNumber = camera.cameraNumber
        
        delegate?.onlineView(self, didSelectCamera: camera)

        player?.replaceCurrentItem(with: AVPlayerItem(url: camera.video))
        player?.play()
    }
    
}

extension OnlineView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        reloadCameraIfNeeded(selectedIndexPath: indexPath)
    }
    
}

extension OnlineView: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cameras.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: CameraNumberCell.self, for: indexPath)
        
        cell.configure(curCamera: cameras[indexPath.row])
        
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
