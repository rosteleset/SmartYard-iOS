//
//  HomePayViewController+Calendar.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 19.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JTAppleCalendar

extension HomePayViewController {
    func configureCalendar() {
        calendarView.register(nibWithCellClass: DetailsCalendarDayCell.self)
        
        let headerNib = UINib(nibName: "DetailsCalendarHeaderView", bundle: Bundle.main)
        calendarView.register(
            headerNib,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "DetailsCalendarHeaderView"
        )
        
        calendarView.calendarDelegate = self
        calendarView.calendarDataSource = self
        
        calendarView.scrollingMode = .stopAtEachCalendarFrame
        calendarView.minimumLineSpacing = 0
        calendarView.minimumInteritemSpacing = 0
        calendarView.allowsMultipleSelection = true
        calendarView.allowsRangedSelection = true
        calendarView.rangeSelectionMode = .continuous
        calendarContainerView.layer.masksToBounds = false
        calendarContainerView.layer.shadowColor = UIColor.black.cgColor
        calendarContainerView.layer.shadowOpacity = 0.4
        calendarContainerView.layer.shadowOffset = CGSize.zero
        calendarContainerView.layer.shadowRadius = 10
        
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
        
        let tapCalendarBack = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapCalendarBack)
        )
        calendarBackView.addGestureRecognizer(tapCalendarBack)
    }
    
    @objc private dynamic func handleTapCalendarBack(_ recognizer: UITapGestureRecognizer) {
        self.calendarBackView.isHidden = true
        self.calendarContainerView.isHidden = true
    }
    
    func showCalendar(contract: ContractFaceObject, from: Date, to: Date) {
        calendarBackView.isHidden = false
        calendarContainerView.isHidden = false
        calendarDetailsTrigger.onNext(nil)
        calendarRangeSelect = DetailRange(contract: contract, fromDay: nil, toDay: nil)
        updatePeriodHeader(from: from, to: to)
        updateCalendarHeader(from: to)
        calendarView.selectDates(from: from, to: to, triggerSelectionDelegate: false, keepSelectionIfMultiSelectionAllowed: true)
        calendarView.scrollToDate(to, animateScroll: false)
        calendarView.reloadData()
    }
    
    func updateCalendarHeader(from visibleDate: Date?) {
        guard let visibleDate = visibleDate else {
            return
        }
        
        let formatter = DateFormatter()

        formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
        formatter.locale = Calendar.novokuznetskCalendar.locale
        
        formatter.dateFormat = "LLLL"
        let nameOfMonth = formatter.string(from: visibleDate)
        calendarMonthLabel.text = nameOfMonth.prefix(1).capitalized + nameOfMonth.dropFirst()
        
        formatter.dateFormat = "yyyy"
        let nameOfYear = formatter.string(from: visibleDate)
        calendarYearLabel.text = nameOfYear
        
        // MARK: Показ и скрытие стрелочек
        
        let startDateMonth = calendarRange.startDate.month
        let endDateMonth = calendarRange.to.month
        let visibleDateMonth = visibleDate.month
        let startDateYear = calendarRange.startDate.year
        let endDateYear = calendarRange.to.year
        
        if endDateYear == startDateYear {
            calendarLeftArrowButton.isHidden = visibleDateMonth <= startDateMonth
            calendarRightArrowButton.isHidden = visibleDateMonth >= endDateMonth
            return
        }
        let visibleDateYear = visibleDate.year
        calendarRightArrowButton.isHidden = (visibleDateYear == endDateYear) && (visibleDateMonth >= endDateMonth)
        calendarLeftArrowButton.isHidden = (visibleDateYear == startDateYear) && (visibleDateMonth <= startDateMonth)
    }
    
    private func updatePeriodHeader(from: Date?, to: Date?) {
        let formatter = DateFormatter()

        formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
        formatter.locale = Calendar.novokuznetskCalendar.locale
        
        formatter.dateFormat = "dd.MM.yyyy"
        if let from = from {
            if let to = to {
                calendarRangeLabel.text = formatter.string(from: from) + " - " + formatter.string(from: to)
            } else {
                calendarRangeLabel.text = formatter.string(from: from) + " - ..."
            }
        } else {
            if let to = to {
                calendarRangeLabel.text = "... - " + formatter.string(from: to)
            } else {
                calendarRangeLabel.text = "... - ..."
            }
        }
    }
    
    private func configureCell(view: JTACDayCell?, cellState: CellState) {
        guard let myCustomCell = view as? DetailsCalendarDayCell else {
            return
        }

        myCustomCell.configure(
            with: cellState,
            isValidDate: calendarRange.intersects(start: cellState.date, end: cellState.date)
        )
    }
}

extension HomePayViewController: JTACMonthViewDelegate, JTACMonthViewDataSource {
    func calendar(
        _ calendar: JTACMonthView,
        headerViewForDateRange range: (start: Date, end: Date),
        at indexPath: IndexPath
    ) -> JTACMonthReusableView {
        return calendar.dequeueReusableJTAppleSupplementaryView(
            withReuseIdentifier: "DetailsCalendarHeaderView",
            for: indexPath
        // swiftlint:disable:next force_cast
        ) as! DetailsCalendarHeaderView
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
        let parameters = ConfigurationParameters(
            startDate: calendarRange.startDate,
            endDate: calendarRange.to,
            numberOfRows: 6,
            calendar: Calendar.novokuznetskCalendar,
            generateInDates: .forAllMonths,
            generateOutDates: .tillEndOfRow,
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
            withReuseIdentifier: "DetailsCalendarDayCell",
            for: indexPath
        // swiftlint:disable:next force_cast
        ) as! DetailsCalendarDayCell
        
        configureCell(view: cell, cellState: cellState)

        return cell
    }
    
    func calendar(_ calendar: JTACMonthView, shouldSelectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) -> Bool {
        guard calendarRange.intersects(start: cellState.date, end: cellState.date), let calendarRangeSelect = calendarRangeSelect else {
            return false
        }
        let rangeSelected = calendar.selectedDates

        if !rangeSelected.contains(date), cellState.selectionType == .userInitiated {
            if let fromday = calendarRangeSelect.fromDay {
                if fromday < date {
                    self.calendarRangeSelect?.toDay = date
                    if let lastdate = rangeSelected.last, fromday == lastdate {
                        let to = Calendar.novokuznetskCalendar.date(byAdding: .day, value: -1, to: lastdate)!
                        calendar.deselectDates(from: rangeSelected.first!, to: to, triggerSelectionDelegate: false, keepDeselectionIfMultiSelectionAllowed: true)
                    }
                    let from = Calendar.novokuznetskCalendar.date(byAdding: .day, value: 1, to: rangeSelected.last!)!
                    calendar.selectDates(from: from, to: date, triggerSelectionDelegate: false, keepSelectionIfMultiSelectionAllowed: true)
                    updatePeriodHeader(from: fromday, to: date)
                } else {
                    self.calendarRangeSelect?.toDay = fromday
                    self.calendarRangeSelect?.fromDay = date
                    if let firstdate = rangeSelected.first, fromday == firstdate {
                        let from = Calendar.novokuznetskCalendar.date(byAdding: .day, value: 1, to: firstdate)!
                        calendar.deselectDates(from: from, to: rangeSelected.last!, triggerSelectionDelegate: false, keepDeselectionIfMultiSelectionAllowed: true)
                    }
                    let to = Calendar.novokuznetskCalendar.date(byAdding: .day, value: -1, to: rangeSelected.first!)!
                    calendar.selectDates(from: date, to: to, triggerSelectionDelegate: false, keepSelectionIfMultiSelectionAllowed: true)
                }
                calendarBackView.isHidden = true
                calendarContainerView.isHidden = true
                calendarDetailsTrigger.onNext(self.calendarRangeSelect)
            } else {
                if let firstdate = rangeSelected.first, date < firstdate {
                    self.calendarRangeSelect?.fromDay = date
                    let to = Calendar.novokuznetskCalendar.date(byAdding: .day, value: -1, to: firstdate)!
                    calendar.selectDates(from: date, to: to, triggerSelectionDelegate: false, keepSelectionIfMultiSelectionAllowed: true)
                    updatePeriodHeader(from: date, to: nil)
                    return false
                }
                if let lastdate = rangeSelected.last, date > lastdate {
                    self.calendarRangeSelect?.fromDay = date
                    let from = Calendar.novokuznetskCalendar.date(byAdding: .day, value: 1, to: lastdate)!
                    calendar.selectDates(from: from, to: date, triggerSelectionDelegate: false, keepSelectionIfMultiSelectionAllowed: true)
                    updatePeriodHeader(from: nil, to: date)
                }
            }
            return false
        }
        return true
    }
    
    func calendar(_ calendar: JTACMonthView, shouldDeselectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) -> Bool {
        guard calendarRange.intersects(start: cellState.date, end: cellState.date), let calendarRangeSelect = calendarRangeSelect else {
            return false
        }
        let rangeSelected = calendar.selectedDates
        if rangeSelected.contains(date), cellState.selectionType == .userInitiated {
            if let fromday = calendarRangeSelect.fromDay {
                if fromday <= date {
                    self.calendarRangeSelect?.toDay = date
                    if let lastdate = rangeSelected.last, date < lastdate {
                        let index = rangeSelected.firstIndex(of: date)
                        let from = rangeSelected[index! + 1]
                        calendar.deselectDates(from: from, to: lastdate, triggerSelectionDelegate: false, keepDeselectionIfMultiSelectionAllowed: true)
                    }
                    updatePeriodHeader(from: fromday, to: date)
                } else {
                    self.calendarRangeSelect?.toDay = fromday
                    self.calendarRangeSelect?.fromDay = date
                    if let firstdate = rangeSelected.first, date > firstdate {
                        let index = rangeSelected.firstIndex(of: date)
                        let to = rangeSelected[index! - 1]
                        calendar.deselectDates(from: firstdate, to: to, triggerSelectionDelegate: false, keepDeselectionIfMultiSelectionAllowed: true)
                    }
                    updatePeriodHeader(from: date, to: fromday)
                }
                calendarBackView.isHidden = true
                calendarContainerView.isHidden = true
                calendarDetailsTrigger.onNext(self.calendarRangeSelect)
            } else {
                self.calendarRangeSelect?.fromDay = date
                if let firstdate = rangeSelected.first, date > firstdate {
                    let index = rangeSelected.firstIndex(of: date)
                    let to = rangeSelected[index! - 1]
                    calendar.deselectDates(from: firstdate, to: to, triggerSelectionDelegate: false, keepDeselectionIfMultiSelectionAllowed: true)
                }
                updatePeriodHeader(from: date, to: nil)
            }
            return false
        }
        return true
    }

    func calendar(_ calendar: JTACMonthView, didSelectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) {
        guard calendarRange.intersects(start: cellState.date, end: cellState.date), let calendarRangeSelect = calendarRangeSelect else {
            return
        }
    }
    
    func calendar(_ calendar: JTACMonthView, didDeselectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) {
        guard calendarRange.intersects(start: cellState.date, end: cellState.date), let calendarRangeSelect = calendarRangeSelect else {
            return
        }
    }
    
    func calendar(_ calendar: JTACMonthView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        updateCalendarHeader(from: visibleDates.monthDates.first?.date)
    }
}
