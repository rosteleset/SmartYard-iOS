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

protocol ArchivePageViewControllerDelegate: AnyObject {
    
    func archivePageViewController(_ vc: ArchivePageViewController, didSelectDate date: Date)
    
}

class ArchivePageViewController: BaseViewController {
    
    @IBOutlet private weak var calendarView: JTACMonthView!
    @IBOutlet private weak var monthLabel: UILabel!
    @IBOutlet private weak var leftArrowButton: UIButton!
    @IBOutlet private weak var rightArrowButton: UIButton!
    
    private let formatter = DateFormatter()
    private let currentCalendar = Calendar.current
    
    private let endDate = Date()
    
    private var startDate: Date {
        return endDate.adding(.day, value: -7)
    }
    
    weak var delegate: ArchivePageViewControllerDelegate?
    
    init() {
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
    
    private func configureCell(view: JTACDayCell?, cellState: CellState) {
        guard let myCustomCell = view as? CustomDayCell else {
            return
        }
        
        myCustomCell.configure(
            with: cellState,
            isValidDate: cellState.date.isBetween(startDate, endDate, includeBounds: true)
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
        
        let startDateMonth = startDate.month
        let endDateMonth = endDate.month
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
        return date.isBetween(startDate, endDate, includeBounds: true)
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
