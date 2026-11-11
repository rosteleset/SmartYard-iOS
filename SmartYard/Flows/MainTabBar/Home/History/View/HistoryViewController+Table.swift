// Created by Александр Попов. Copyright © 2026 Sesameware.

import UIKit
import JGProgressHUD
import RxSwift
import RxCocoa
import RxDataSources

extension HistoryViewController: UITableViewDelegate {

    func displayDaysInRadius(_ willDisplayDay: Date, _ radius: Int = 0) {
        guard let willDisplayDayIndex = allAvailableDates.firstIndex(of: willDisplayDay)
        else {
            return
        }
        var dayIndex = willDisplayDayIndex - radius

        while dayIndex <= willDisplayDayIndex + radius {
            if dayIndex >= allAvailableDates.startIndex, dayIndex < allAvailableDates.endIndex, dayIndex != willDisplayDayIndex {
                if daysQueue.contains(allAvailableDates[dayIndex]) {
                    daysQueue.removeAll(allAvailableDates[dayIndex])
                    loadDayTriger.onNext(allAvailableDates[dayIndex])
                }
            }
            dayIndex += 1
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
        updateScrollUpButton(for: scrollView)

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

    private func updateScrollUpButton(for scrollView: UIScrollView) {
        // управление скрытием кнопки scrollUp
        if let dataSource = dataSource, !dataSource.sectionModels.isEmpty {
            if scrollView.contentOffset.y > 0 && scrollUpButton.alpha == 0 {
                scrollUpButton.view.fadeIn(duration: 0.5, completion: { _ in self.scrollUpButton.isHidden = false })
            }
            if scrollView.contentOffset.y <= 0 && scrollUpButton.alpha == 1 {
                scrollUpButton.view.fadeOut(duration: 0.5, completion: { _ in self.scrollUpButton.isHidden = true })
            }
        }
    }
}
