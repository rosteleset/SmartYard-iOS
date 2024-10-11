//
//  FullscreenArchiveIntercomPlayerViewController+Calendar.swift
//  SmartYard
//
//  Created by devcentra on 24.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JTAppleCalendar

extension FullscreenArchiveIntercomPlayerViewController {
    
    func configureCalendarView(_ disposeBag: DisposeBag) {
        calendarView.register(nibWithCellClass: BlackDayCell.self)
        
        let headerNib = UINib(nibName: "BlackCalendarHeaderView", bundle: Bundle.main)
        calendarView.register(
            headerNib,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "BlackCalendarHeaderView"
        )
        
        calendarView.calendarDelegate = self
        calendarView.calendarDataSource = self
        
        calendarView.scrollingMode = .stopAtEachCalendarFrame
        calendarView.minimumLineSpacing = 0
        calendarView.minimumInteritemSpacing = 0
        
        calendarLeftArrowButton.rx
            .tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    self?.calendarView.scrollToSegment(.previous)
                }
            )
            .disposed(by: disposeBag)
        
        calendarRightArrowButton.rx
            .tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    self?.calendarView.scrollToSegment(.next)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func setupCalendarHeader(from visibleDate: Date?) {
        guard let visibleDate = visibleDate else {
            return
        }
        
        // MARK: Заголовок
        
        let formatter = DateFormatter()

        formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
        formatter.locale = Calendar.novokuznetskCalendar.locale
        formatter.dateFormat = "LLLL"

        let nameOfMonth = formatter.string(from: visibleDate).capitalized
        
        calendarMonthLabel.text = nameOfMonth
        
        // MARK: Показ и скрытие стрелочек
        
        let maxRangeDate = ranges.compactMap { $0?.endDate }.max() ?? upperDateLimit
        let startDateMonth = lowerDateLimit.month
        let endDateMonth = maxRangeDate.month
        let visibleDateMonth = visibleDate.month
        let startDateYear = lowerDateLimit.year
        let endDateYear = maxRangeDate.year
        
        if endDateYear == startDateYear {
            calendarLeftArrowButton.isHidden = visibleDateMonth <= startDateMonth
            calendarRightArrowButton.isHidden = visibleDateMonth >= endDateMonth
        }
        let visibleDateYear = visibleDate.year
        calendarRightArrowButton.isHidden = (visibleDateYear == endDateYear) && (visibleDateMonth >= endDateMonth)
        calendarLeftArrowButton.isHidden = (visibleDateYear == startDateYear) && (visibleDateMonth <= startDateMonth)
    }

    private func configureCell(view: JTACDayCell?, cellState: CellState) {
        guard let myCustomCell = view as? BlackDayCell else {
            return
        }
        let calendar = Calendar.novokuznetskCalendar
        let startOfDay = calendar.startOfDay(for: cellState.date)
        let endOfDay = startOfDay.adding(.hour, value: 24)
        
        let maxRangeDate = ranges.compactMap { $0?.endDate }.max() ?? upperDateLimit
        let matchingRange = (startOfDay <= maxRangeDate) && (lowerDateLimit < endOfDay)

        myCustomCell.configure(
            with: cellState,
            isValidDate: matchingRange
        )
    }
    
}

extension FullscreenArchiveIntercomPlayerViewController: JTACMonthViewDataSource, JTACMonthViewDelegate {
    
    func calendar(
        _ calendar: JTACMonthView,
        headerViewForDateRange range: (start: Date, end: Date),
        at indexPath: IndexPath
    ) -> JTACMonthReusableView {
        return calendar.dequeueReusableJTAppleSupplementaryView(
            withReuseIdentifier: "BlackCalendarHeaderView",
            for: indexPath
        // swiftlint:disable:next force_cast
        ) as! BlackCalendarHeaderView
    }

    func calendarSizeForMonths(_ calendar: JTACMonthView?) -> MonthSize? {
        return MonthSize(defaultSize: 40)
    }

    func calendar(
        _ calendar: JTAppleCalendar.JTACMonthView,
        willDisplay cell: JTAppleCalendar.JTACDayCell,
        forItemAt date: Date,
        cellState: JTAppleCalendar.CellState,
        indexPath: IndexPath
    ) {
        configureCell(view: cell, cellState: cellState)
    }
        
    func configureCalendar(_ calendar: JTAppleCalendar.JTACMonthView) -> JTAppleCalendar.ConfigurationParameters {
        let (startDate, endDate): (Date, Date) = {
            let calendar = Calendar.novokuznetskCalendar
            let maxRangeDate = ranges.compactMap { $0?.endDate }.max() ?? upperDateLimit
            let lowerBound = calendar.startOfDay(for: lowerDateLimit)
            let upperBound = calendar.startOfDay(for: maxRangeDate)
            
            return (lowerBound, upperBound)
        }()

        let parameters = ConfigurationParameters(
            startDate: startDate,
            endDate: endDate,
            numberOfRows: 6,
            calendar: Calendar.novokuznetskCalendar,
            generateInDates: .forAllMonths,
            generateOutDates: .off,
//            generateOutDates: .tillEndOfGrid,
            firstDayOfWeek: .monday,
            hasStrictBoundaries: true
        )

        return parameters
    }
    
    func calendar(
        _ calendar: JTAppleCalendar.JTACMonthView,
        cellForItemAt date: Date,
        cellState: JTAppleCalendar.CellState,
        indexPath: IndexPath
    ) -> JTAppleCalendar.JTACDayCell {
        let cell = calendar.dequeueReusableJTAppleCell(
            withReuseIdentifier: "BlackDayCell",
            for: indexPath
        // swiftlint:disable:next force_cast
        ) as! BlackDayCell
        
        configureCell(view: cell, cellState: cellState)

        return cell
    }
    
    func calendar(
        _ calendar: JTACMonthView,
        didSelectDate date: Date,
        cell: JTACDayCell?,
        cellState: CellState,
        indexPath: IndexPath
    ) {
        if calendarBackView.isHidden {
            calendarContainerView.isHidden = true
            return
        }
        let maxRangeDate = ranges.compactMap { $0?.endDate }.max() ?? upperDateLimit
        let calendar = Calendar.novokuznetskCalendar
        if let numberSection = calendar.dateComponents([.day], from: date, to: calendar.startOfDay(for: maxRangeDate)).day,
           numberSection < (archiveCollectionView.numberOfSections - 1),
           numberSection >= 0 {
            scrollToSection(numberSection, date: date)
            calendarBackView.isHidden = true
            calendarContainerView.isHidden = true
        }
    }

    func calendar(_ calendar: JTACMonthView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        setupCalendarHeader(from: visibleDates.monthDates.first?.date)
    }
}

