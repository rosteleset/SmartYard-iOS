//
//  NotAvailableServicesViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class NotAvailableServicesViewController: BaseViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var sendRequestButton: BlueButton!
    
    private let viewModel: NotAvailableSericesViewModel
    private let itemsProxy = BehaviorSubject<[ServiceModel]>(value: [])
    
    private let serviceStateChanged = PublishSubject<Int?>()
    
    init(viewModel: NotAvailableSericesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        bind()
    }

    private func bind() {
        let input = NotAvailableSericesViewModel.Input(
            sendRequestTapped: sendRequestButton.rx.tap.asDriverOnErrorJustComplete(),
            serviceStateChanged: serviceStateChanged.asDriverOnErrorJustComplete(),
            viewWillAppearTrigger: rx.viewWillAppear.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input: input)
        
        output.serviceItems
            .drive(itemsProxy)
            .disposed(by: disposeBag)
        
        itemsProxy
            .subscribe(
                onNext: { [weak self] _ in
                    self?.tableView.reloadData()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(nibWithCellClass: NotAvailableServiceCell.self)
        
        tableView.tableFooterView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: tableView.frame.size.width,
                height: 1
            )
        )
    }
    
}

extension NotAvailableServicesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        serviceStateChanged.onNext(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }
    
}

extension NotAvailableServicesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let data = try? itemsProxy.value() else {
            return 0
        }
        
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let data = try? itemsProxy.value() else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withClass: NotAvailableServiceCell.self, for: indexPath)
        cell.configure(with: data[indexPath.row])
        
        return cell
    }
    
}
