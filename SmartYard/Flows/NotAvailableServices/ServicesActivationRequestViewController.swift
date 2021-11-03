//
//  ServicesActivationRequestViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD

class ServicesActivationRequestViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var sendRequestButton: BlueButton!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    private let viewModel: ServicesActivationRequestViewModel
    private let itemsProxy = BehaviorSubject<[ServiceModel]>(value: [])
    
    private let serviceStateChanged = PublishSubject<Int?>()
    
    var loader: JGProgressHUD?
    
    init(viewModel: ServicesActivationRequestViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        fakeNavBar.configureBlueNavBar()
        bind()
    }

    private func bind() {
        let input = ServicesActivationRequestViewModel.Input(
            sendRequestTapped: sendRequestButton.rx.tap.asDriverOnErrorJustComplete(),
            serviceStateChanged: serviceStateChanged.asDriverOnErrorJustComplete(),
            viewWillAppearTrigger: rx.viewWillAppear.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input: input)
        
        output.serviceItems
            .drive(itemsProxy)
            .disposed(by: disposeBag)
        
        output.isSelectedSomeService
            .drive(sendRequestButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.view.endEditing(true)
                    }
                    
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
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
        tableView.register(nibWithCellClass: ServicesActivationRequestСell.self)
        
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

extension ServicesActivationRequestViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        serviceStateChanged.onNext(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }
    
}

extension ServicesActivationRequestViewController: UITableViewDataSource {
    
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
        
        let cell = tableView.dequeueReusableCell(withClass: ServicesActivationRequestСell.self, for: indexPath)
        cell.configure(with: data[indexPath.row])
        
        return cell
    }
    
}
