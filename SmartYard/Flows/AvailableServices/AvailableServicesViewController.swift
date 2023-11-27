//
//  AvailableServicesViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import JGProgressHUD

class AvailableServicesViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var nextButton: BlueButton!
    @IBOutlet private weak var addressLabel: UILabel!
    
    var loader: JGProgressHUD?
    
    private let viewModel: AvailableServicesViewModel
    private let itemsProxy = BehaviorSubject<[ServiceModel]>(value: [])
    
    private let serviceStateChanged = PublishSubject<Int?>()
    
    init(viewModel: AvailableServicesViewModel) {
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
        let input = AvailableServicesViewModel.Input(
            nextTapped: nextButton.rx.tap.asDriverOnErrorJustComplete(),
            serviceStateChanged: serviceStateChanged.asDriverOnErrorJustComplete(),
            viewWillAppearTrigger: rx.viewWillAppear.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input: input)
        
        output.serviceItems
            .drive(itemsProxy)
            .disposed(by: disposeBag)
        
        output.addressSubject
            .drive(
                onNext: { [weak self] address in
                    self?.addressLabel.text = address
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: NSLocalizedString("Creating a task", comment: ""))
                }
            )
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
        tableView.register(nibWithCellClass: AvailableServiceCell.self)
        
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

extension AvailableServicesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        serviceStateChanged.onNext(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

extension AvailableServicesViewController: UITableViewDataSource {
    
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
        
        let cell = tableView.dequeueReusableCell(withClass: AvailableServiceCell.self, for: indexPath)
        cell.configure(with: data[indexPath.row])
        
        return cell
    }
    
}
