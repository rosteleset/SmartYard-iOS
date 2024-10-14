//
//  HistoryDetailViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 24.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import JGProgressHUD
import RxSwift
import RxCocoa
import RxDataSources

class HistoryDetailViewController: BaseViewController, LoaderPresentable {
    var loader: JGProgressHUD?
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var emptyStateView: UIView!
    
    fileprivate let viewModel: HistoryViewModel
    fileprivate var dataSource: RxCollectionViewSectionedAnimatedDataSource<HistorySectionModel>?
    fileprivate let selectItemOnLoad: HistoryDataItem?
    fileprivate var itemWasPointed = false
    
    private let loadDayTriger = PublishSubject<Date>()
    private var availableDays = BehaviorRelay<AvailableDays>(value: [:])
    
    /// дни, которые есть в sectionModels, т.е. в таблице
    private var days: [Date] = []
    
    /// все дни какие есть на сервере для данной комбинации фильтров
    private var allAvailableDates: [Date] = []
    
    /// дни, которые есть на сервере, но их нет в sectionModels - чтобы они оказались в sectionModels, их надо запросить
    private var daysQueue: [Date] = []
    
    /// таблица соответствия objectId <-> url flussonic
    private var camMap: [APICamMap] = []
    
    var stopDynamicLoading = false
    
    var focusedCellIndexPath: IndexPath?
    
    private let addFaceTrigger = PublishSubject<APIPlog>()
    private let deleteFaceTrigger = PublishSubject<APIPlog>()
    private let displayHintTrigger = PublishSubject<Void>()
    
    init(viewModel: HistoryViewModel, focusedOn: HistoryDataItem? = nil) {
        self.viewModel = viewModel
        self.selectItemOnLoad = focusedOn
        super.init(nibName: nil, bundle: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fakeNavBar.configueDarkNavBar()
        fakeNavBar.setText(NSLocalizedString("Events", comment: ""))
        emptyStateView.isHidden = true
        
        setupCollectionView()
        bind()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !itemWasPointed {
            DispatchQueue.main.async {
                self.pointViewToSelectedItem()
                self.itemWasPointed = true
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if  let focusedCellIndexPath = focusedCellIndexPath {
            let cell = collectionView.cellForItem(at: focusedCellIndexPath) as? HistoryCollectionViewCell
            cell?.stopVideo()
        }
        super.viewDidDisappear(animated)
    }
    
    fileprivate func pointViewToSelectedItem() {
        guard let indexPath = { () -> IndexPath? in
            
            guard let dataSource = dataSource else {
                return nil
            }
            
            // Если мы попали в этот контроллер без указания элемнта на какой надо спозиционироваться, то позиционируемся на самый первый.
            if self.selectItemOnLoad == nil,
               !dataSource.sectionModels.isEmpty,
               !dataSource.sectionModels.first!.items.isEmpty {
                return IndexPath(item: 0, section: 0)
            }
            
            for (sectionIndex, section) in dataSource.sectionModels.enumerated() {
                for (row, item) in section.items.enumerated() where item == self.selectItemOnLoad {
                    return IndexPath(item: row, section: sectionIndex)
                }
            }
            return nil
        }() else {
            return
        }
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        focusedCellIndexPath = indexPath
        if let focusedCellIndexPath = focusedCellIndexPath {
            onItemFocused(indexPath: focusedCellIndexPath)
        }
    }
    
    fileprivate func setupCollectionView() {
        collectionView.register(nibWithCellClass: HistoryCollectionViewCell.self)
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 11, bottom: 0, right: 11)
        collectionView.decelerationRate = .fast
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .horizontal
        }
        
        self.dataSource = RxCollectionViewSectionedAnimatedDataSource<HistorySectionModel>(
            configureCell: { _, collectionView, indexPath, item in
                let cell: HistoryCollectionViewCell = collectionView.dequeueReusableCell(withClass: HistoryCollectionViewCell.self, for: indexPath)
                
                // если у домофона есть камера, то конфигурируем ячейку с параметрами для отображения видео
                if let camera = self.camMap.first(where: { $0.entranceId == item.value.entranceId }) {
                    cell.configure(
                        value: item.value,
                        using: imagesCache,
                        camera: camera
                    )
                } else if let camera = self.camMap.first(where: { $0.id == item.value.objectId }){
                    cell.configure(
                        value: item.value,
                        using: imagesCache,
                        camera: camera
                    )
                } else {
                    cell.configure(
                        value: item.value,
                        using: imagesCache
                    )
                }
                
                cell.itsMeTrigger
                    .drive(self.addFaceTrigger)
                    .disposed(by: cell.disposeBag)
                
                cell.itsNotMeTrigger
                    .drive(self.deleteFaceTrigger)
                    .disposed(by: cell.disposeBag)
                
                cell.displayHintTrigger
                    .drive(self.displayHintTrigger)
                    .disposed(by: cell.disposeBag)
                
                return cell
            }
        )
    }
    func onItemFocused(indexPath: IndexPath) {
        collectionView.layoutIfNeeded()
        let cell = collectionView.cellForItem(at: indexPath) as? HistoryCollectionViewCell
        
        cell?.playVideo()
    }
    func onItemLostFocus(indexPath: IndexPath) {
        collectionView.layoutIfNeeded()
        let cell = collectionView.cellForItem(at: indexPath) as? HistoryCollectionViewCell
        
        cell?.stopVideo()
    }
    func bind() {
        let trigger = PublishSubject<Void>()
        
        let input = HistoryViewModel.InputDetail(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            updateSections: trigger.asDriver(onErrorJustReturn: ()),
            loadDay: loadDayTriger.asDriverOnErrorJustComplete(),
            addFaceTrigger: addFaceTrigger.asDriverOnErrorJustComplete(),
            deleteFaceTrigger: deleteFaceTrigger.asDriverOnErrorJustComplete(),
            displayHintTrigger: displayHintTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                    if isLoading { self?.emptyStateView.isHidden = true }
                }
            )
            .disposed(by: disposeBag)
        
        output.sections // отсюда притетает свежий [HistorySectionModels] для DataSource таблицы
            .do(
                onNext: { sectionModels in
                    self.days = sectionModels.map { $0.day }
                }
            )
            .drive(collectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
        
        output.availableDays
            .drive(
                onNext: { [weak self] arg in
                    self?.availableDays.accept(arg)
                    self?.emptyStateView.isHidden = !arg.isEmpty
                }
            )
            .disposed(by: disposeBag)
        
        output.camMap
            .drive { [weak self] data in
                guard let self = self else {
                    return
                }
                
                self.camMap = data
            }
            .disposed(by: disposeBag)
        
        availableDays.asDriverOnErrorJustComplete()
            .drive {
                // со всех квартир собираем все дни, убираем дубли, сортируем от поздних к ранним
                self.daysQueue = $0.flatMap { $0.value }
                    .map { $0.day }
                    .withoutDuplicates()
                    .sorted(by: >)
                
                // сохраняем список всех имеющихся дат на будущее - пригодятся.
                self.allAvailableDates = self.daysQueue
                
                // загружаем самый первый день
                guard let firstDay = self.daysQueue.first else {
                    return
                }
                self.daysQueue.remove(at: 0)
                self.loadDayTriger.onNext(firstDay)
                
            }
            .disposed(by: disposeBag)
        
    }
}

extension HistoryDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        
        return CGSize(width: collectionView.width - 32, height: collectionView.height)
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if stopDynamicLoading {
            return
        }
        
        // тут мы будем динамически подгружать данные
        guard let dataSource = dataSource else {
            return
        }
        let section = dataSource.sectionModels[indexPath.section]
        
        // получаем время секции
        let day = section.day
        
        // ищем день, который будет отображаться
        guard let willDisplayDayIndex = allAvailableDates.firstIndex(of: day) else {
            return
        }
        
        // если предыдущий не загружен - загружаем
        if  willDisplayDayIndex + 1 < allAvailableDates.count {
            let nextDay = allAvailableDates[willDisplayDayIndex + 1]
            if daysQueue.contains(nextDay) {
                daysQueue.removeAll(nextDay)
                loadDayTriger.onNext(nextDay)
            }
        }
        // если следующий не загружен - загружаем
        if willDisplayDayIndex - 1 >= 0 {
            let previousDay = allAvailableDates[willDisplayDayIndex - 1]
            if daysQueue.contains(previousDay) {
                daysQueue.removeAll(previousDay)
                loadDayTriger.onNext(previousDay)
            }
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let center = self.view.convert(self.collectionView.center, to: self.collectionView)
        
        guard let indexPath = collectionView!.indexPathForItem(at: center) else {
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
}
