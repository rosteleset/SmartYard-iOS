//
//  AddressAccessViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class AddressAccessViewController: BaseViewController {

    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var intercomAccessView: IntercomTemporaryAccessView!
    @IBOutlet private weak var barrierAccessView: AccessView!
    @IBOutlet private weak var permanentAccessView: AccessView!
    
    private let viewModel: AddressAccessViewModel
    
    init(viewModel: AddressAccessViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    private func bind() {
        let input = AddressAccessViewModel.Input(
    }

}
