//
//  AddressIntercomsViewCell.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 15.04.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit

class AddressIntercomsViewCell: UICollectionViewCell {
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pagerView: UIView!
    @IBOutlet private weak var pagerControl: UIPageControl!
    
    @IBOutlet private weak var pagerViewHeightConstraint: NSLayoutConstraint!
    
    private var delegate: MyYardIntercomsCellProtocol?
    var cameras: [CameraInversObject] = []
    var place: IntercomCamerasObject?
    var accessService: AccessService?
    var dateOriginalCache: NSCache<NSString, NSDate>?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    func updateCode(code: String) {
        self.place?.doorcode = code
        collectionView.reloadData()
    }
    
    func configureCell(
        intercom: IntercomCamerasObject,
        delegate: MyYardIntercomsCellProtocol?,
        accessService: AccessService,
        dateCache: NSCache<NSString, NSDate>
    ) {
        self.place = intercom
        self.cameras = intercom.cameras
        self.delegate = delegate
        self.accessService = accessService
        self.dateOriginalCache = dateCache
        
        pagerView.isHidden = cameras.count < 2
        pagerViewHeightConstraint.constant = cameras.count < 2 ? 0 : 24
        pagerControl.currentPage = 0
        pagerControl.numberOfPages = cameras.count
        
        pagerControl.addTarget(self, action: #selector(pageDidChange(sender:)), for: .valueChanged)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(nibWithCellClass: IntercomsViewCell.self)
        
        collectionView.reloadData()
    }
    
    @objc func pageDidChange(sender: UIPageControl) {
        let indexPath = IndexPath(row: pagerControl.currentPage, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
        stopAllPlayers()
    }
}

extension AddressIntercomsViewCell {
    func stopAllPlayers(_ camera: CameraInversObject? = nil) {
        for row in 0..<cameras.count {
            if let cell = collectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? IntercomsViewCell {
                if camera != cell.camera {
                    cell.stopPlayer()
                }
            }
        }
    }
    
    func stopAllRefresh() {
        for row in 0..<cameras.count {
            if let cell = collectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? IntercomsViewCell {
                cell.stopAllRefresh()
            }
        }
    }
    
    func restoreAllRefresh() {
        for row in 0..<cameras.count {
            if let cell = collectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? IntercomsViewCell {
                cell.restoreAllRefresh()
            }
        }
    }
    
    func reloadCollectionData() {
        collectionView.reloadData()
    }
}

extension AddressIntercomsViewCell: UICollectionViewDelegate {
    
}

extension AddressIntercomsViewCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cameras.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: IntercomsViewCell.self, for: indexPath)
        
        guard let intercom = place, let accessService = accessService, let dateCache = dateOriginalCache else {
            return cell
        }
        
        let previewString = accessService.backendURL + "/event/get/url/" + String(cameras[indexPath.row].camId)

        cell.configureCell(intercom: intercom, camera: cameras[indexPath.row], urlString: previewString, dateCache: dateCache)
        cell.delegate = self.delegate
        
        return cell
    }
}

extension AddressIntercomsViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let height = (UIScreen.main.bounds.width - 16) / 16 * 9 + 34
        return CGSize(width: UIScreen.main.bounds.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        pagerControl.currentPage = indexPath.row
        stopAllPlayers()
    }
}
