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
import TOInsetGroupedTableView

class HistoryViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var tableView: InsetGroupedTableView!
    @IBOutlet private weak var toolbar: UIToolbar!
    @IBOutlet private weak var topToolbarPositon: NSLayoutConstraint!
    
    
    private var dataSource: RxTableViewSectionedReloadDataSource<HistorySectionModel>?
    
    var loader: JGProgressHUD?
    
    private let viewModel: HistoryViewModel
    
    private let itemSelectedTrigger = PublishSubject<Int>()
    private let itemsProxy = BehaviorSubject<[APIPlog]>(value: [])
    private var availableDays: [APIPlogDays] = []
    
    init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        //tableView.dataSource = self
        tableView.register(nibWithCellClass: HistoryTableViewCell.self)
        tableView.register(nibWithCellClass: HistoryLoadingTableViewCell.self)
        
        dataSource = RxTableViewSectionedReloadDataSource<HistorySectionModel>(
            configureCell: { dataSource, tableView, indexPath, item in
                let cell: HistoryLoadingTableViewCell = tableView.dequeueReusableCell(withClass: HistoryLoadingTableViewCell.self, for: indexPath)
                cell.isLoading = true
                return cell
            },
            titleForHeaderInSection: { dataSource, index in
                return dataSource.sectionModels[index].day.apiString
            }
        )
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        bind()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func bind() {
        let input = HistoryViewModel.Input(
            itemSelected: itemSelectedTrigger.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
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
            .drive(
                onNext: { [weak self] data in
                    guard let self = self else {
                        return
                    }
                    
                    let sections =  data.map { day -> HistorySectionModel in
                        return HistorySectionModel(identity: day.day, itemsCount: day.itemsCount, items: [HistoryDataItem(), HistoryDataItem()])
                    }
                    
                    Observable.just(sections)
                        .bind(to: self.tableView.rx.items(dataSource: self.dataSource!))
                        .disposed(by: self.disposeBag)
                    
                }
            )
            .disposed(by: disposeBag)
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
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
