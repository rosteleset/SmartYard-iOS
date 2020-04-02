//
//  PaymentsViewController.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD

class PaymentsViewController: BaseViewController, LoaderPresentable {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var skeletonContainer: UIView!
    
    private var refreshControl = UIRefreshControl()
    
    private let viewModel: PaymentsViewModel
    
    var loader: JGProgressHUD?
    
    init(viewModel: PaymentsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureTableView()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if skeletonContainer.isSkeletonActive {
            skeletonContainer.showSkeletonAsynchronously()
        }
    }
    
    private func configureTableView() {
        tableView.refreshControl = refreshControl
        refreshControl.tintColor = UIColor.SmartYard.gray
        
        tableView.register(nibWithCellClass: PaymentAddressCell.self)
    }
    
    private func configureView() {
        
    }
    
    private func bind() {
        
    }

}
