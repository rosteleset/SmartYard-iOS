//
//  OnlinePageViewController.swift
//  SmartYard
//
//  Created by admin on 15.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AVKit
import TouchAreaInsets

protocol OnlinePageViewControllerDelegate: AnyObject {
    func onlinePageViewController(_ vc: OnlinePageViewController, didSelectCamera camera: CameraObject)
}

class OnlinePageViewController: BaseViewController {
    weak var delegate: OnlinePageViewControllerDelegate?
    
    // MARK: - Properties
    @IBOutlet private weak var camerasCollectionView: UICollectionView!
    @IBOutlet private weak var pointsCollectionView: UICollectionView!
    @IBOutlet private weak var camerasFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet private weak var pointsFlowLayout: UICollectionViewFlowLayout!
    
    private let buttonSize = CGSize(width: 36, height: 36)
    
    private var cameras = [CameraObject]()
    private var selectedCameraNumber: Int?
    private var focusedCellIndexPath: IndexPath?
    private var indexOfCellBeforeDragging = 0
    private var itemCountsPerCell: [Int] = []
    
    // MARK: - Initialization
    init() {
        super.init(nibName: nil, bundle: nil)
        
        title = NSLocalizedString("Online", comment: "")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if  let focusedCellIndexPath = self.focusedCellIndexPath {
            let cell = self.camerasCollectionView.cellForItem(at: focusedCellIndexPath) as? CameraCollectionViewCell
            cell?.player?.replaceCurrentItem(with: nil)
        }
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        bind()
    }

    override func viewDidLayoutSubviews() {
        configureFlowLayoutItemSize(flowLayout: camerasFlowLayout)
        configureFlowLayoutItemSize(flowLayout: pointsFlowLayout)
    }
    
    // MARK: - Public Methods
    func setCameras(_ cameras: [CameraObject], selectedCamera: CameraObject?) {
        self.cameras = cameras
        
        camerasCollectionView.reloadData { [weak self] in
            guard let selectedCamera = selectedCamera,
                  let index = cameras.firstIndex(of: selectedCamera) else {
                return
            }
            
            let selectedIndexPath = IndexPath(row: index, section: 0)
            self?.reloadCameraIfNeeded(selectedIndexPath: selectedIndexPath)
        }
        
        pointsCollectionView.reloadData()
    }
    
    // MARK: - Private Methods
    // swiftlint:disable:next function_body_length
    private func bind() {
        let didEnterBackground = NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let viewDidDisappear = rx.viewDidDisappear
            .asDriver()
            .mapToVoid()
        
        // При уходе с окна или при сворачивании приложения - паузим плеер
        
        Driver
            .merge(didEnterBackground, viewDidDisappear)
            .drive(
                onNext: { [weak self] _ in
                    if  let focusedCellIndexPath = self?.focusedCellIndexPath {
                        let cell = self?.camerasCollectionView.cellForItem(at: focusedCellIndexPath) as? CameraCollectionViewCell
                        cell?.player?.pause()
                    }
                }
            )
            .disposed(by: disposeBag)
    
        // При заходе на окно - запускаем плеер
        
        rx.viewDidAppear
            .asDriver()
            .drive(
                onNext: { [weak self] _ in
                    if  let focusedCellIndexPath = self?.focusedCellIndexPath {
                        let cell = self?.camerasCollectionView.cellForItem(at: focusedCellIndexPath) as? CameraCollectionViewCell
                        cell?.player?.play()
                    }
                    let rowsPerPage = self?.calculateRowsPerPageForPoints() ?? 1
                    
                    self?.calculateItemsPerCell(
                        totalItemCount: self?.cameras.count ?? 0,
                        itemsPerRow: 5,
                        rowsPerPage: rowsPerPage
                    )
                    let itemsPerPage = rowsPerPage * 5
                    let page = (self?.selectedCameraNumber ?? 1) / itemsPerPage
                    let pointsIndexPath = IndexPath(item: page, section: 0)
                    
                    DispatchQueue.main.async {
                        self?.pointsCollectionView.selectItem(
                            at: pointsIndexPath,
                            animated: true,
                            scrollPosition: .centeredHorizontally
                        )
                    }

                    self?.pointsCollectionView.reloadData()
                    self?.pointsCollectionView.isHidden = false
                }
            )
            .disposed(by: disposeBag)
        
        // При разворачивании приложения (если окно открыто) - запускаем плеер
        
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(rx.isVisible.asDriverOnErrorJustComplete())
            .isTrue()
            .drive(
                onNext: { [weak self] _ in
                    if  let focusedCellIndexPath = self?.focusedCellIndexPath {
                        let cell = self?.camerasCollectionView.cellForItem(at: focusedCellIndexPath) as? CameraCollectionViewCell
                        cell?.player?.play()
                    }
                }
            )
            .disposed(by: disposeBag)
        
    }
    
    private func configureCollectionView() {
        pointsCollectionView.register(nibWithCellClass: CameraNumberCell.self)
        camerasCollectionView.register(nibWithCellClass: CameraCollectionViewCell.self)
        pointsCollectionView.isHidden = true
    }
    
    private func reloadCameraIfNeeded(selectedIndexPath: IndexPath) {
        let camera = cameras[selectedIndexPath.row]
        let cell = camerasCollectionView.cellForItem(at: selectedIndexPath) as? CameraCollectionViewCell
        
        print("Selected Camera #\(camera.cameraNumber)")
        
        guard camera.cameraNumber != selectedCameraNumber else {
            return
        }
        
        selectedCameraNumber = camera.cameraNumber
        
        delegate?.onlinePageViewController(self, didSelectCamera: camera)
        
        cell?.player?.replaceCurrentItem(with: nil)
        
        camerasCollectionView.scrollToItem(
            at: selectedIndexPath,
            at: .centeredHorizontally,
            animated: true
        )
        
        camera.updateURLAndExec { [weak self] urlString in
            guard let self = self, let url = URL(string: urlString) else {
                return
            }
            cell?.startToPlay(url)
        }
    }
    
    fileprivate func calculateSectionInsetForCollection() -> CGFloat {
        let collectionViewWidth = camerasFlowLayout.collectionView!.frame.width
        let itemWidth: CGFloat = 280
        let inset = (collectionViewWidth - itemWidth) / 4
        return inset
    }
    
    fileprivate func configureFlowLayoutItemSize(flowLayout: UICollectionViewFlowLayout) {
        let inset: CGFloat = calculateSectionInsetForCollection()
        
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        flowLayout.itemSize = CGSize(
            width: flowLayout.collectionView!.frame.size.width - inset * 2,
            height: flowLayout.collectionView!.frame.size.height
        )
    }
    
    fileprivate func calculateRowsPerPageForPoints() -> Int {
        let collectionHeight = view.height - 36 - camerasCollectionView.height
        let inset = 10
        let rowHeight = buttonSize.height + CGFloat(inset)
        let rows = round(collectionHeight / rowHeight)
        return Int(rows)
    }
    
    fileprivate func calculateItemsPerCell(totalItemCount: Int, itemsPerRow: Int, rowsPerPage: Int) {
        let itemsPerPage = itemsPerRow * rowsPerPage
        
        let totalCells = totalItemCount / itemsPerPage
        let remainder = totalItemCount % itemsPerPage
        let additionalCells = remainder > 0 ? 1 : 0
        let totalPages = totalCells + additionalCells
        
        itemCountsPerCell = Array(repeating: itemsPerPage, count: totalCells)
        
        if remainder > 0 {
            itemCountsPerCell.append(remainder)
        }
    }
    
    private func onItemFocused(indexPath: IndexPath) {
        camerasCollectionView.layoutIfNeeded()
        let cell = camerasCollectionView.cellForItem(at: indexPath) as? CameraCollectionViewCell
        let camera = cameras[indexPath.row]
        
        print("Selected Camera #\(camera.cameraNumber)")
        
        guard camera.cameraNumber != selectedCameraNumber else {
            return
        }
        
        selectedCameraNumber = camera.cameraNumber
        
        delegate?.onlinePageViewController(self, didSelectCamera: camera)
        
        cell?.loadVideo()
    }
    
    private func onItemLostFocus(indexPath: IndexPath) {
        camerasCollectionView.layoutIfNeeded()
        let cell = camerasCollectionView.cellForItem(at: indexPath) as? CameraCollectionViewCell
        
        cell?.stopVideo()
    }
}

// MARK: - UICollectionViewDataSource
extension OnlinePageViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case camerasCollectionView:
            return cameras.count
        default:
            let rows = calculateRowsPerPageForPoints()
            let itemsPerPage = rows * 5
            return cameras.count % itemsPerPage == 0 ? cameras.count / itemsPerPage : (cameras.count / itemsPerPage) + 1
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        switch collectionView {
        case camerasCollectionView:
            let cell = collectionView.dequeueReusableCell(withClass: CameraCollectionViewCell.self, for: indexPath)
            cell.configure(curCamera: cameras[indexPath.row], cache: imagesCache)
            return cell
            
        default:
            let cell = collectionView.dequeueReusableCell(withClass: CameraNumberCell.self, for: indexPath)
            
            let rows = calculateRowsPerPageForPoints()
            let itemsPerPage = rows * 5
            
            let startIndex = indexPath.item * itemsPerPage
            let endIndex = min((indexPath.item + 1) * itemsPerPage, cameras.count)
            let dataChunk = Array(cameras[startIndex..<endIndex])
            
            if startIndex < cameras.count {
                let dataChunk = Array(cameras[startIndex..<endIndex])
                cell.configure(
                    with: dataChunk,
                    rows: rows,
                    selectedCameraNumber: selectedCameraNumber ?? 1
                )
                cell.delegate = self
            }
            
            return cell
        }
    }
    
}

// MARK: - UICollectionViewDelegateFlowLayout
extension OnlinePageViewController: UICollectionViewDelegateFlowLayout {
        
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == pointsCollectionView {
            indexOfCellBeforeDragging = indexOfMajorCellForPoints()
        } else if scrollView == camerasCollectionView {
            indexOfCellBeforeDragging = indexOfMajorCellForCameras()
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if scrollView == pointsCollectionView {
            targetContentOffset.pointee = scrollView.contentOffset
            
            let targetIndex: Int
            if velocity.x > 0 {
                targetIndex = indexOfCellBeforeDragging + 1
            } else if velocity.x < 0 {
                targetIndex = indexOfCellBeforeDragging - 1
            } else {
                let collectionViewWidth = pointsFlowLayout.collectionView!.bounds.width
                targetIndex = Int((targetContentOffset.pointee.x + collectionViewWidth / 2) / collectionViewWidth)
            }
            
            let safeTargetIndex = max(0, min(targetIndex, pointsCollectionView.numberOfItems(inSection: 0) - 1))
            
            let offset = CGFloat(safeTargetIndex) * pointsFlowLayout.itemSize.width
            targetContentOffset.pointee = CGPoint(x: offset, y: 0)
    
        } else if scrollView == camerasCollectionView {
            targetContentOffset.pointee = scrollView.contentOffset
            
            let indexOfMajorCell = self.indexOfMajorCellForCameras()
            
            // calculate conditions:
            let swipeVelocityThreshold: CGFloat = 0.5 // after some trail and error
            let hasEnoughVelocityToSlideToTheNextCell = indexOfCellBeforeDragging + 1 < cameras.count && velocity.x > swipeVelocityThreshold
            let hasEnoughVelocityToSlideToThePreviousCell = indexOfCellBeforeDragging - 1 >= 0 && velocity.x < -swipeVelocityThreshold
            let majorCellIsTheCellBeforeDragging = indexOfMajorCell == indexOfCellBeforeDragging
            let didUseSwipeToSkipCell = majorCellIsTheCellBeforeDragging && (hasEnoughVelocityToSlideToTheNextCell || hasEnoughVelocityToSlideToThePreviousCell)
            
            if didUseSwipeToSkipCell {
                let snapToIndex = indexOfCellBeforeDragging + (hasEnoughVelocityToSlideToTheNextCell ? 1 : -1)
                let toValue = camerasFlowLayout.itemSize.width * CGFloat(snapToIndex)
                
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 1,
                    initialSpringVelocity: velocity.x,
                    options: .allowUserInteraction,
                    animations: {
                        scrollView.contentOffset = CGPoint(x: toValue, y: 0)
                        scrollView.layoutIfNeeded()
                    },
                    completion: nil
                )
                
            } else {
                let indexPath = IndexPath(row: indexOfMajorCell, section: 0)
                camerasFlowLayout.collectionView!.scrollToItem(
                    at: indexPath,
                    at: .centeredHorizontally,
                    animated: true
                )
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if camerasCollectionView == scrollView {
            if !decelerate {
                updatePointCell()
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if camerasCollectionView == scrollView {
            updatePointCell()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCameraCell()
    }
    
    fileprivate func updateCameraCell() {
        guard let center = camerasCollectionView.getCenterPoint() else {
            return
        }
        guard let indexPath = camerasCollectionView.indexPathForItem(at: center) else {
            return
        }
        
        if indexPath != focusedCellIndexPath {
            if let focusedCellIndexPath = focusedCellIndexPath {
                onItemLostFocus(indexPath: focusedCellIndexPath)
            }
            focusedCellIndexPath = indexPath
            onItemFocused(indexPath: indexPath)
        }
    }
    
    fileprivate func updatePointCell() {
        guard let center = camerasCollectionView.getCenterPoint() else {
            return
        }
        
        guard let indexPath = camerasCollectionView!.indexPathForItem(at: center) else {
            return
        }
        
        for cell in pointsCollectionView.visibleCells {
            guard let cameraCell = cell as? CameraNumberCell else { continue }
            cameraCell.resetSelection()
            cameraCell.selectCameraButton(cameraNumber: selectedCameraNumber ?? 0)
        }
        
        // обрабатываем переход до следующей ячейки pointsCollection
        let rowsPerPage = calculateRowsPerPageForPoints()
        let itemsPerPage = rowsPerPage * 5
        let page = indexPath.row / itemsPerPage

        let pointsIndexPath = IndexPath(item: page, section: 0)
        pointsCollectionView.selectItem(
            at: pointsIndexPath,
            animated: true,
            scrollPosition: .centeredHorizontally
        )
    }
    
    fileprivate func indexOfMajorCellForCameras() -> Int {
        let itemWidth = camerasFlowLayout.itemSize.width
        let proportionalOffset = camerasFlowLayout.collectionView!.contentOffset.x / itemWidth
        let index = Int(round(proportionalOffset))
        let safeIndex = max(0, min(cameras.count - 1, index))
        return safeIndex
    }
    
    fileprivate func indexOfMajorCellForPoints() -> Int {
        let itemWidth = pointsFlowLayout.itemSize.width
        let spacing = pointsFlowLayout.minimumInteritemSpacing
        let offset = pointsCollectionView.contentOffset.x
        let pageWidth = itemWidth + spacing
        let approximateIndex = offset / pageWidth
        let cellIndex = Int(round(approximateIndex))
        return max(0, min(cellIndex, pointsCollectionView.numberOfItems(inSection: 0) - 1))
    }
}

// MARK: - CameraButtonDelegate
extension OnlinePageViewController: CameraButtonDelegate {
    func didTapCameraButton(cameraNumber: Int) {
        guard let index = cameras.firstIndex(where: { $0.cameraNumber == cameraNumber }) else {
            return
        }
        let indexPath = IndexPath(row: index, section: 0)
        
        reloadCameraIfNeeded(selectedIndexPath: indexPath)
        for cell in pointsCollectionView.visibleCells {
            guard let cameraCell = cell as? CameraNumberCell else { continue }
            cameraCell.resetSelection()
            cameraCell.selectCameraButton(cameraNumber: selectedCameraNumber ?? 0)
        }
    }
}
