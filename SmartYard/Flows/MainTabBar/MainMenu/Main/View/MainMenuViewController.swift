//
//  MainMenuViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 06.01.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MainMenuViewController: BaseViewController {
    
    private let viewModel: MainMenuViewModel
    private let itemsProxy = BehaviorSubject<[MenuItemsList]>(value: [])
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    init(viewModel: MainMenuViewModel) {
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
        bind()
    }
    
    private func bind() {
        
        let input = MainMenuViewModel.Input(
            itemSelected: collectionView.rx.itemSelected.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.items
            .drive(itemsProxy)
            .disposed(by: disposeBag)
        
        itemsProxy
            .subscribe(
                onNext: { [weak self] _ in
                    self?.collectionView.reloadData()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureTableView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(cellWithClass: MainMenuItem.self)
        
    }
}

extension MainMenuViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let item = (try? itemsProxy.value())?[safe: indexPath.row] else {
            return .zero
        }
        
        let height = MainMenuItem.preferredHeight(
            for: UIScreen.main.bounds.width - 32,
            title: item.label
        ).totalHeight
        
        return CGSize(width: UIScreen.main.bounds.width - 32, height: height)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 10
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 16, bottom: 20, right: 16)
    }
    
}

extension MainMenuViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let data = try? itemsProxy.value() else {
            return 0
        }
        
        return data.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let data = try? itemsProxy.value() else {
            return UICollectionViewCell()
        }
        let cell = collectionView.dequeueReusableCell(withClass: MainMenuItem.self, for: indexPath)
        cell.configure(address: data[safe: indexPath.row]?.label, iconName: data[safe: indexPath.row]?.iconName)
        
        return cell
    }
    
}
