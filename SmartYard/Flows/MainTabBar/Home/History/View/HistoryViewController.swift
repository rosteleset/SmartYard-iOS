//
//  YardMapViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import UIKit
import JGProgressHUD
import RxSwift
import RxCocoa
import RxDataSources

final class HistoryViewController: BaseViewController, LoaderPresentable, UIAdaptivePresentationControllerDelegate {
    
    enum Constants {
        static let toolbarHeight: CGFloat = 64
        static let toolbarHiddenOffset = -toolbarHeight
        static let filterPanelCornerRadius: CGFloat = 12
        static let calendarButtonSize: CGFloat = 36
    }

    @IBOutlet private weak var headerView: HeaderView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private(set) weak var tableView: UITableViewWithHandler!
    @IBOutlet private(set) weak var toolbar: UIView!
    @IBOutlet private(set) weak var topToolbarPositon: NSLayoutConstraint!
    
    @IBOutlet private(set) weak var eventsFilterButton: UIButton!
    @IBOutlet private(set) weak var calendarButton: UIButton!
    @IBOutlet private(set) weak var appartmentFilterButton: UIButton!
    @IBOutlet private(set) weak var scrollUpButton: UIButton!
    @IBOutlet private(set) weak var filterPanelView: UIView!
    @IBOutlet private(set) weak var filterPanelEffectView: UIVisualEffectView!
    @IBOutlet private(set) weak var filterPanelOverlayView: UIView!
    
    private var refreshControl = UIRefreshControl()
    lazy var emptyStateView = makeEmptyStateView()
    var isHistoryLoading = false
    var hasLoadedAvailableDays = false
    var currentSectionModels: [HistorySectionModel] = []

    let daysRadiusToLoad = 6
    var lastContentOffset: CGFloat = 0.0
    let maxHeaderHeight: CGFloat = 44.0
    var lockToolbar = false
    var scrollOnDateIfLoads: Date?
    var stopDynamicLoading = false
    
    var loader: JGProgressHUD?
    
    let viewModel: HistoryViewModel
    internal var eventsFilter = BehaviorRelay<EventsFilter>(value: .all)
    private var apptsFilterString = BehaviorRelay<String>(value: L10n.History.Filter.allOption)
    let apptsFilter = BehaviorRelay<[Int]>(value: [])
    
    let loadDayTriger = PublishSubject<Date>()
    
    private var availableDays = BehaviorRelay<AvailableDays>(value: [:])
    
    /// датасорс для таблицы
    var dataSource: RxTableViewSectionedAnimatedDataSource<HistorySectionModel>?
    
    /// все дни какие есть на сервере для данной комбинации фильтров
    var allAvailableDates: [Date] = []
    
    /// дни, которые есть в sectionModels, т.е. в таблице
    private var days: [Date] = []
    
    /// дни, которые есть на сервере, но их нет в sectionModels - чтобы они оказались в sectionModels, их надо запросить
    var daysQueue: [Date] = []
    
    init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        refreshControl.tintColor = UIColor.SmartYard.gray
        
        tableView.register(nibWithCellClass: HistoryTableViewCell.self)
        // TODO: - Посмотреть где используется
        tableView.register(nibWithCellClass: HistoryLoadingTableViewCell.self)
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.sectionHeaderTopPadding = 0
        tableView.backgroundView = emptyStateView
       
        dataSource = RxTableViewSectionedAnimatedDataSource<HistorySectionModel>(
            configureCell: { [weak self] dataSource, tableView, indexPath, _  in
                let cell: HistoryTableViewCell = tableView.dequeueReusableCell(withClass: HistoryTableViewCell.self, for: indexPath)
                
                guard let self = self else {
                    return cell
                }
                
                self.configureCell(indexPath, cell, dataSource)
                return cell
            }
        )
        
    }
    
    fileprivate func setupShadows() {
        filterPanelView.layer.shadowOpacity = 0
        filterPanelView.layer.masksToBounds = false

        scrollUpButton.view.layer.shadowPath = UIBezierPath(roundedRect: scrollUpButton.view.bounds, cornerRadius: 24).cgPath
        scrollUpButton.view.layer.shadowRadius = 24
        scrollUpButton.view.layer.shadowOffset = CGSize(width: 0, height: 4)
        scrollUpButton.view.layer.shadowOpacity = 1
        scrollUpButton.view.layer.shadowColor = UIColor(red: 0.268, green: 0.338, blue: 0.421, alpha: 0.18).cgColor
        scrollUpButton.view.clipsToBounds = false
    }
    
    private func configureUI() {
        eventsFilterButton.setTitle(L10n.History.Filter.allButton, for: .normal)
        configureFilterPanel()
        updateApartmentFilterTitle(L10n.History.Filter.allApartments)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fakeNavBar.setText(L10n.Tab.addresses)
        setupShadows()
        setupTableView()
        bind()

        registerForTraitChanges(
            UITraitCollection.systemTraitsAffectingColorAppearance,
            action: #selector(handleColorAppearanceChange)
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        filterPanelView.layer.shadowPath = UIBezierPath(
            roundedRect: filterPanelView.bounds,
            cornerRadius: Constants.filterPanelCornerRadius
        ).cgPath
    }
    
    fileprivate func configureCell(_ indexPath: IndexPath, _ cell: HistoryTableViewCell, _ dataSource: TableViewSectionedDataSource<HistorySectionModel>) {
        let cellOrder = dataSource.sectionModels[indexPath.section].items[indexPath.row].order
        let value = dataSource.sectionModels[indexPath.section].items[indexPath.row].value
        cell.configureCell(cellOrder: cellOrder, from: value)
    }
    
    @IBAction private func tapScrollUp(_ sender: Any) {
        stopDynamicLoading = true
        self.topToolbarPositon.constant = 0
        self.view.layoutIfNeeded()
        lockToolbar = true
        if tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.stopDynamicLoading = false
            self?.lockToolbar = false
        }
    }
    
    @IBAction private func tapEvents(_ sender: UIView) {
        logEventFilterOpened(filterType: "event_type")
        
        showEventsFilterPopover(
            from: eventsFilterButton.imageView!,
            items: EventsFilter.allCasesString,
            onSelect: { name, _ in
                self.eventsFilterButton.setTitle(name, for: .normal)
                let selectedFilter = EventsFilter.allCases.first(where: { $0.name == name }) ?? .all
                self.logEventFilterApplied(filterType: "event_type")
                self.logEventTypeSelected(selectedFilter)
                self.hasLoadedAvailableDays = false
                self.updateEmptyState()
                self.eventsFilter.accept(selectedFilter)
                
                self.topToolbarPositon.constant = 0
                
            }
        )
    }
    
    @IBAction private func tapAppartments(_ sender: UIView) {
        logEventFilterOpened(filterType: "apartment")
        let flatLabels = [L10n.History.Filter.allApartments] +
            viewModel.flatNumbers.map { L10n.Address.Form.apartment + " " + String($0) }
        let itemsId = [""] + viewModel.flatIds.map { String($0) }
        
        let selectedRow = { () -> Int in
            if apptsFilter.value.count == 1 {
                return itemsId.firstIndex(of: String(apptsFilter.value[0])) ?? 0
            } else {
                return 0
            }
        }()
        showAppartmentsFilterPopover(
            from: appartmentFilterButton.imageView!,
            items: flatLabels,
            selectedRow: selectedRow,
            onSelect: { _, selectedRow in
                if selectedRow == 0 {
                    self.updateApartmentFilterTitle(L10n.History.Filter.allApartments)
                } else {
                    let title = L10n.Address.Form.apartment
                        + " \(self.viewModel.flatNumbers[selectedRow - 1])"
                    self.updateApartmentFilterTitle(title)
                }
                self.logEventFilterApplied(filterType: "apartment")
                self.hasLoadedAvailableDays = false
                self.updateEmptyState()
                self.apptsFilterString.accept(itemsId[selectedRow])
                self.topToolbarPositon.constant = 0
                
            }
        )
    }
    
    private func onPopUpDismiss() {
        stopDynamicLoading = false
        lockToolbar = false
        scrollOnDateIfLoads = nil
        tableView.afterUpdateHandler = nil
    }
    
    @IBAction private func tapCalendar(_ sender: Any) {
        self.lockToolbar = true
        logEventFilterOpened(filterType: "date")
        
        showCalendarPopover(
            from: calendarButton.imageView!,
            minDate: allAvailableDates.last ?? Date(),
            maxDate: Date(),
            onSelect: { date in
                self.logEventFilterApplied(filterType: "date")
                // предварительно нам надо понять: вообще на какой день мы собираемся отматывать,
                // даже если предположить, что у нас вообще были бы загружены все данные
                guard let scrollOnDay = self.allAvailableDates.first(where: { $0 <= date }) else {
                    // по идее тут мы вообще не должны ну никак оказаться
                    return
                }
                
                // а далее есть варианты:
                // 1) пользователь выберет день, котрый у нас есть в days - тут мы просто на него отматываем
                // 2) пользователь выберет день, которого у нас нет в days, но он есть в daysQueue - его надо подгрузить и потом на него отмотать
                
                if let scrollOnSection = self.days.firstIndex(of: scrollOnDay) {
                    // 1) пользователь выберет день, котрый у нас есть в days - тут мы просто на него отматываем
                    self.tableView.scrollToRow(
                        at: IndexPath(row: 0, section: scrollOnSection),
                        at: .top,
                        animated: true
                    )
                    return
                }
                
                // тут мы оказались, если нужной даты у нас в таблицы пока нет
                // сохраняем дату, на какую мы хотим, чтобы TableView отмотал табличку, когда получит обновления данных
                self.scrollOnDateIfLoads = scrollOnDay
                
                // запрашиваем с сервера данные для этой даты
                self.displayDaysInRadius(scrollOnDay, self.daysRadiusToLoad)
                
                // если обработчика ещё нет, то настраиваем обработчик, который сработает, когда таблица получит свежие данные
                // этот обработчик удалится, когда пользователь закроет pop-up календаря.
                // делается это всё из метода self.onPopUpDismiss() с использованием NotificationCenter
                guard self.tableView.afterUpdateHandler == nil else {
                    return
                }
                self.tableView.afterUpdateHandler = {
                    // проверяем, что нам надо будет скролить таблицу
                    guard let scrollOnDay = self.scrollOnDateIfLoads,
                          // ищем наиболее близкую дату к той, какую хочет найти пользователь
                          let scrollOnSection = self.days.firstIndex(where: { $0 <= scrollOnDay }) else {
                        return
                    }
                    // скролим на эту дату
                    self.tableView.scrollToRow(
                        at: IndexPath(row: 0, section: scrollOnSection),
                        at: .top,
                        animated: false
                    )
                }
            }
        )
    }
}

extension HistoryViewController {
    
    @objc private func handleColorAppearanceChange() {
        filterPanelView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
        updateFilterPanelColors()
    }

    private func analyticsEventType(from filter: EventsFilter) -> String {
        switch filter {
        case .all:
            return "all"
        case .domophones, .phoneCall:
            return "call"
        case .keys:
            return "rfid_access"
        case .faces:
            return "face_access"
        case .application, .code:
            return "door_opened"
        }
    }

    private func logEventFilterOpened(filterType: String) {
        AppAnalytics.log(
            AppAnalyticsEvent.eventFilterOpened(
                filterType: filterType,
                source: "events_toolbar"
            )
        )
    }

    private func logEventFilterApplied(filterType: String) {
        AppAnalytics.log(
            AppAnalyticsEvent.eventFilterApplied(
                filterType: filterType,
                source: "events_toolbar"
            )
        )
    }

    private func logEventTypeSelected(_ filter: EventsFilter) {
        AppAnalytics.log(
            AppAnalyticsEvent.eventTypeSelected(
                eventType: analyticsEventType(from: filter),
                source: "events_toolbar"
            )
        )
    }
    
}

extension HistoryViewController {

    func bind() {
        let itemSelected = tableView.rx.itemSelected
            .map { [weak self] indexPath -> HistoryDataItem? in
                self?.dataSource?.sectionModels[indexPath.section].items[indexPath.row]
            }
            .ignoreNil()

        let input = HistoryViewModel.Input(
            itemSelected: itemSelected.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            loadDay: loadDayTriger.asDriverOnErrorJustComplete(),
            refreshDataTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver(),
            eventsFilter: eventsFilter.asDriver(),
            apptsFilter: apptsFilter.asDriver()
        )

        let output = viewModel.transform(input)

        output.sections // отсюда притетает свежий [HistorySectionModels] для DataSource таблицы
            .do(
                onNext: { sectionModels in
                    self.currentSectionModels = sectionModels
                    self.days = sectionModels.map({ $0.day })
                    self.refreshControl.endRefreshing()
                    if self.days.count >= min(1, self.allAvailableDates.count) {
                        self.updateLoader(isEnabled: false, detailText: nil)
                    }
                    self.updateEmptyState()
                }
            )
            .drive(tableView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)

        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.isHistoryLoading = isLoading
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                    self?.updateFilterPanelLoadingState(isLoading)
                    self?.updateEmptyState()
                }
            )
            .disposed(by: disposeBag)

        output.address
            .drive(
                onNext: { [weak self] address in
                    self?.headerView.setText(
                        L10n.History.title,
                        subtitle: address ?? ""
                    )
                }
            )
            .disposed(by: disposeBag)

        bindCalendar(output)
    }

    private func bindCalendar(_ output: HistoryViewModel.Output) {
        output.availableDays
            .drive(availableDays)
            .disposed(by: disposeBag)

        apptsFilterString
            .map { [weak self] flatString -> [Int] in
                guard let self = self else {
                    return []
                }

                let flatInt = Int(flatString) ?? 0
                if flatInt > 0 {
                    return [flatInt]
                } else {
                    return Array(self.viewModel.flatIds)
                }
            }
            .bind(to: apptsFilter)
            .disposed(by: disposeBag)

        availableDays.asDriverOnErrorJustComplete()
            .drive {
                let selectedFlatIdsCount = self.selectedFlatIdsCount
                self.hasLoadedAvailableDays = selectedFlatIdsCount > 0
                    && $0.count >= selectedFlatIdsCount

                self.appartmentFilterButton.isEnabled = self.viewModel.flatIds.isEmpty == false
                self.appartmentFilterButton.alpha = self.appartmentFilterButton.isEnabled ? 1 : 0.6

                // со всех квартир собираем все дни, убираем дубли, сортируем от поздних к ранним
                self.daysQueue = $0.flatMap { $0.value }
                    .map { $0.day }
                    .withoutDuplicates()
                    .sorted(by: >)

                // сохраняем список всех имеющихся дат на будущее - пригодятся.
                self.allAvailableDates = self.daysQueue
                self.updateEmptyState()

                // загружаем самый первый день
                guard let firstDay = self.daysQueue.first else {
                    return
                }

                self.updateLoader(isEnabled: true, detailText: nil)
                self.daysQueue.remove(at: 0)
                self.loadDayTriger.onNext(firstDay)
                self.displayDaysInRadius(firstDay, self.daysRadiusToLoad)

            }
            .disposed(by: disposeBag)

        // это событие прилетает при закрытии pop-up окошка с календарём
        NotificationCenter.default.rx.notification(.popupDimissed)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            .drive(
                onNext: {
                    self.onPopUpDismiss()
                }
            )
            .disposed(by: disposeBag)
    }
}
