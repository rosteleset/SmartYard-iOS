//
//  PaymentsViewController.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD

class PaymentsViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var skeletonContainer: UIView!
    
    private var refreshControl = UIRefreshControl()
    
    private let viewModel: PaymentsViewModel
    
    private let itemsProxy = BehaviorSubject<[APIPaymentsListAddress]>(value: [])
    
    var loader: JGProgressHUD?
    
    init(viewModel: PaymentsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if skeletonContainer.sk.isSkeletonActive {
            skeletonContainer.showSkeletonAsynchronously()
        }
    }
    
    private func bind() {
        let input = PaymentsViewModel.Input(
            itemSelected: collectionView.rx.itemSelected.asDriver(),
            refreshDataTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.itemModels
            .drive(itemsProxy)
            .disposed(by: disposeBag)
        
        output.reloadingFinished
            .drive(
                onNext: { [weak self] in
                    self?.refreshControl.endRefreshing()
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.view.endEditing(true)
                    }
                    
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
        output.shouldBlockInteraction
            .drive(
                onNext: { [weak self] shouldBlockInteraction in
                    self?.collectionView.isHidden = shouldBlockInteraction
                    self?.skeletonContainer.isHidden = !shouldBlockInteraction
                    
                    if shouldBlockInteraction {
                        self?.skeletonContainer.showSkeletonAsynchronously()
                    } else {
                        self?.skeletonContainer.hideSkeleton()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        itemsProxy
            .subscribe(
                onNext: { [weak self] _ in
                    self?.collectionView.reloadData()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureTableView() {
//        mainContainerView.layerCornerRadius = 24
//        mainContainerView.layer.maskedCorners = .topCorners
        
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(cellWithClass: PaymentsAddressCell.self)
        
        collectionView.refreshControl = refreshControl
    }
    
}

extension PaymentsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let address = (try? itemsProxy.value())?[safe: indexPath.row] else {
            return .zero
        }
        
        let height = PaymentsAddressCell.preferredHeight(
            for: UIScreen.main.bounds.width - 32,
            title: address.address
        ).totalHeight
        
        return CGSize(width: UIScreen.main.bounds.width - 32, height: height)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 10
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)
    }
    
}

extension PaymentsViewController: UICollectionViewDataSource {
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
        
        let cell = collectionView.dequeueReusableCell(withClass: PaymentsAddressCell.self, for: indexPath)
        cell.configure(address: data[safe: indexPath.row]?.address)
        
        return cell
    }
    
}
