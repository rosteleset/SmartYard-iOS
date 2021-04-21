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
    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var scrollUpButton: UIButton!

    var lastContentOffset: CGFloat = 0.0
    let maxHeaderHeight: CGFloat = 44.0
    
    var loader: JGProgressHUD?
    
    fileprivate let viewModel: HistoryViewModel
    public var eventsFilter = BehaviorRelay<EventsFilter>(value: .all)
    public var apptsFilter = BehaviorRelay<String>(value: "все") 
    
    private let itemSelectedTrigger = PublishSubject<Int>()
    private let loadDayTriger = PublishSubject<Date>()
    private let dataCache = BehaviorRelay<[DataSection]>(value: [])
    private var availableDays = BehaviorRelay<AvailableDays>(value: [:])
    //private let sectionProxy = PublishSubject<[HistorySectionModel]>()
    
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
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
       
        viewModel.dataSource = RxTableViewSectionedAnimatedDataSource<HistorySectionModel>(
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
            loadDay: loadDayTriger.asDriverOnErrorJustComplete(),
            eventsFilter: eventsFilter.asDriver(),
            apptsFilter: apptsFilter.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.sections //отсюда притетает свежий [HistorySectionModels] для DataSource таблицы
            .bind(to: tableView.rx.items(dataSource: viewModel.dataSource!))
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
        
        availableDays.asDriverOnErrorJustComplete()
            .drive {
                if $0.keys.count > 1 {
                    self.appartmentFilterButton.isHidden = false
                } else {
                    self.appartmentFilterButton.isHidden = true
                }
                
                //TODO: временный костыль, надо заменить на днамическую загрузку
                $0.forEach { (key: FlatId, value: PlogDaysResponseData) in
                    value.forEach { item in
                        self.loadDayTriger.onNext(item.day)
                    }
                }
                
                
            }
            .disposed(by: disposeBag)
        
    }
    
    fileprivate func configureCell(_ indexPath: IndexPath, _ cell: HistoryTableViewCell, _ dataSource: TableViewSectionedDataSource<HistorySectionModel>) {
        let cellOrder = dataSource.sectionModels[indexPath.section].items[indexPath.row].order
        let value = dataSource.sectionModels[indexPath.section].items[indexPath.row].value
        cell.configureCell(cellOrder: cellOrder, from: value)
    }
    
    @IBAction private func tapScrollUp(_ sender: Any) {
        tableView.scrollToTop()
    }
    
    @IBAction private func tapEvents(_ sender: UIView) {
        showEventsFilterPopover(
            from: eventsFilterButton.imageView!,
            onSelect: { name, selectedRow in
                self.eventsFilterButton.setTitle(name, for: .normal)
                self.eventsFilterButton.sizeToFit()
                self.eventsFilter.accept(EventsFilter(rawValue: selectedRow) ?? .all)
                
                self.topToolbarPositon.constant = 0
                
            }
        )
    }
    
    @IBAction private func tapAppartments(_ sender: UIView) {
        let flatLabels = ["Все квартиры"] + viewModel.flatNumbers.map { "Квартира " + String($0) }
        let itemsId = [""] + viewModel.flatIds.map { String($0) }
        
        let selectedRow = { () -> Int in
            if viewModel.apptsFilter.value.count == 1 {
                return itemsId.firstIndex(of: String(viewModel.apptsFilter.value[0])) ?? 0
            } else {
                return 0
            }
        }()
        showAppartmentsFilterPopover(
            from: appartmentFilterButton.imageView!,
            items: flatLabels,
            selectedRow: selectedRow,
            onSelect: { _ , selectedRow in
                if selectedRow == 0 {
                    self.appartmentFilterButton.setTitle("Квартира, все", for: .normal)
                } else {
                    self.appartmentFilterButton.setTitle("Квартира, \(self.viewModel.flatNumbers[selectedRow-1])", for: .normal)
                }
                self.appartmentFilterButton.sizeToFit()
                self.apptsFilter.accept(itemsId[selectedRow])
                self.topToolbarPositon.constant = 0
                
            }
        )
    }
 
    @IBAction private func tapCalendar(_ sender: Any) {
        
        guard let days = viewModel.dataSource?.sectionModels else {
            return
        }
        
        showCalendarPopover(
            from: calendarButton.imageView!,
            minDate: days.last?.day ?? Date(),
            maxDate: Date(),
            onSelect: { date in
                self.tableView.scrollToRow(
                    at: IndexPath(row: 0, section: days.firstIndex(where: { $0.day <= date }) ?? 0),
                    at: .top,
                    animated: true
                )
            }
        )
    }
}

extension HistoryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let dataSource = viewModel.dataSource else {
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
        /*
        topToolbarPositon.constant = velocity.y > 0 ? -44 : 0
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [UIView.AnimationOptions.allowUserInteraction], animations: {
            self.view.layoutIfNeeded()
        })
        */
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //print("contentOffset.y = \(scrollView.contentOffset.y)")
        
        //не скрывать тулбар, если контент умещается без скрола
        if scrollView.contentSize.height <= scrollView.frame.size.height {
            topToolbarPositon.constant = 0
            return
        }
        //если скрол-вью отползает в нормальное положение после отскока, то игнорируем это движение
        if scrollView.contentOffset.y <= 0 && (scrollView.contentOffset.y > self.lastContentOffset) {
            return
        }
        
        
        //ниже - магия работы с тулбаром "туда-сюда" при скроле
        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
            //Scrolled to bottom
            topToolbarPositon.constant = -44
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [UIView.AnimationOptions.allowUserInteraction], animations: {
                self.view.layoutIfNeeded()
            })
        }
        else if (scrollView.contentOffset.y < self.lastContentOffset || scrollView.contentOffset.y <= 0) && (topToolbarPositon.constant < 0)  {
            //Scrolling up, scrolled to top
            topToolbarPositon.constant = 0
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [UIView.AnimationOptions.allowUserInteraction], animations: {
                self.view.layoutIfNeeded()
            })
        }
        else if (scrollView.contentOffset.y > self.lastContentOffset) && topToolbarPositon.constant != -44.0 {
            //Scrolling down
            topToolbarPositon.constant = -44
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [UIView.AnimationOptions.allowUserInteraction], animations: {
                self.view.layoutIfNeeded()
            })
        }
        
        self.lastContentOffset = scrollView.contentOffset.y
        //конец "магии" тулбара
        
        //управление скрытием кнопки scrollUp
        if scrollView.contentOffset.y > 0 && scrollUpButton.alpha == 0 {
            scrollUpButton.view.fadeIn(duration: 0.5, completion: { _ in self.scrollUpButton.isHidden = false })
        }
        if scrollView.contentOffset.y <= 0 && scrollUpButton.alpha == 1 {
            scrollUpButton.view.fadeOut(duration: 0.5, completion: { _ in self.scrollUpButton.isHidden = true })
        }
            
    }
}

