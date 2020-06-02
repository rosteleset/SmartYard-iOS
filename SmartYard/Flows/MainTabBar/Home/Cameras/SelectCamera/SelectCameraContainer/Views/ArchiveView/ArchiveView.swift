//
//  ArchiveView.swift
//  SmartYard
//
//  Created by Mad Brains on 13.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import PMNibLinkableView
import JTAppleCalendar
import SwifterSwift
import RxSwift
import RxCocoa

protocol ArchiveViewDelegate: AnyObject {
    
    func archiveView(_ archiveView: ArchiveView, didSelectDate date: Date)
    
}

class ArchiveView: PMNibLinkableView {
    
    @IBOutlet private weak var calendarView: JTACMonthView!
    @IBOutlet private weak var monthLabel: UILabel!
    @IBOutlet private weak var leftArrowButton: UIButton!
    @IBOutlet private weak var rightArrowButton: UIButton!
    
    private let formatter = DateFormatter()
    private let currentCalendar = Calendar.current
    
    private let disposeBag = DisposeBag()
    
    weak var delegate: ArchiveViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        configureCalendarView()
        setupCalendar()
        bind()
    }
    
    func parrentViewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let visibleDates = calendarView.visibleDates()
        calendarView.viewWillTransition(to: size, with: coordinator, anchorDate: visibleDates.monthDates.first?.date)
        setupCalendar()
    }
    
    func setupCalendar() {
        setupCalendarHeader(from: calendarView.visibleDates())
    }
    
    fileprivate func configureCell(view: JTACDayCell?, cellState: CellState) {
        guard let myCustomCell = view as? CustomDayCell else {
            return
        }
        
        handleCellTextColor(view: myCustomCell, cellState: cellState)
        handleCellSelection(view: myCustomCell, cellState: cellState)
        handleCellDate(view: view, cellState: cellState)
    }
    
    private func handleCellSelection(view: JTACDayCell?, cellState: CellState) {
        guard let myCustomCell = view as? CustomDayCell else {
            return
        }
        
        myCustomCell.setSelectedViewVisibility(isHidden: !cellState.isSelected)
    }
    
    private func handleCellDate(view: JTACDayCell?, cellState: CellState) {
        guard let myCustomCell = view as? CustomDayCell else {
            return
        }
        
        myCustomCell.configureDate(dayText: cellState.text)
    }
    
    private func handleCellTextColor(view: CustomDayCell, cellState: CellState) {
        let hex = cellState.dateBelongsTo == .thisMonth ? 0x28323E : 0xBEBEBE
        view.configureColor(from: hex)
    }
    
    private func setupCalendarHeader(from visibleDates: DateSegmentInfo) {
        guard let startDate = visibleDates.monthDates.first?.date else {
            return
        }
    
        formatter.dateFormat = "LLLL"
        let nameOfMonth = formatter.string(from: startDate).capitalized
        let year = currentCalendar.component(.year, from: startDate)
        
        monthLabel.text = nameOfMonth + " " + String(year)
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
    }
    
    private func bind() {
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

extension ArchiveView: JTACMonthViewDataSource, JTACMonthViewDelegate {
    
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
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CustomDayCell", for: indexPath) as! CustomDayCell
        configureCell(view: cell, cellState: cellState)
        
        return cell
    }
    
    func configureCalendar(_ calendar: JTACMonthView) -> ConfigurationParameters {
        formatter.dateFormat = "yyyy MM dd"
        formatter.timeZone = currentCalendar.timeZone
        formatter.locale = .init(identifier: "RU")
        
        // TODO: set real data
        let startDate = formatter.date(from: "2020 01 01")!
        let endDate = formatter.date(from: "2020 12 01")!
        
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
        didSelectDate date: Date,
        cell: JTACDayCell?,
        cellState: CellState,
        indexPath: IndexPath
    ) {
        guard cellState.dateBelongsTo == .thisMonth else {
            return
        }
        
        configureCell(view: cell, cellState: cellState)
        
        delegate?.archiveView(self, didSelectDate: date)
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
