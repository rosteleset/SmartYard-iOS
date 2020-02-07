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

class AddressesListViewController: BaseViewController {
    
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<AddressesListSectionModel>?
    
    // MARK: Это костыль для того, чтобы понять, сколько на самом деле ячеек внутри секции
    // В методе configureCell у RxDataSource мы должны сконфигурировать ячейку
    // Но проблема в том, что RxDataSource выполняет операции обновления и добавления ячеек отдельно
    // Сначала выполняется обновление уже существующих ячеек, а потом добавляются новые
    // Поэтому на момент обновления ячеек мы не можем получить актуальное количество секций через dataSource[section]
    // Так что приходится проксировать количество ячеек в секциях в отдельный субъект и брать данные отсюда
    
    private let itemsCountProxy = BehaviorSubject<[Int: Int]>(value: [:])
    
    let viewModel: AddressesListViewModel
    
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
        configureCollectionView()
        configureView()
        bind()
    }
    
    // swiftlint:disable:next function_body_length
    private func bind() {
        let itemSelected = collectionView.rx.itemSelected
            .map { [weak self] indexPath in
                self?.dataSource?[indexPath].identity
            }
            .ignoreNil()
        
        let input = AddressesListViewModel.Input(itemSelected: itemSelected.asDriverOnErrorJustComplete())
        
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
        
        // MARK: Скроллим таблицу при сворачивании / разворачивании секций для лучшего UX
        
        let scrollingModeSubject = BehaviorSubject<AddressesListScrollingMode?>(value: nil)
        let scrollingMode = scrollingModeSubject.asDriver(onErrorJustReturn: nil)
        
        output.scrollingMode
            .drive(
                onNext: {
                    scrollingModeSubject.onNext($0)
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
            .withLatestFrom(scrollingMode)
            .ignoreNil()
            .do(
                onNext: { _ in
                    scrollingModeSubject.onNext(nil)
                }
            )
            .withLatestFrom(output.sectionModels) { ($0, $1) }
            
            // MARK: Ищем секцию, которая содержит Header с указанным идентификатором, и скроллим к нему
            
            .map { scrollingBehavior, sectionModels -> (UICollectionView.ScrollPosition, IndexPath)? in
                let neededSectionOffset = sectionModels.enumerated().first { _, model in
                    model.items.contains { $0.identity == scrollingBehavior.associatedIdentity }
                }?.offset
                
                guard let section = neededSectionOffset else {
                    return nil
                }
                
                let indexPath = IndexPath(row: 0, section: section)
                return (scrollingBehavior.scrollingPosition, indexPath)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] position, indexPath in
                    self?.collectionView.scrollToItem(at: indexPath, at: position, animated: true)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureView() {
        mainContainerView.cornerRadius = 24
        mainContainerView.layer.maskedCorners = .topCorners
        
        addButton.setImage(UIImage(named: "AddButtonIcon"), for: .normal)
        addButton.setImage(UIImage(named: "AddButtonIcon")?.darkened(), for: .highlighted)
    }
    
    private func configureCollectionView() {
        [
            AddressesListHeaderCell.self,
            AddressesListObjectCell.self,
            AddressesListCameraCell.self
        ].forEach {
            collectionView.register(nibWithCellClass: $0)
        }
        
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<AddressesListSectionModel>(
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
        item: AddressesListDataItem
    ) -> UICollectionViewCell {
        let customizableCell: CustomBorderCollectionViewCell = {
            switch item {
            case let .header(_, address, isExpanded):
                let cell = collectionView.dequeueReusableCell(withClass: AddressesListHeaderCell.self, for: indexPath)
                cell.configure(address: address, isExpanded: isExpanded)
                return cell
                
            case let .object(_, type, name, isOpened):
                let cell = collectionView.dequeueReusableCell(withClass: AddressesListObjectCell.self, for: indexPath)
                cell.configure(objectType: type, name: name, isOpened: isOpened)
                return cell
                
            case let .cameras(_, numberOfCameras):
                let cell = collectionView.dequeueReusableCell(withClass: AddressesListCameraCell.self, for: indexPath)
                cell.configure(availableCameras: numberOfCameras)
                return cell
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
            customCornerRadius: 12
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
