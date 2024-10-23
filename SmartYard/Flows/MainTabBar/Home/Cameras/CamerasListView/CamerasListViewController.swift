//
//  CamerasListViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 18.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD

final class CamerasListViewController: BaseViewController, LoaderPresentable {
    var loader: JGProgressHUD?
    private let viewModel: CamerasListViewModel
    private let itemsProxy = BehaviorSubject<[CamerasListItem]>(value: [])
    private let itemSelected = PublishSubject<IndexPath>()
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var containerView: TopRoundedView!
    @IBOutlet private weak var skeletonContainer: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var addressLabel: UILabel!
    
    init(viewModel: CamerasListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        bind()
    }
    
    private func bind() {
        
        let input = CamerasListViewModel.Input(
            itemSelected: itemSelected.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        collectionView.rx.itemSelected.asDriver()
            .drive(
                onNext: { [weak self] indexPath in
                    self?.itemSelected.onNext(indexPath)
                }
            )
            .disposed(by: disposeBag)
        
        let output = viewModel.transform(input)
        
        output.items
            .drive(itemsProxy)
            .disposed(by: disposeBag)
        
        output.address
            .drive(addressLabel.rx.text)
            .disposed(by: disposeBag)
        
        itemsProxy
            .subscribe(
                onNext: { [weak self] _ in
                    self?.collectionView.reloadData()
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
                    
                    shouldBlockInteraction ?
                        self?.skeletonContainer.showSkeletonAsynchronously() :
                        self?.skeletonContainer.hideSkeleton()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(cellWithClass: CamerasListItemCell.self)
    }

}

extension CamerasListViewController: UICollectionViewDelegateFlowLayout {
    // В первой секции название раздела, если оно есть
    // Во второй секции - элементы списка: либо группы, либо камеры.
    
    // возвращает высоту одного элемента меню
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        
        guard let item = (try? itemsProxy.value())?[safe: indexPath.row] else {
            return .zero
        }
        
        switch item {
            
        case .caption:
            let height = CamerasListItemCell.preferredHeightForHeader(
                for: UIScreen.main.bounds.width - 32,
                title: item.label
            ).totalHeight
            
            return CGSize(width: UIScreen.main.bounds.width - 32, height: height)
        default:
            let height = CamerasListItemCell.preferredHeight(
                for: UIScreen.main.bounds.width - 32,
                title: item.label
            ).totalHeight
            
            return CGSize(width: UIScreen.main.bounds.width - 32, height: height)
        }
        
    }
    
    // возвращает расстояние между элементами меню
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 8
    }
    
    // возвращает отступы вокруг секции
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 21, left: 16, bottom: 20, right: 16)
    }
    
}

extension CamerasListViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard (try? itemsProxy.value()) != nil else {
            return 0
        }
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (try? itemsProxy.value().count) ?? 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let data = try? itemsProxy.value() else {
            return UICollectionViewCell()
        }
        
        switch indexPath.section {
        default:
            let cell = collectionView.dequeueReusableCell(withClass: CamerasListItemCell.self, for: indexPath)
            guard let item = data[safe: indexPath.row] else {
                return cell
            }
            cell.configure(item: item)
            return cell
        }
    }
}
