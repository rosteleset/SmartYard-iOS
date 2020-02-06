//
//  AddressesViewController.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class AddressesViewController: BaseViewController {
    
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<AddressesSectionModel>?
    
    let viewModel: AddressesViewModel
    
    init(viewModel: AddressesViewModel) {
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
        configureView()
        bind()
    }
    
    private func bind() {
        let input = AddressesViewModel.Input()
        let output = viewModel.transform(input)
        
        output.sectionModels
            .drive(collectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
    }
    
    private func configureView() {
        mainContainerView.cornerRadius = 24
        mainContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        addButton.setImage(UIImage(named: "AddButtonIcon"), for: .normal)
        addButton.setImage(UIImage(named: "AddButtonIcon")?.darkened(), for: .highlighted)
    }
    
    private func configureCollectionView() {
        [
            AddressExpandableHeaderCell.self
        ].forEach {
            collectionView.register(nibWithCellClass: $0)
        }
        
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<AddressesSectionModel>(
            configureCell: { [weak self] _, collectionView, indexPath, item in
                guard let self = self else {
                    return UICollectionViewCell()
                }
                
                return self.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
            }
        )
        
        collectionView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        
        self.dataSource = dataSource
    }
    
    private func configureCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: AddressesDataItem
    ) -> UICollectionViewCell {
        switch item {
        case let .header(_, address, isExpanded):
            let cell = collectionView.dequeueReusableCell(withClass: AddressExpandableHeaderCell.self, for: indexPath)
            cell.configure(address: address, isExpanded: isExpanded)
            
            maskCorners(
                ofCell: cell,
                at: indexPath.row,
                withTotalRowsInSection: collectionView.numberOfItems(inSection: indexPath.section)
            )
            
            return cell
        }
    }
    
    private func maskCorners(
        ofCell cell: UICollectionViewCell,
        at row: Int,
        withTotalRowsInSection totalRows: Int
    ) {
        cell.layer.cornerRadius = 12
        
        let maskedCorners: CACornerMask = {
            var arr = [CACornerMask]()
            
            if row == 0 {
                arr.append(contentsOf: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
            }
            
            if row == totalRows - 1 {
                arr.append(contentsOf: [.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            }
            
            return CACornerMask(arr)
        }()
        
        cell.layer.cornerRadius = 12
        cell.layer.maskedCorners = maskedCorners
    }

}

extension AddressesViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: collectionView.width - 32, height: 72)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        let topInset: CGFloat = {
            switch section {
            case 0: return 16
            default: return 0
            }
        }()
        
        let bottomInset: CGFloat = {
            switch section {
            case collectionView.numberOfSections - 1: return 20
            default: return 10
            }
        }()
        
        return UIEdgeInsets(top: topInset, left: 16, bottom: bottomInset, right: 16)
    }
    
}
