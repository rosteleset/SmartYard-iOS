//
//  GatePermanentAccessView.swift
//  SmartYard
//
//  Created by Александр Попов on 03.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit
import PMNibLinkableView
import RxSwift
import RxCocoa
import RxDataSources

final class GateAccessView: PMNibLinkableView, UICollectionViewDelegate, HasDisposeBag {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var segmentControl: SmartYardHighlightSegmentedControlView!
    @IBOutlet private weak var collectionView: UICollectionView!
    
    @IBOutlet private var segmentToCollectionConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    
    
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<GateAccessSectionModel>?
    
    let goToGateAccessDetailRelay = PublishRelay<Void>()
    let segmentControlValueChangedRelay = PublishRelay<GateAccessSegmentType?>()
    let deleteGateAccessCarRelay = PublishRelay<AllowedCar>()
    let deleteGateAccessPersonRelay = PublishRelay<AllowedPerson>()
    let sendSMSToPersonTappedRelay = PublishRelay<AllowedPerson>()
    
    private var currentSegment: GateAccessSegmentType = .persons
    
    let viewModel = GateAccessViewModel()
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        configureCollectionView()
        bind()
    }
    
    // MARK: - Public Methods
    
    func segmentControl(isHidden: Bool) {
        segmentToCollectionConstraint.isActive = !isHidden
        segmentControl.isHidden = isHidden
    }
    
    func segmentControl(selectedSegmentIndex: Int) {
        segmentControl.rx.setSelectedIndex.onNext(selectedSegmentIndex)
    }
    
    // MARK: - Bindings
    
    func bind() {
        viewModel.sectionModels
            .asDriver(onErrorJustReturn: [])
            .drive(collectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .map { [weak self] indexPath in
                self?.dataSource?[indexPath].identity
            }
            .ignoreNil()
            .filter { $0 == .shortcut }
            .mapToVoid()
            .bind(to: goToGateAccessDetailRelay)
            .disposed(by: disposeBag)
        
        segmentControl.rx.selectedIndex
            .asDriver()
            .map { index -> GateAccessSegmentType in
                return index == 0 ? .cars : .persons
            }
            .drive(onNext: { [weak self] type in
                self?.currentSegment = type
                self?.segmentControlValueChangedRelay.accept(type)
                self?.collectionView.collectionViewLayout.invalidateLayout()
            })
            .disposed(by: disposeBag)
    }
    
}

// MARK: - Configuration

extension GateAccessView {
    
    private func setupUI() {
        segmentControl.titles = [
            NSLocalizedString("By car number", comment: ""),
            NSLocalizedString("By phone number", comment: "")
        ]
    }
    
    private func configureCollectionView() {
        collectionView.register(nibWithCellClass: GateAccessCell.self)
        collectionView.register(nibWithCellClass: GateAccessShortcutCell.self)
        collectionView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<GateAccessSectionModel>(
            configureCell: { _, collectionView, indexPath, item in
                
                switch item {
                case .car(let licencePlate):
                    let cell = collectionView.dequeueReusableCell(
                        withClass: GateAccessCell.self,
                        for: indexPath
                    )
                    cell.configure(with: licencePlate)
                    
                    cell.deleteButtonTappedRelay
                        .bind { [weak self] in
                            self?.deleteGateAccessCarRelay.accept(licencePlate)
                        }
                        .disposed(by: cell.disposeBag)
                    
                    return cell
                    
                case .person(let number):
                    let cell = collectionView.dequeueReusableCell(
                        withClass: GateAccessCell.self,
                        for: indexPath
                    )
                    cell.configure(with: number)
                    
                    cell.deleteButtonTappedRelay
                        .bind { [weak self] in
                            self?.deleteGateAccessPersonRelay.accept(number)
                        }
                        .disposed(by: cell.disposeBag)
                    
                    cell.smsButtonTappedRelay
                        .bind { [weak self] in
                            self?.sendSMSToPersonTappedRelay.accept(number)
                        }
                        .disposed(by: cell.disposeBag)
                    
                    return cell
                    
                case .shortcut(let type):
                    let cell = collectionView.dequeueReusableCell(
                        withClass: GateAccessShortcutCell.self,
                        for: indexPath
                    )
                    cell.configure(with: type)
                    
                    return cell
                }
            }
        )
        
        collectionView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        
        self.dataSource = dataSource
    }
    
    private func configureFlowLayout() -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 8
        flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return flowLayout
    }
    
}
