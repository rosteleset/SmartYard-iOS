//
//  AddressesViewController.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable file_length function_body_length closure_body_length

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import JGProgressHUD
import SkeletonView

class AddressesListViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var skeletonContainer: UIView!
    
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<AddressesListSectionModel>?
    private var refreshControl = UIRefreshControl()
    
    // MARK: Это костыль для того, чтобы понять, сколько на самом деле ячеек внутри секции
    // В методе configureCell у RxDataSource мы должны сконфигурировать ячейку
    // Но проблема в том, что RxDataSource выполняет операции обновления и добавления ячеек отдельно
    // Сначала выполняется обновление уже существующих ячеек, а потом добавляются новые
    // Поэтому на момент обновления ячеек мы не можем получить актуальное количество секций через dataSource[section]
    // Так что приходится проксировать количество ячеек в секциях в отдельный субъект и брать данные отсюда
    
    private let itemsCountProxy = BehaviorSubject<[Int: Int]>(value: [:])
    
    private let viewModel: AddressesListViewModel
    
    private let requestGuestAccess = PublishSubject<AddressesListDataItemIdentity>()
    private let qrCodeTapped = PublishSubject<Void>()
    
    var loader: JGProgressHUD?
    
    init(viewModel: AddressesListViewModel) {
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
        
//        refreshControl = UIRefreshControl()
//        refreshControl.attributedTitle = NSAttributedString(string: "Обновление...")
//        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
//        collectionView.refreshControl = refreshControl
    }
    
//    @objc func refresh(_ sender:AnyObject) {
//        configureView()
//        configureCollectionView()
//        bind()
//        sleep(2)
//        
//        refreshControl.endRefreshing()
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if skeletonContainer.sk.isSkeletonActive {
            skeletonContainer.showSkeletonAsynchronously()
        }
    }
    
    private func bind() {
        let itemSelected = collectionView.rx.itemSelected
            .map { [weak self] indexPath in
                self?.dataSource?[indexPath].identity
            }
            .ignoreNil()
        
        let input = AddressesListViewModel.Input(
            itemSelected: itemSelected.asDriverOnErrorJustComplete(),
            guestAccessRequested: requestGuestAccess.asDriverOnErrorJustComplete(),
            refreshDataTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver(),
            addAddressTrigger: addButton.rx.tap.asDriver(),
            issueQrCodeTrigger: qrCodeTapped.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        // MARK: При получении моделей сначала проксируем словарь с количеством ячеек в секциях
        // А уже потом отправляем свежие модели в таблицу
        
        output.sectionModels
            .do(
                onNext: { [weak self] models in
                    let itemsCountDict: [Int: Int] = models.enumerated().reduce([:]) { dict, enumeration in
                        let (offset, element) = enumeration
                        
                        var mutableDict = dict
                        mutableDict[offset] = element.items.count
                        return mutableDict
                    }
                    
                    self?.itemsCountProxy.onNext(itemsCountDict)
                }
            )
            .drive(collectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
        
        output.reloadingFinished
            .drive(
                onNext: { [weak self] in
                    self?.refreshControl.endRefreshing()
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Скроллим таблицу при сворачивании / разворачивании секций для лучшего UX
        
        let updateKindSubject = BehaviorSubject<AddressesListSectionUpdateKind?>(value: nil)
        let updateKind = updateKindSubject.asDriver(onErrorJustReturn: nil)
        
        output.updateKind
            .drive(
                onNext: {
                    updateKindSubject.onNext($0)
                }
            )
            .disposed(by: disposeBag)
        
        collectionView.rx
            .observeWeakly(CGSize.self, "contentSize", options: [.new])
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            
            // MARK: BatchUpdates проходят постепенно, поэтому contentSize меняется несколько раз
            // Чтобы анимации не конфликтовали, ждем, пока contentSize станет стабильным
            
            .debounce(.milliseconds(50))
            .withLatestFrom(updateKind)
            .ignoreNil()
            .do(
                onNext: { _ in
                    updateKindSubject.onNext(nil)
                }
            )
            .withLatestFrom(output.sectionModels) { ($0, $1) }
            
            // MARK: Ищем секцию, которая содержит Header с указанным идентификатором, и скроллим к нему
            
            .map { [weak self] updateKind, sectionModels -> (AddressesListSectionUpdateKind, IndexPath)? in
                let neededSectionOffset = sectionModels.enumerated().first { _, model in
                    model.items.contains { $0.identity == updateKind.associatedIdentity }
                }?.offset
                
                guard let section = neededSectionOffset else {
                    return nil
                }
                
                guard !(self?.collectionView.refreshControl?.isRefreshing ?? false) else {
                    return nil
                }
                
                let indexPath = IndexPath(row: 0, section: section)
                return (updateKind, indexPath)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] updateKind, indexPath in
                    self?.performScrollUpdate(updateKind: updateKind, to: indexPath)
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
    }
    
    private func performScrollUpdate(updateKind: AddressesListSectionUpdateKind, to indexPath: IndexPath) {
        switch updateKind {
        case .expand:
            guard let attributes = collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath) else {
                return
            }
            
            let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
            
            let topInset = collectionView(
                collectionView,
                layout: collectionView.collectionViewLayout,
                insetForSectionAt: indexPath.section
            ).top
            
            let desiredOffset = attributes.frame.origin.y - topInset
            let maxPossibleOffset = contentHeight - collectionView.bounds.height
            
            let finalOffset = max(min(desiredOffset, maxPossibleOffset), 0)
            
            collectionView.setContentOffset(
                CGPoint(x: 0, y: finalOffset),
                animated: true
            )
            
        case .collapse:
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    private func configureView() {
        mainContainerView.layerCornerRadius = 24
        mainContainerView.layer.maskedCorners = .topCorners
        
        addButton.setImage(UIImage(named: "AddButtonIcon"), for: .normal)
        addButton.setImage(UIImage(named: "AddButtonIcon")?.darkened(), for: .highlighted)
    }
    
    private func configureCollectionView() {
        collectionView.refreshControl = refreshControl
        refreshControl.tintColor = UIColor.SmartYard.gray
        
        [
            AddressesListObjectCell.self,
            AddressesListCameraCell.self,
            AddressesListHistoryCell.self,
            AddressesListEmptyStateCell.self,
            UnapprovedObjectCell.self
        ].forEach {
            collectionView.register(nibWithCellClass: $0)
        }
        
        collectionView.register(cellWithClass: AddressesHeaderCell.self)
        
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<AddressesListSectionModel>(
            configureCell: { [weak self] _, collectionView, indexPath, item in
                guard let self = self else {
                    // MARK: я думал, мы сюда вообще никак не сможем попасть, но я еще никогда так не ошибался
                    // Из-за реактивщины этот датасорс может жить чуть дольше, чем этот контроллер
                    // Из-за того, что я возвращал UICollectionViewCell(), приложение падало с эксепшном
                    // Типа нельзя использовать ячейки без ReuseIdentifier в таком датасорсе
                    // Поэтому возвращаю рандомную ячейку. Все равно контроллер уже мертв, нам пофиг
                    
                    return collectionView.dequeueReusableCell(withClass: AddressesHeaderCell.self, for: indexPath)
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
        item: AddressesListDataItem
    ) -> UICollectionViewCell {
        if case .emptyState = item {
            let cell = collectionView.dequeueReusableCell(withClass: AddressesListEmptyStateCell.self, for: indexPath)
            return cell
        }
        
        let customizableCell: CustomBorderCollectionViewCell = {
            switch item {
            case let .header(_, address, isExpanded):
                let cell = collectionView.dequeueReusableCell(withClass: AddressesHeaderCell.self, for: indexPath)
                cell.configure(address: address, isExpanded: isExpanded)
                return cell
                
            case let .object(_, type, name, isOpened):
                let cell = collectionView.dequeueReusableCell(withClass: AddressesListObjectCell.self, for: indexPath)
                cell.configure(objectType: type, name: name, isOpened: isOpened)
                
                let subject = PublishSubject<Void>()
                
                subject
                    .map { item.identity }
                    .bind(to: self.requestGuestAccess)
                    .disposed(by: cell.disposeBag)
                
                cell.bind(with: subject)
                
                return cell
                
            case let .cameras(_, numberOfCameras):
                let cell = collectionView.dequeueReusableCell(withClass: AddressesListCameraCell.self, for: indexPath)
                cell.configure(availableCameras: numberOfCameras)
                return cell
            
            case let .history(_, eventsCount):
                let cell = collectionView.dequeueReusableCell(withClass: AddressesListHistoryCell.self, for: indexPath)
                cell.configure(itemsCount: eventsCount)
                return cell
                
            case let .unapprovedAddresses(_, address):
                let cell = collectionView.dequeueReusableCell(withClass: UnapprovedObjectCell.self, for: indexPath)
                cell.configure(address: address)
                cell.bind(with: qrCodeTapped)
                
                return cell
                
            case .emptyState:
                fatalError("Should be handled separately")
            }
        }()
        
        guard let itemsCountDict = try? itemsCountProxy.value(),
            let totalItemsInSection = itemsCountDict[indexPath.section] else {
            return customizableCell
        }
        
        let isFirstInSection = indexPath.row == 0
        let isLastInSection = indexPath.row == totalItemsInSection - 1
        
        customizableCell.addCustomBorder(
            isFirstInSection: isFirstInSection,
            isLastInSection: isLastInSection,
            customBorderWidth: 1,
            customBorderColor: UIColor.SmartYard.grayBorder,
            customlayerCornerRadius: 12
        )
        
        return customizableCell
    }

}

extension AddressesListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let item = dataSource?[indexPath] else {
            return .zero
        }
        
        switch item {
        case .emptyState:
            return CGSize(width: collectionView.width - 32, height: collectionView.bounds.height - 36)
            
        case let .header(_, address, _):
            let height = AddressesHeaderCell.preferredHeight(
                for: UIScreen.main.bounds.width - 32,
                title: address
            ).totalHeight
            
            return CGSize(width: UIScreen.main.bounds.width - 32, height: height)
            
        default:
            return CGSize(width: collectionView.width - 32, height: 72)
        }
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
            default: return 10
            }
        }()
        
        let bottomInset: CGFloat = {
            switch section {
            case collectionView.numberOfSections - 1: return 20
            default: return 0
            }
        }()
        
        return UIEdgeInsets(top: topInset, left: 16, bottom: bottomInset, right: 16)
    }
    
}
