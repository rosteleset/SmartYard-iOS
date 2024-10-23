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
import JGProgressHUD

final class MainMenuViewController: BaseViewController, LoaderPresentable {
    var loader: JGProgressHUD?
    private let viewModel: MainMenuViewModel
    private let itemsProxy = BehaviorSubject<[MenuListItem]>(value: [])
    private let callSupportTrigger = PublishSubject<Void>()
    private let itemSelected = PublishSubject<IndexPath>()
    
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var skeletonContainer: UIView!
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
            itemSelected: itemSelected.asDriverOnErrorJustComplete(),
            bottomButton: callSupportTrigger.asDriverOnErrorJustComplete()
        )
        
        collectionView.rx.itemSelected.asDriver()
            .drive(
                onNext: { [weak self] indexPath in
                    switch indexPath.section {
                    case 0: self?.itemSelected.onNext(indexPath)
                    case 1: self?.callSupportTrigger.onNext(Void())
                    default: return
                    }
                }
            )
            .disposed(by: disposeBag)
        
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
        
        output.shouldBlockInteraction
            .drive(
                onNext: { [weak self] shouldBlockInteraction in
                    self?.collectionView.isHidden = shouldBlockInteraction
                    self?.skeletonContainer.isHidden = !shouldBlockInteraction
                    
                    shouldBlockInteraction ?
                        self?.skeletonContainer.showSkeletonAsynchronously() :
                        self?.skeletonContainer.hideSkeleton()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureTableView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(cellWithClass: MainMenuItem.self)
        collectionView.register(nibWithCellClass: BottomCell.self)
        
    }
}

extension MainMenuViewController: UICollectionViewDelegateFlowLayout {
    // В первой секции элементы меню
    // Во второй секции всего один элемент – кнопка вызова
    
    // возвращает высоту одного элемента меню
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard indexPath.section == 0 else {
            return CGSize(width: UIScreen.main.bounds.width - 32, height: 60)
        }
        
        guard let item = (try? itemsProxy.value())?[safe: indexPath.row] else {
            return .zero
        }
        
        let height = MainMenuItem.preferredHeight(
            for: UIScreen.main.bounds.width - 32,
            title: item.label
        ).totalHeight
        
        return CGSize(width: UIScreen.main.bounds.width - 32, height: height)
    }
    
    // возвращает расстояние между элементами меню
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 8
    }
    
    // возвращает отступы вокруг секции
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        // высчитываем сколько надо добавить пустого места между последним элементом меню и нижней кнопкой,
        // что бы нижняя кнопка встала ровно на 60 единиц от нижнего края вьюшки.
        let extraSpace = collectionView.height.float - 21 - collectionView.numberOfItems(inSection: 0).float * 80 + 8 - 20 - 16 - 60 - 60
        switch section {
        case collectionView.numberOfSections - 1:
            return UIEdgeInsets(top: 16 + (extraSpace > 0 ? CGFloat(extraSpace) : 0), left: 16, bottom: 60, right: 16)
        default:
            return UIEdgeInsets(top: 21, left: 16, bottom: 20, right: 16)
        }
    }
    
}

extension MainMenuViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let data = try? itemsProxy.value() else {
            return 0
        }
        switch section {
        case 0:
            return data.count
        case 1:
            return 1
        default: return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard (try? itemsProxy.value()) != nil else {
            return 0
        }
        
        return 2
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let data = try? itemsProxy.value() else {
            return UICollectionViewCell()
        }
        
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withClass: MainMenuItem.self, for: indexPath)
            guard let item = data[safe: indexPath.row] else {
                return cell
            }
            if item.icon != nil {
                cell.configure(name: item.label, icon: item.icon)
            } else {
                cell.configure(name: item.label, iconName: item.iconName)
            }
            return cell
        default:
            let bottomCell = collectionView.dequeueReusableCell(withClass: BottomCell.self, for: indexPath)
            
            return bottomCell
        }
    }
    
}
