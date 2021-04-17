//
//  YardMapViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import Mapbox
import JGProgressHUD
import RxSwift
import RxCocoa
import RxDataSources
import PopOverDatePicker


class HistoryViewController: BaseViewController, LoaderPresentable, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var toolbar: UIToolbar!
    @IBOutlet private weak var topToolbarPositon: NSLayoutConstraint!
    
    @IBOutlet private weak var eventsFilterButton: UIButton!
    @IBOutlet private weak var calendarButton: UIButton!
    @IBOutlet private weak var appartmentFilterButton: UIButton!
    @IBOutlet private weak var eventsFilterBarButton: UIBarButtonItem!
    @IBOutlet private weak var calendarBarButton: UIBarButtonItem!
    
    //private var dataSource: RxTableViewSectionedReloadDataSource<HistorySectionModel>?
    private var dataSource: RxTableViewSectionedAnimatedDataSource<HistorySectionModel>?
    
    var loader: JGProgressHUD?
    
    private let viewModel: HistoryViewModel
    public var eventsFilter: EventsFilter = .all
    public var apptsFilter: [String] = []
    
    private let itemSelectedTrigger = PublishSubject<Int>()
    private let loadDayTriger = PublishSubject<Date>()
    private let dataCache = BehaviorRelay<[DataSection]>(value: []) // здесь
    private var availableDays: [APIPlogDay] = []
    private let sectionProxy = PublishSubject<[HistorySectionModel]>()
    
    
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
        //tableView.dataSource = self
        tableView.register(nibWithCellClass: HistoryTableViewCell.self)
        tableView.register(nibWithCellClass: HistoryLoadingTableViewCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CELL")
        
        //tableView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupShadows()
        setupTableView()
        bind()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func bind() {
        let input = HistoryViewModel.Input(
            itemSelected: itemSelectedTrigger.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            loadDay: loadDayTriger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        sectionProxy //отсюда притетает свежий dataSource для таблицы
            .bind(to: tableView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
        
        output.isLoading 
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
        output.plog //отсюда прилетает список событий журнала за день для квартиры
            .drive(
                onNext: { [weak self] data in
                    guard let self = self,
                          let dataSource = self.dataSource else {
                        return
                    }
                    self.dataCache.accept(self.dataCache.value + [data])
                    
                    let sections = dataSource.sectionModels
                    var new = sections
                    
                    guard let sectionIndex = sections.firstIndex(where: {$0.day == data.day}) else {
                        return
                    }
                    let item = sections[sectionIndex]
                    let historyItems = data.items.enumerated().map { HistoryDataItem(identity: "\(sectionIndex)-\($0.offset)", value: $0.element) }
                    
                    new[sectionIndex] = HistorySectionModel(identity: item.identity, itemsCount: item.itemsCount, state: .loaded, items: historyItems )
                    
                    self.sectionProxy.onNext(new)
                    
                }
            )
        
        output.address
            .drive(addressLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.availableDays //отсюда прилетает список доступных в журнале дней для каждой квартиры
            .drive { [weak self] logs, flatId in
                guard let self = self else {
                    return
                }
                self.availableDays = logs
                let sections = logs.map { day -> HistorySectionModel in
                   
                    let section = Array(0...day.itemsCount-1).map( { HistoryDataItem(identity: "\(day)-\($0)", value: APIPlog()) } )
                    
                    return HistorySectionModel(identity: day.day, itemsCount: day.itemsCount, state: .waiting, items: section)
                }
                
                self.sectionProxy.onNext(sections)
            }
            .disposed(by: disposeBag)
        
        dataCache
            .asDriver()
            .drive { [weak self] dataSection in
                //
                
            }
    }
    
    fileprivate func configureCell(_ indexPath: IndexPath, _ cell: HistoryTableViewCell, _ dataSource: TableViewSectionedDataSource<HistorySectionModel>) {
        
        
        let cellOrder: HistoryCellOrder = {
            switch indexPath.row {
            case 0:
                return dataSource.sectionModels[indexPath.section].items.count == 1 ? .single : .first
            case dataSource.sectionModels[indexPath.section].items.count - 1 :
                return .last
            default:
                return .regular
            }
        }()
        
        let value = dataSource.sectionModels[indexPath.section].items[indexPath.row].value
       
        if value.uuid == "" {
            cell.configureEmptyCell(cellOrder: cellOrder, day: dataSource.sectionModels[indexPath.section].day)
            return
        }
        
        cell.configureCell(cellOrder: cellOrder, from: value)
        
    }
    
    
    
    @IBAction private func tapEvents(_ sender: UIView) {
        
        showEventsFilterPopover(from: eventsFilterButton.imageView!) { name, selectedRow in
            self.eventsFilterButton.setTitle(name, for: .normal)
            self.eventsFilterButton.sizeToFit()
            
            self.eventsFilter = EventsFilter(rawValue: selectedRow) ?? .all
        }
    }
    
    @IBAction private func tapAppartments(_ sender: UIView) {
    }
    
    @IBAction private func tapCalendar(_ sender: Any) {
        let date = Date()
        
        let popOverDatePickerViewController = PopOverDatePickerViewController.instantiate()
        popOverDatePickerViewController.set(date: date)
        popOverDatePickerViewController.set(minimumDate: availableDays.last?.day ?? date)
        popOverDatePickerViewController.set(maximumDate: date)
        popOverDatePickerViewController.set(datePickerMode: .date)
        popOverDatePickerViewController.set(locale: Locale(identifier: "ru-RU"))
        popOverDatePickerViewController.popoverPresentationController?.barButtonItem = calendarBarButton
        popOverDatePickerViewController.presentationController?.delegate = self
        popOverDatePickerViewController.changeHandler = { date in
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: self.availableDays.firstIndex(where: { $0.day <= date }) ?? 0),
                                       at: .top,
                                       animated: true)
        }
        
        showPopup(popOverDatePickerViewController, sourceView: calendarButton.imageView!)
       
    }
}

extension HistoryViewController: UITableViewDelegate {
    /*func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return availableDays[section].day.apiString
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .zero
    }*/
    
    /*func numberOfSections(in tableView: UITableView) -> Int {
        return availableDays.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableDays[section].itemsCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: HistoryLoadingTableViewCell = tableView.dequeueReusableCell(withClass: HistoryLoadingTableViewCell.self, for: indexPath)
        cell.isLoading = true
        return cell
    }
    */
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let dataSource = dataSource else {
            return
        }
        let section = dataSource.sectionModels[indexPath.section]
        
        if section.state == .waiting {
            loadDayTriger.onNext(section.day)
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
                
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 6))
        
        headerView.backgroundColor = .clear
        return headerView
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
                
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 0))
        
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        topToolbarPositon.constant = velocity.y > 0 ? -44 : 0
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [UIView.AnimationOptions.allowUserInteraction], animations: {
            self.view.layoutIfNeeded()
        })
    }
}

/* наработки для убираемого тулбара
 {
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!

    var lastContentOffset: CGFloat = 0.0
    let maxHeaderHeight: CGFloat = 115.0

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
            //Scrolled to bottom
            UIView.animate(withDuration: 0.3) {
                self.heightConstraint.constant = 0.0
                self.view.layoutIfNeeded()
            }
        }
        else if (scrollView.contentOffset.y < self.lastContentOffset || scrollView.contentOffset.y <= 0) && (self.heightConstraint.constant != self.maxHeaderHeight)  {
            //Scrolling up, scrolled to top
            UIView.animate(withDuration: 0.3) {
                self.heightConstraint.constant = self.maxHeaderHeight
                self.view.layoutIfNeeded()
            }
        }
        else if (scrollView.contentOffset.y > self.lastContentOffset) && self.heightConstraint.constant != 0.0 {
            //Scrolling down
            UIView.animate(withDuration: 0.3) {
                self.heightConstraint.constant = 0.0
                self.view.layoutIfNeeded()
            }
        }
        self.lastContentOffset = scrollView.contentOffset.y
    }
}
*/

