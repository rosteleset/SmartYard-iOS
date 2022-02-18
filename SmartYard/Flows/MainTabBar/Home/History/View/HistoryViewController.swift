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

class HistoryViewController: BaseViewController, LoaderPresentable, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var tableView: UITableViewWithHandler!
    @IBOutlet private weak var toolbar: UIToolbar!
    @IBOutlet private weak var topToolbarPositon: NSLayoutConstraint!
    
    @IBOutlet private weak var eventsFilterButton: UIButton!
    @IBOutlet private weak var calendarButton: UIButton!
    @IBOutlet private weak var appartmentFilterButton: UIButton!
    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var scrollUpButton: UIButton!
    
    private var refreshControl = UIRefreshControl()

    var lastContentOffset: CGFloat = 0.0
    let maxHeaderHeight: CGFloat = 44.0
    var lockToolbar = false
    var scrollOnDateIfLoads: Date?
    var stopDynamicLoading = false
    
    var loader: JGProgressHUD?
    
    fileprivate let viewModel: HistoryViewModel
    internal var eventsFilter = BehaviorRelay<EventsFilter>(value: .all)
    private var apptsFilterString = BehaviorRelay<String>(value: "все") 
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
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
    }
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        refreshControl.tintColor = UIColor.SmartYard.gray
        
        tableView.register(nibWithCellClass: HistoryTableViewCell.self)
        tableView.register(nibWithCellClass: HistoryLoadingTableViewCell.self)
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
       
        dataSource = RxTableViewSectionedAnimatedDataSource<HistorySectionModel>(
            configureCell: { [weak self] dataSource, tableView, indexPath, item in
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
        toolbar.view.layer.shadowPath = UIBezierPath(rect: toolbar.view.bounds).cgPath
        toolbar.view.layer.shadowRadius = 32
        toolbar.view.layer.shadowOffset = CGSize(width: 0, height: 4)
        toolbar.view.layer.shadowOpacity = 1
        toolbar.view.layer.shadowColor = UIColor(red: 0.268, green: 0.338, blue: 0.421, alpha: 0.18).cgColor
        
        scrollUpButton.view.layer.shadowPath = UIBezierPath(roundedRect: scrollUpButton.view.bounds, cornerRadius: 24).cgPath
        scrollUpButton.view.layer.shadowRadius = 24
        scrollUpButton.view.layer.shadowOffset = CGSize(width: 0, height: 4)
        scrollUpButton.view.layer.shadowOpacity = 1
        scrollUpButton.view.layer.shadowColor = UIColor(red: 0.268, green: 0.338, blue: 0.421, alpha: 0.18).cgColor
        scrollUpButton.view.clipsToBounds = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fakeNavBar.setText("Адреса")
        setupShadows()
        setupTableView()
        bind()
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
                    self.days = sectionModels.map({ $0.day })
                    self.refreshControl.endRefreshing()
                }
            )
            .drive(tableView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
        
        output.isLoading 
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
        output.address
            .drive(addressLabel.rx.text)
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
                if self.viewModel.flatIds.count > 1 {
                    self.appartmentFilterButton.isHidden = false
                } else {
                    self.appartmentFilterButton.isHidden = true
                }
                
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
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.stopDynamicLoading = false
            self?.lockToolbar = false
        }
    }
    
    @IBAction private func tapEvents(_ sender: UIView) {
        
        showEventsFilterPopover(
            from: eventsFilterButton.imageView!,
            items: EventsFilter.allCasesString,
            onSelect: { name, _ in
                self.eventsFilterButton.setTitle(name, for: .normal)
                self.eventsFilterButton.sizeToFit()
                self.eventsFilter.accept(EventsFilter.allCases.first(where: { $0.name == name }) ?? .all)
                
                self.topToolbarPositon.constant = 0
                
            }
        )
    }
    
    @IBAction private func tapAppartments(_ sender: UIView) {
        let flatLabels = ["Все квартиры"] + viewModel.flatNumbers.map { "Квартира " + String($0) }
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
                    self.appartmentFilterButton.setTitle("Квартира, все", for: .normal)
                } else {
                    self.appartmentFilterButton.setTitle("Квартира, \(self.viewModel.flatNumbers[selectedRow - 1])", for: .normal)
                }
                self.appartmentFilterButton.sizeToFit()
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
        
        showCalendarPopover(
            from: calendarButton.imageView!,
            minDate: allAvailableDates.last ?? Date(),
            maxDate: Date(),
            onSelect: { date in
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
                self.loadDayTriger.onNext(scrollOnDay)
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
        if  willDisplayDayIndex - 1 >= 0 {
            let previousDay = allAvailableDates[willDisplayDayIndex - 1]
            if daysQueue.contains(previousDay) {
                daysQueue.removeAll(previousDay)
                loadDayTriger.onNext(previousDay)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 6.0
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude // это "ноль"
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
                
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 6))
        
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
        
        if scrollView.contentOffset.y > 0 && scrollUpButton.alpha == 0 {
            scrollUpButton.view.fadeIn(duration: 0.5, completion: { _ in self.scrollUpButton.isHidden = false })
        }
        if scrollView.contentOffset.y <= 0 && scrollUpButton.alpha == 1 {
            scrollUpButton.view.fadeOut(duration: 0.5, completion: { _ in self.scrollUpButton.isHidden = true })
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
            topToolbarPositon.constant = -44
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
        if (scrollView.contentOffset.y > self.lastContentOffset) && topToolbarPositon.constant != -44.0 {
            // Scrolling down
            topToolbarPositon.constant = -44
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
