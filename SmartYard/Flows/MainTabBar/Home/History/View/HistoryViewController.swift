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

class HistoryViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var toolbar: UIToolbar!
    @IBOutlet private weak var topToolbarPositon: NSLayoutConstraint!
    
    private var dataSource: RxTableViewSectionedReloadDataSource<HistorySectionModel>?
    
    var loader: JGProgressHUD?
    
    private let viewModel: HistoryViewModel
    
    private let itemSelectedTrigger = PublishSubject<Int>()
    private let itemsProxy = BehaviorSubject<[APIPlog]>(value: [])
    private var availableDays: [APIPlogDay] = []
    
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
    
    fileprivate func configureCell(_ indexPath: IndexPath, _ cell: HistoryTableViewCell, _ dataSource: TableViewSectionedDataSource<HistorySectionModel>) {
        //cell.isLoading = true
        
        
        /*let cell = tableView.dequeueReusableCell(withIdentifier: "CELL")!
         
         cell.textLabel?.text = String(dataSource.sectionModels[indexPath.section].items[indexPath.row].identity)
         */
        switch indexPath.row {
        case 0:
            cell.configureCell(cellOrder: .first, from: dataSource.sectionModels[indexPath.section].items[indexPath.row].value)
        case dataSource.sectionModels[indexPath.section].items.count - 1 :
            cell.configureCell(cellOrder: .last, from: dataSource.sectionModels[indexPath.section].items[indexPath.row].value)
        default:
            cell.configureCell(cellOrder: .regular ,from: dataSource.sectionModels[indexPath.section].items[indexPath.row].value)
        }
    }
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        //tableView.dataSource = self
        tableView.register(nibWithCellClass: HistoryTableViewCell.self)
        tableView.register(nibWithCellClass: HistoryLoadingTableViewCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CELL")
        
        //tableView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        dataSource = RxTableViewSectionedReloadDataSource<HistorySectionModel>(
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
