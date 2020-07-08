//
//  ArchivePageViewController.swift
//  SmartYard
//
//  Created by admin on 15.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JTAppleCalendar
import JGProgressHUD

protocol ArchivePageViewControllerDelegate: AnyObject {
    
    func archivePageViewController(_ vc: ArchivePageViewController, didSelectDate date: Date)
    
}

class ArchivePageViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var calendarView: JTACMonthView!
    @IBOutlet private weak var monthLabel: UILabel!
    @IBOutlet private weak var leftArrowButton: UIButton!
    @IBOutlet private weak var rightArrowButton: UIButton!
    
    private let formatter = DateFormatter()
    private let currentCalendar = Calendar.current
    
    private let apiWrapper: APIWrapper
    
    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()
    
    private var archiveRangesDisposeBag = DisposeBag()
    
    var loader: JGProgressHUD?
    
    weak var delegate: ArchivePageViewControllerDelegate?
    
    // MARK: Доступные периоды для просмотра архивных видео
    // При получении новых данных - обновляем датасорс, чтобы конфигурация календаря поменялась
    
    private var availableRanges: [APIArchiveRange]? {
        didSet {
            calendarView.calendarDataSource = self
        }
    }
    
    // MARK: Максимальная доступная дата среди всех интервалов. Нужна для конфигурации календаря
    
    private var upperDateLimit: Date? {
        let maxDate = availableRanges?
            .map { $0.endDate }
            .max()
        
        // Если у нас 00:00, то в Москве еще 23:00. Соответственно, у них не наступил новый день и выбрать его нельзя
        // Поэтому вычитаем разницу между локальной таймзоной и МСК из текущего времени
        
        let diffWithMoscow = TimeZone.current.secondsFromGMT() / 3600 - Date.moscowOffsetFromGMT
        
        return maxDate?.adding(.hour, value: -diffWithMoscow)
    }
    
    // MARK: Минимальная доступная дата среди всех интервалов. Нужна для конфигурации календаря
    
    private var lowerDateLimit: Date? {
        let minDate = availableRanges?
            .map { $0.startDate }
            .min()
        
        // Если у нас 00:00, то в Москве еще 23:00. Соответственно, у них не наступил новый день и выбрать его нельзя
        // Поэтому вычитаем разницу между локальной таймзоной и МСК из текущего времени
        
        let diffWithMoscow = TimeZone.current.secondsFromGMT() / 3600 - Date.moscowOffsetFromGMT
        
        return minDate?.adding(.hour, value: -diffWithMoscow)
    }
    
    init(apiWrapper: APIWrapper) {
        self.apiWrapper = apiWrapper
        
        super.init(nibName: nil, bundle: nil)
        
        title = "Архив"
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCalendarView()
        setupCalendar()
        
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupCalendar()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let visibleDates = calendarView.visibleDates()
        calendarView.viewWillTransition(to: size, with: coordinator, anchorDate: visibleDates.monthDates.first?.date)
        setupCalendar()
    }
    
    func setupCalendar() {
        setupCalendarHeader(from: calendarView.visibleDates())
    }
    
    func updateAvailableDates(camera: CameraObject) {
        archiveRangesDisposeBag = DisposeBag()
        availableRanges = []
        
        apiWrapper
            .getArchiveRanges(cameraUrl: camera.video, from: 1525186456, token: camera.token)
            .trackActivity(activityTracker)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] ranges in
                    self?.availableRanges = ranges
                }
            )
            .disposed(by: archiveRangesDisposeBag)
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
        
        let matchingRange = availableRanges?.first { range in
            let diffWithMoscow = TimeZone.current.secondsFromGMT() / 3600 - Date.moscowOffsetFromGMT
            
            guard let startDate = range.startDate.adding(.hour, value: -diffWithMoscow).beginning(of: .day),
                let endDate = range.endDate.adding(.hour, value: -diffWithMoscow).end(of: .day) else {
                return false
            }
            
            return cellState.date.isBetween(startDate, endDate, includeBounds: true)
        }
        
        myCustomCell.configure(
            with: cellState,
            isValidDate: matchingRange != nil
        )
    }
    
    private func setupCalendarHeader(from visibleDates: DateSegmentInfo) {
        guard let visibleDate = visibleDates.monthDates.first?.date else {
            return
        }
        
        // MARK: Заголовок
        
        formatter.dateFormat = "LLLL"
        
        let nameOfMonth = formatter.string(from: visibleDate).capitalized
        let year = currentCalendar.component(.year, from: visibleDate)
        
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
        
        calendarView.scrollToDate(Date())
        
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
        formatter.dateFormat = "yyyy MM dd"
        formatter.timeZone = currentCalendar.timeZone
        formatter.locale = .init(identifier: "RU")
        
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
            calendar: currentCalendar,
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
        
        let matchingRange = availableRanges.first { range in
            let diffWithMoscow = TimeZone.current.secondsFromGMT() / 3600 - Date.moscowOffsetFromGMT
            
            guard let startDate = range.startDate.adding(.hour, value: -diffWithMoscow).beginning(of: .day),
                let endDate = range.endDate.adding(.hour, value: -diffWithMoscow).end(of: .day) else {
                return false
            }
            
            return date.isBetween(startDate, endDate, includeBounds: true)
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
        setupCalendarHeader(from: visibleDates)
    }

}
