//
//  AddressesViewController.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AddressesViewController: BaseViewController {
    
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    
    let viewModel: AddressesViewModel
    
    init(viewModel: AddressesViewModel) {
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
    }
    
    private func configureView() {
        mainContainerView.cornerRadius = 24
        mainContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        addButton.setImage(UIImage(named: "AddButtonIcon"), for: .normal)
        addButton.setImage(UIImage(named: "AddButtonIcon")?.darkened(), for: .highlighted)
    }

}
