//
//  YardMapViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import JGProgressHUD
import RxSwift
import RxCocoa
import RxDataSources

final class HistoryViewController: BaseViewController, LoaderPresentable, UIAdaptivePresentationControllerDelegate {
    
    private enum Constants {
        static let toolbarHeight: CGFloat = 64
        static let toolbarHiddenOffset = -toolbarHeight
        static let filterPanelCornerRadius: CGFloat = 12
        static let calendarButtonSize: CGFloat = 36
    }

    @IBOutlet private weak var headerView: HeaderView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var tableView: UITableViewWithHandler!
    @IBOutlet private weak var toolbar: UIView!
    @IBOutlet private weak var topToolbarPositon: NSLayoutConstraint!
    
    @IBOutlet private weak var eventsFilterButton: UIButton!
    @IBOutlet private weak var calendarButton: UIButton!
    @IBOutlet private weak var appartmentFilterButton: UIButton!
    @IBOutlet private weak var scrollUpButton: UIButton!
    @IBOutlet private weak var filterPanelView: UIView!
    @IBOutlet private weak var filterPanelEffectView: UIVisualEffectView!
    @IBOutlet private weak var filterPanelOverlayView: UIView!
    
    private var refreshControl = UIRefreshControl()
    private lazy var emptyStateView = makeEmptyStateView()
    private var isHistoryLoading = false
    private var hasLoadedAvailableDays = false
    private var currentSectionModels: [HistorySectionModel] = []

    let daysRadiusToLoad = 6
    var lastContentOffset: CGFloat = 0.0
    let maxHeaderHeight: CGFloat = 44.0
    var lockToolbar = false
    var scrollOnDateIfLoads: Date?
    var stopDynamicLoading = false
    
    var loader: JGProgressHUD?
    
    fileprivate let viewModel: HistoryViewModel
    internal var eventsFilter = BehaviorRelay<EventsFilter>(value: .all)
    private var apptsFilterString = BehaviorRelay<String>(value: L10n.History.Filter.allOption)
    private let apptsFilter = BehaviorRelay<[Int]>(value: [])
    
    private let loadDayTriger = PublishSubject<Date>()
    
    private var availableDays = BehaviorRelay<AvailableDays>(value: [:])
    
    /// датасорс для таблицы
    private var dataSource: RxTableViewSectionedAnimatedDataSource<HistorySectionModel>?
    
    /// все дни какие есть на сервере для данной комбинации фильтров
    private var allAvailableDates: [Date] = []
    
    /// дни, которые есть в sectionModels, т.е. в таблице
    private var days: [Date] = []
    
    /// дни, которые есть на сервере, но их нет в sectionModels - чтобы они оказались в sectionModels, их надо запросить
    private var daysQueue: [Date] = []
    
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
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        filterPanelView.layer.shadowPath = UIBezierPath(
            roundedRect: filterPanelView.bounds,
            cornerRadius: Constants.filterPanelCornerRadius
        ).cgPath
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
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

extension HistoryViewController: UITableViewDelegate {
    
    fileprivate func displayDaysInRadius(_ willDisplayDay: Date, _ radius: Int = 0) {
        guard let willDisplayDayIndex = allAvailableDates.firstIndex(of: willDisplayDay)
        else {
            return
        }
        var i = willDisplayDayIndex - radius
        
        while i <= willDisplayDayIndex + radius {
            if i >= allAvailableDates.startIndex, i < allAvailableDates.endIndex, i != willDisplayDayIndex {
                if daysQueue.contains(allAvailableDates[i]) {
                    daysQueue.removeAll(allAvailableDates[i])
                    loadDayTriger.onNext(allAvailableDates[i])
                }
            }
            i += 1
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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
        
        // пробуем загрузить данные в его окрестности
        displayDaysInRadius(day, self.daysRadiusToLoad)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? CGFloat.leastNormalMagnitude : 6.0
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude // это "ноль"
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let height = section == 0 ? CGFloat.leastNormalMagnitude : 6.0
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: height))
        
        headerView.backgroundColor = .clear
        return headerView
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
                
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 0))
        
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // управление скрытием кнопки scrollUp
        if let dataSource = dataSource, !dataSource.sectionModels.isEmpty {
            if scrollView.contentOffset.y > 0 && scrollUpButton.alpha == 0 {
                scrollUpButton.view.fadeIn(duration: 0.5, completion: { _ in self.scrollUpButton.isHidden = false })
            }
            if scrollView.contentOffset.y <= 0 && scrollUpButton.alpha == 1 {
                scrollUpButton.view.fadeOut(duration: 0.5, completion: { _ in self.scrollUpButton.isHidden = true })
            }
        }
        
        // не скрывать тулбар, если контент умещается без скрола
        if scrollView.contentSize.height <= scrollView.frame.size.height || lockToolbar {
            topToolbarPositon.constant = 0
            self.view.layoutIfNeeded()
            return
        }
        // если скрол-вью отползает в нормальное положение после отскока, то игнорируем это движение
        if scrollView.contentOffset.y <= 0 && (scrollView.contentOffset.y > self.lastContentOffset) {
            return
        }
        
        // ниже - магия работы с тулбаром "туда-сюда" при скроле
        if scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) {
            // Scrolled to bottom
            topToolbarPositon.constant = Constants.toolbarHiddenOffset
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                options: [UIView.AnimationOptions.allowUserInteraction],
                animations: {
                    self.view.layoutIfNeeded()
                }
            )
        } else
        if (
            scrollView.contentOffset.y < self.lastContentOffset ||
            scrollView.contentOffset.y <= 0
        ) && (topToolbarPositon.constant < 0) {
            // Scrolling up, scrolled to top
            topToolbarPositon.constant = 0
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                options: [UIView.AnimationOptions.allowUserInteraction],
                animations: {
                    self.view.layoutIfNeeded()
                }
            )
        } else
        if (scrollView.contentOffset.y > self.lastContentOffset)
            && topToolbarPositon.constant != Constants.toolbarHiddenOffset {
            // Scrolling down
            topToolbarPositon.constant = Constants.toolbarHiddenOffset
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                options: [UIView.AnimationOptions.allowUserInteraction],
                animations: {
                    self.view.layoutIfNeeded()
                }
            )
        }
        
        self.lastContentOffset = scrollView.contentOffset.y
        // конец "магии" тулбара
    }
}

extension HistoryViewController {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

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

private extension HistoryViewController {
    func makeEmptyStateView() -> UIView {
        let containerView = UIView(frame: tableView.bounds)
        containerView.backgroundColor = .clear
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.isHidden = true

        let titleLabel = UILabel.make(
            .bodySemibold,
            text: NSLocalizedString("history.emptyStateMessage", comment: "")
        )
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .SmartYard.gray
        titleLabel.textAlignment = .center

        containerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -32)
        ])

        return containerView
    }

    func updateEmptyState() {
        emptyStateView.isHidden = isHistoryLoading
            || hasLoadedAvailableDays == false
            || allAvailableDates.isEmpty == false
            || currentSectionModels.isEmpty == false
    }

    var selectedFlatIdsCount: Int {
        let selectedFlatIds = apptsFilter.value
        return selectedFlatIds.isEmpty ? viewModel.flatIds.count : selectedFlatIds.count
    }

    func configureFilterPanel() {
        toolbar.backgroundColor = .SmartYard.backgroundColor
        toolbar.layer.borderWidth = 0
        toolbar.layer.borderColor = UIColor.clear.cgColor
        toolbar.clipsToBounds = false

        configureFilterPanelChrome()
        configureEventsFilterButton()
        configureApartmentFilterButton()
        configureCalendarButton()

        updateFilterPanelColors()
    }

    func configureFilterPanelChrome() {
        filterPanelView.backgroundColor = .clear
        filterPanelView.layer.cornerRadius = Constants.filterPanelCornerRadius
        filterPanelView.layer.borderWidth = 1
        filterPanelView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)

        filterPanelEffectView.layer.cornerRadius = Constants.filterPanelCornerRadius
        filterPanelEffectView.clipsToBounds = true
        filterPanelEffectView.isUserInteractionEnabled = false

        filterPanelOverlayView.layer.cornerRadius = Constants.filterPanelCornerRadius
        filterPanelOverlayView.clipsToBounds = true
        filterPanelOverlayView.isUserInteractionEnabled = false
    }

    func configureEventsFilterButton() {
        eventsFilterButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        eventsFilterButton.titleLabel?.lineBreakMode = .byTruncatingTail
        eventsFilterButton.titleLabel?.numberOfLines = 1
        eventsFilterButton.contentHorizontalAlignment = .leading
        eventsFilterButton.semanticContentAttribute = .forceRightToLeft
        eventsFilterButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        eventsFilterButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 0, right: -4)
        eventsFilterButton.setTitleColor(.SmartYard.blue, for: .normal)
        eventsFilterButton.setTitleColor(.SmartYard.blue.withAlphaComponent(0.75), for: .highlighted)
        eventsFilterButton.setImage(
            UIImage(named: "ArrowDown")?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        eventsFilterButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        eventsFilterButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        eventsFilterButton.addTarget(
            self,
            action: #selector(filterPanelButtonTouchDown(_:)),
            for: [.touchDown, .touchDragEnter]
        )
        eventsFilterButton.addTarget(
            self,
            action: #selector(filterPanelButtonTouchUp(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
        )
    }

    func configureApartmentFilterButton() {
        appartmentFilterButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        appartmentFilterButton.titleLabel?.lineBreakMode = .byTruncatingTail
        appartmentFilterButton.titleLabel?.numberOfLines = 1
        appartmentFilterButton.contentHorizontalAlignment = .leading
        appartmentFilterButton.semanticContentAttribute = .forceRightToLeft
        appartmentFilterButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        appartmentFilterButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 0, right: -4)
        appartmentFilterButton.setTitleColor(.SmartYard.blue, for: .normal)
        appartmentFilterButton.setTitleColor(.SmartYard.blue.withAlphaComponent(0.75), for: .highlighted)
        appartmentFilterButton.setImage(
            UIImage(named: "ArrowDown")?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        appartmentFilterButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        appartmentFilterButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        appartmentFilterButton.addTarget(
            self,
            action: #selector(filterPanelButtonTouchDown(_:)),
            for: [.touchDown, .touchDragEnter]
        )
        appartmentFilterButton.addTarget(
            self,
            action: #selector(filterPanelButtonTouchUp(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
        )
    }

    func configureCalendarButton() {
        calendarButton.layer.cornerRadius = Constants.calendarButtonSize / 2
        calendarButton.clipsToBounds = true
        calendarButton.tintColor = .SmartYard.blue
        calendarButton.setImage(
            UIImage(named: "calendar")?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        calendarButton.imageView?.contentMode = .scaleAspectFit
        calendarButton.setContentHuggingPriority(.required, for: .horizontal)
        calendarButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        calendarButton.addTarget(
            self,
            action: #selector(filterPanelButtonTouchDown(_:)),
            for: [.touchDown, .touchDragEnter]
        )
        calendarButton.addTarget(
            self,
            action: #selector(filterPanelButtonTouchUp(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
        )
    }

    func updateApartmentFilterTitle(_ title: String) {
        appartmentFilterButton.setTitle(title, for: .normal)
        appartmentFilterButton.accessibilityLabel = title
    }

    func updateFilterPanelLoadingState(_ isLoading: Bool) {
        filterPanelView.alpha = isLoading ? 0.6 : 1
        filterPanelView.isUserInteractionEnabled = isLoading == false
    }

    func updateFilterPanelColors() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        filterPanelOverlayView.backgroundColor = isDark
            ? UIColor.SmartYard.secondBackgroundColor.withAlphaComponent(0.92)
            : UIColor.SmartYard.secondBackgroundColor.withAlphaComponent(0.96)
        calendarButton.backgroundColor = isDark
            ? UIColor.SmartYard.backgroundColor.withAlphaComponent(0.45)
            : UIColor.SmartYard.backgroundColor.withAlphaComponent(0.65)
    }

    @objc func filterPanelButtonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.14, delay: 0, options: [.allowUserInteraction]) {
            sender.alpha = 0.8
            sender.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }
    }

    @objc func filterPanelButtonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.16, delay: 0, options: [.allowUserInteraction]) {
            sender.alpha = 1
            sender.transform = .identity
        }
    }
}
