//
//  PayContractViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 03.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class PayContractViewController: BaseViewController {

    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    private var currentIndex = 0
    
    private let itemsProxy = BehaviorSubject<[APIPaymentsListAccount]>(value: [])
    
    private let payContractTrigger = PublishSubject<(String, Double?, String?)>()
    private let fullVersionPersonalAccountTrigger = PublishSubject<String?>()
    
    private let viewModel: PayContractViewModel
    
    init(viewModel: PayContractViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        fakeNavBar.configueDarkNavBar()
        configureCollectionView()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureCollectionViewLayoutItemSize()
    }
    
    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(nibWithCellClass: ContractCell.self)
        
        collectionViewFlowLayout.minimumLineSpacing = 0
    }
    
    private func bind() {
        let input = PayContractViewModel.Input(
            fullVersionPersonalAccountTrigger: fullVersionPersonalAccountTrigger.asDriverOnErrorJustComplete(),
            payContractTrigger: payContractTrigger.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.items
            .drive(itemsProxy)
            .disposed(by: disposeBag)
        
        output.address
            .drive(addressLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    private func configureCollectionViewLayoutItemSize() {
        let inset: CGFloat = 16
        
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        
        collectionViewFlowLayout.itemSize = CGSize(
            width: collectionViewFlowLayout.collectionView!.frame.size.width - inset * 2,
            height: collectionViewFlowLayout.collectionView!.frame.size.height - inset
        )
    }
    
    private func getIndexOfMajorCell() -> Int {
        guard let data = try? itemsProxy.value() else {
            return 0
        }
        
        let itemWidth = collectionViewFlowLayout.itemSize.width
        let proportionalOffset = collectionViewFlowLayout.collectionView!.contentOffset.x / itemWidth
        let index = Int(round(proportionalOffset))
        
        return max(0, min(data.count - 1, index))
    }
    
}

extension PayContractViewController: UICollectionViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        currentIndex = getIndexOfMajorCell()
    }
    
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        guard let data = try? itemsProxy.value() else {
            return
        }
        
        targetContentOffset.pointee = scrollView.contentOffset
        
        let indexOfMajorCell = self.getIndexOfMajorCell()
        
        let neededVelocity: CGFloat = 0.5
        
        let hasEnoughVelocityForSlideToNextCell = currentIndex + 1 < data.count && velocity.x > neededVelocity
        let hasEnoughVelocityForSlideToPrevCell = currentIndex - 1 >= 0 && velocity.x < -neededVelocity
        
        let majorCellIsTheCellBeforeDragging = indexOfMajorCell == currentIndex
        
        let didUseSwipeToSkipCell = majorCellIsTheCellBeforeDragging &&
                                    (hasEnoughVelocityForSlideToNextCell || hasEnoughVelocityForSlideToPrevCell)
        
        guard didUseSwipeToSkipCell else {
            let indexPath = IndexPath(row: indexOfMajorCell, section: 0)
            
            collectionViewFlowLayout.collectionView!.scrollToItem(
                at: indexPath,
                at: .centeredHorizontally,
                animated: true
            )
            
            return
        }
        
        let swipeToIndex = currentIndex + (hasEnoughVelocityForSlideToNextCell ? 1 : -1)
        let toContentOffset = collectionViewFlowLayout.itemSize.width * CGFloat(swipeToIndex)
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: velocity.x,
            options: .allowUserInteraction,
            animations: {
                scrollView.contentOffset = CGPoint(x: toContentOffset, y: 0)
                scrollView.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
}

extension PayContractViewController: UICollectionViewDataSource {
    
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
        
        let cell = collectionView.dequeueReusableCell(withClass: ContractCell.self, for: indexPath)
        
        cell.configure(with: data[indexPath.row])
        
        let paymentSubject = PublishSubject<Void>()
        
        paymentSubject
            .map { (data[indexPath.row].clientId, data[indexPath.row].payAdvice, data[indexPath.row].contractName) }
            .bind(to: payContractTrigger)
            .disposed(by: cell.disposeBag)
        
        let openLkSubject = PublishSubject<Void>()
        
        openLkSubject
            .map { data[indexPath.row].lcab }
            .bind(to: fullVersionPersonalAccountTrigger)
            .disposed(by: cell.disposeBag)
        
        cell.bind(with: paymentSubject, openLkOuterSubject: openLkSubject)
        
        return cell
    }
    
}
