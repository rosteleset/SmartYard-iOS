//
//  ArchivePageViewController.swift
//  SmartYard
//
//  Created by admin on 15.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JTAppleCalendar
import JGProgressHUD

protocol ArchivePageViewControllerDelegate: AnyObject {
    
    func archivePageViewController(_ vc: ArchivePageViewController, didSelectDate date: Date)
    
}

final class ArchivePageViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var calendarView: JTACMonthView!
    @IBOutlet private weak var monthLabel: UILabel!
    @IBOutlet private weak var leftArrowButton: UIButton!
    @IBOutlet private weak var rightArrowButton: UIButton!
    
    private let apiWrapper: APIWrapper
    
    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()
    
    private var archiveRangesDisposeBag = DisposeBag()
    
    var loader: JGProgressHUD?
    
    weak var delegate: ArchivePageViewControllerDelegate?
    
    // Если вызывать reloadData в то время, когда календаря нет на экране - все идет по 3.14зде
    // Почему? Потому что разработчики библиотеки - кайфовые ребята
    // Что делать? Добавляем флаг
    
    private var shouldReloadOnAppear = false
    
    // MARK: Доступные периоды для просмотра архивных видео
    // Если календарь видно - обновляемся. Если не видно - выставляем флаг
    
    private var availableRanges: [APIArchiveRange]? {
        didSet {
            calculateDateLimits(for: availableRanges)
            
            guard isVisible else {
                shouldReloadOnAppear = true
                return
            }
            
            calendarView.reloadData()
        }
    }
    
    // MARK: Максимальная доступная дата среди всех интервалов. Нужна для конфигурации календаря
    
    private var upperDateLimit: Date?
    
    // MARK: Минимальная доступная дата среди всех интервалов. Нужна для конфигурации календаря
    
    private var lowerDateLimit: Date?
    
    private func calculateDateLimits(for ranges: [APIArchiveRange]?) {
        guard let ranges = ranges else {
            lowerDateLimit = nil
            upperDateLimit = nil
            return
        }
        
        lowerDateLimit = ranges.compactMap { $0.startDate }.min()
        upperDateLimit = ranges.compactMap { $0.endDate }.max()
    }
    
    init(apiWrapper: APIWrapper) {
        self.apiWrapper = apiWrapper
        
        super.init(nibName: nil, bundle: nil)
        
        title = NSLocalizedString("Archive", comment: "")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: Именно пробел. Если оставить nil или "", календарь скакать будет при первой загрузке
        
        monthLabel.text = " "
        leftArrowButton.isHidden = true
        rightArrowButton.isHidden = true
        
        configureCalendarView()
        
        bind()
    }
    
    // MARK: Костыль, чтобы не моргал хэдер (иначе он будет пустой до viewDidAppear)
    // А обновить данные прямо здесь мы не можем, только во viewDidAppear
    // Поэтому тут обновляем хэдер
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        calendarView.deselectAllDates()
        
        guard shouldReloadOnAppear else {
            return
        }
        
        setupCalendarHeader(from: upperDateLimit)
    }
    
    // А тут обновляем данные, а потом еще и хэдер на всякий случай
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard shouldReloadOnAppear else {
            return
        }
        
        shouldReloadOnAppear = false
        
        calendarView.reloadData(withAnchor: upperDateLimit) { [weak self] in
            guard let self = self else {
                return
            }
            
            self.setupCalendarHeader(from: self.calendarView.visibleDates().monthDates.first?.date)
        }
    }
    
    func setAvailableRanges(_ ranges: [APIArchiveRange]?) {
        availableRanges = ranges
    }
    
    private func bind() {
        activityTracker
            .asDriver()
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
        errorTracker
            .asDriver()
            .drive(
                onNext: { [weak self] _ in
                    self?.availableRanges = nil
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureCell(view: JTACDayCell?, cellState: CellState) {
        guard let myCustomCell = view as? CustomDayCell else {
            return
        }
        
        let startOfDay = Calendar.serverCalendar.startOfDay(for: cellState.date)
        let endOfDay = startOfDay.adding(.hour, value: 24)
        
        let matchingRange = availableRanges?.first { range in
            (startOfDay < range.endDate) && (range.startDate < endOfDay)
        }
        
        myCustomCell.configure(
            with: cellState,
            isValidDate: matchingRange != nil
        )
    }
    
    private func setupCalendarHeader(from visibleDate: Date?) {
        guard let visibleDate = visibleDate else {
            return
        }
        
        // MARK: Заголовок
        
        let formatter = DateFormatter()
        
        formatter.timeZone = Calendar.serverCalendar.timeZone
        formatter.locale = Calendar.current.locale
        formatter.dateFormat = "LLLL"
        
        let nameOfMonth = formatter.string(from: visibleDate).capitalized
        let year = Calendar.serverCalendar.component(.year, from: visibleDate)
        
        monthLabel.text = nameOfMonth + " " + String(year)
        
        // MARK: Показ и скрытие стрелочек
        
        guard let lowerBound = lowerDateLimit, let upperBound = upperDateLimit else {
            leftArrowButton.isHidden = true
            rightArrowButton.isHidden = true
            
            return
        }
        
        let startDateMonth = lowerBound.month
        let endDateMonth = upperBound.month
        let visibleDateMonth = visibleDate.month
        
        leftArrowButton.isHidden = visibleDateMonth <= startDateMonth
        rightArrowButton.isHidden = visibleDateMonth >= endDateMonth
    }
    
    private func configureCalendarView() {
        calendarView.register(nibWithCellClass: CustomDayCell.self)
        
        let headerNib = UINib(nibName: "WhiteSectionHeaderView", bundle: Bundle.main)
        calendarView.register(
            headerNib,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "WhiteSectionHeaderView"
        )
        
        calendarView.calendarDelegate = self
        calendarView.calendarDataSource = self
        
        calendarView.scrollingMode = .stopAtEachCalendarFrame
        calendarView.minimumLineSpacing = 0
        calendarView.minimumInteritemSpacing = 0
        
        calendarView.reloadData(withAnchor: Date())
        
        leftArrowButton.rx
            .tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    self?.calendarView.scrollToSegment(.previous)
                }
            )
            .disposed(by: disposeBag)
        
        rightArrowButton.rx
            .tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    self?.calendarView.scrollToSegment(.next)
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension ArchivePageViewController: JTACMonthViewDataSource, JTACMonthViewDelegate {

    func calendar(
        _ calendar: JTACMonthView,
        headerViewForDateRange range: (start: Date, end: Date),
        at indexPath: IndexPath
    ) -> JTACMonthReusableView {
        // swiftlint:disable force_cast
        return calendar.dequeueReusableJTAppleSupplementaryView(
            withReuseIdentifier: "WhiteSectionHeaderView",
            for: indexPath
        ) as! WhiteSectionHeaderView
    }

    func calendarSizeForMonths(_ calendar: JTACMonthView?) -> MonthSize? {
        return MonthSize(defaultSize: 40)
    }

    func calendar(
        _ calendar: JTACMonthView,
        willDisplay cell: JTACDayCell,
        forItemAt date: Date,
        cellState: CellState,
        indexPath: IndexPath
    ) {
        configureCell(view: cell, cellState: cellState)
    }

    func calendar(
        _ calendar: JTACMonthView,
        cellForItemAt date: Date,
        cellState: CellState,
        indexPath: IndexPath
    ) -> JTACDayCell {
        // swiftlint: force_cast
        let cell = calendar.dequeueReusableJTAppleCell(
            withReuseIdentifier: "CustomDayCell",
            for: indexPath
        ) as! CustomDayCell

        configureCell(view: cell, cellState: cellState)

        return cell
    }

    func configureCalendar(_ calendar: JTACMonthView) -> ConfigurationParameters {
        let (startDate, endDate): (Date, Date) = {
            guard let lowerBound = lowerDateLimit, let upperBound = upperDateLimit else {
                let date = Date()
                
                return (date, date)
            }
            
            return (lowerBound, upperBound)
        }()

        let parameters = ConfigurationParameters(
            startDate: startDate,
            endDate: endDate,
            numberOfRows: 6,
            calendar: Calendar.current,
            generateInDates: .forAllMonths,
            generateOutDates: .tillEndOfGrid,
            firstDayOfWeek: .monday,
            hasStrictBoundaries: true
        )

        return parameters
    }

    func calendar(
        _ calendar: JTACMonthView,
        shouldSelectDate date: Date,
        cell: JTACDayCell?,
        cellState: CellState,
        indexPath: IndexPath
    ) -> Bool {
        guard let availableRanges = availableRanges, !availableRanges.isEmpty else {
            return false
        }
        
        let startOfDay = Calendar.serverCalendar.startOfDay(for: cellState.date)
        let endOfDay = startOfDay.adding(.hour, value: 24)
        
        let matchingRange = availableRanges.first { range in
            (startOfDay < range.endDate) && (range.startDate < endOfDay)
        }
        
        return matchingRange != nil
    }

    func calendar(
        _ calendar: JTACMonthView,
        didSelectDate date: Date,
        cell: JTACDayCell?,
        cellState: CellState,
        indexPath: IndexPath
    ) {
        configureCell(view: cell, cellState: cellState)

        delegate?.archivePageViewController(self, didSelectDate: date)
    }

    func calendar(
        _ calendar: JTACMonthView,
        didDeselectDate date: Date,
        cell: JTACDayCell?,
        cellState: CellState,
        indexPath: IndexPath
    ) {
        configureCell(view: cell, cellState: cellState)
    }

    func calendar(_ calendar: JTACMonthView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        setupCalendarHeader(from: visibleDates.monthDates.first?.date)
    }

}
