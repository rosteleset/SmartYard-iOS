//
//  DetailGateAccessViewController.swift
//  SmartYard
//
//  Created by Александр Попов on 18.07.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import RxDataSources

final class DetailGateAccessViewController: BaseViewController, UIScrollViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var addressView: FullRoundedView!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var segmentControl: SmartYardHighlightSegmentedControlView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var skeletonView: DetailGateAccessSkeletonView!
    @IBOutlet private weak var stackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var collectionViewHeightConstant: NSLayoutConstraint!
    @IBOutlet private weak var skeletonViewTopConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    
    private let addButtonTappedRelay = PublishRelay<Void>()
    private let deleteCarTappedRelay = PublishRelay<AllowedCar>()
    private let sendSMSToPersonTappedRelay = PublishRelay<AllowedPerson>()
    private let deletePersonTappedRelay = PublishRelay<AllowedPerson>()
    
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<DetailGateAccessViewModel.SectionModel>?
    
    private let viewModel: DetailGateAccessViewModel
    
    // MARK: - Lifecycle
    
    init(viewModel: DetailGateAccessViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureCollectionView()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if skeletonView.sk.isSkeletonActive {
            skeletonView.showSkeletonAsynchronously(with: UIColor.SmartYard.secondBackgroundColor)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        /// 24 px - это то, насколько addressView выступает над scrollView
        /// 16 px - это отступ между addressView и следующей за ней вьюхой
        let neededInset = addressView.bounds.height - 24 + 16
        
        stackViewTopConstraint.constant = neededInset
        skeletonViewTopConstraint.constant = neededInset - 16
    }
    
    // MARK: - Bindings
    
    private func bind() {
        let segmentControlValueChangedRelay = BehaviorRelay<GateAccessSegmentType?>(value: nil)
        
        segmentControl.rx.selectedIndex
            .asDriver()
            .map { index -> GateAccessSegmentType in
                return index == 0 ? .cars : .persons
            }
            .drive(segmentControlValueChangedRelay)
            .disposed(by: disposeBag)
        
        let input = DetailGateAccessViewModel.Input(
            segmentControlTrigger: segmentControlValueChangedRelay.asDriver(),
            deleteAccessContactTrigger: deletePersonTappedRelay.asDriverOnErrorJustComplete(),
            smsToContactTrigger: sendSMSToPersonTappedRelay.asDriverOnErrorJustComplete(),
            deleteAccessLicensePlateTrigger: deleteCarTappedRelay.asDriverOnErrorJustComplete(),
            addAccessTrigger: addButtonTappedRelay.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        // MARK: - Outputs
        
        let output = viewModel.transform(input: input)
        
        output.objectAddress
            .drive { [weak self] address in
                self?.addressLabel.text = address
            }
            .disposed(by: disposeBag)
        
        output.isLPRSEnabled
            .drive { [weak self] state in
                self?.segmentControl.isHidden = !state

                UIView.animate(withDuration: 0.25) {
                    self?.view.layoutIfNeeded()
                }
            }
            .disposed(by: disposeBag)
        
        output.selectedSegmentControlType
            .distinctUntilChanged()
            .drive { [weak self] selectedType in
                let selectedIndex = selectedType == .cars ? 0 : 1
                self?.segmentControl.rx.setSelectedIndex.onNext(selectedIndex)
            }
            .disposed(by: disposeBag)
        
        output.sectionModels
            .asDriver(onErrorJustReturn: [])
            .drive(collectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
        
        output.collectionHeight
            .drive { [weak self] height in
                self?.collectionViewHeightConstant.constant = height
                
                UIView.animate(withDuration: 0.25) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            }
            .disposed(by: disposeBag)
        
        output.isInitialLoadingFinished
            .distinctUntilChanged()
            .isTrue()
            .delay(.milliseconds(500))
            .drive { [weak self] _ in
                self?.scrollView.isHidden = false
                self?.skeletonView.hideSkeleton()
                self?.skeletonView.isHidden = true
            }
            .disposed(by: disposeBag)
    }

}

// MARK: - Configuration

extension DetailGateAccessViewController {

    private func configureView() {
        segmentControl.titles = [
            NSLocalizedString("By car number", comment: ""),
            NSLocalizedString("By phone number", comment: "")
        ]
        
        scrollView.isHidden = true
        skeletonView.isHidden = false
        skeletonView.showSkeletonAsynchronously(with: UIColor.SmartYard.secondBackgroundColor)
    }
    
    private func configureCollectionView() {
        collectionView.register(nibWithCellClass: DetailGateAccessCell.self)
        collectionView.register(nibWithCellClass: DetailGateAccessAddCell.self)
        
        collectionView.collectionViewLayout = configureFlowLayout()
        
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<DetailGateAccessViewModel.SectionModel>(
            configureCell: { [weak self] _, collectionView, indexPath, item in
                guard let self else {
                    return DetailGateAccessCell()
                }
                
                switch item {
                case .car(let licencePlate):
                    let cell = collectionView.dequeueReusableCell(
                        withClass: DetailGateAccessCell.self,
                        for: indexPath
                    )
                    cell.configure(with: licencePlate)
                    
                    cell.deleteButtonTappedRelay
                        .bind { [weak self] in
                            self?.deleteCarTappedRelay.accept(licencePlate)
                        }
                        .disposed(by: cell.disposeBag)
                    
                    return cell
                    
                case .person(let personViewState):
                    let cell = collectionView.dequeueReusableCell(
                        withClass: DetailGateAccessCell.self,
                        for: indexPath
                    )
                    cell.configure(with: personViewState)
                    
                    cell.deleteButtonTappedRelay
                        .bind { [weak self] in
                            self?.deletePersonTappedRelay.accept(personViewState.person)
                        }
                        .disposed(by: cell.disposeBag)
                    
                    cell.smsButtonTappedRelay
                        .bind { [weak self] in
                            self?.sendSMSToPersonTappedRelay.accept(personViewState.person)
                        }
                        .disposed(by: cell.disposeBag)
                    
                    return cell
                    
                case .shortcut(let type):
                    let cell = collectionView.dequeueReusableCell(
                        withClass: DetailGateAccessAddCell.self,
                        for: indexPath
                    )
                    cell.configure(with: type)
                    cell.bind(with: addButtonTappedRelay)
                    
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
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 8
        return flowLayout
    }
    
}

extension DetailGateAccessViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let totalItems = collectionView.numberOfItems(inSection: indexPath.section)
        let width = collectionView.bounds.width

        let isOnlyItem = totalItems == 1
        let isLastItem = indexPath.item == totalItems - 1

        let height: CGFloat
        switch true {
        case isOnlyItem:
            height = 57
        case isLastItem:
            height = 57 + 16
        default:
            height = 64
        }

        return CGSize(width: width, height: height)
    }
    
}
