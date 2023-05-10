//
//  ChatwootSelectChatController.swift
//  SmartYard
//
//  Created by devcentra on 23.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD

class ChatwootSelectChatController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var skeletonContainer: UIView!
    
    private var refreshControl = UIRefreshControl()

    private let viewModel: ChatwootSelectChatModel

    private let itemsProxy = BehaviorSubject<[APIChat]>(value: [])

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var loader: JGProgressHUD?

    init(viewModel: ChatwootSelectChatModel) {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if skeletonContainer.sk.isSkeletonActive {
            skeletonContainer.showSkeletonAsynchronously()
        }
    }

    private func bind() {
        
        let input = ChatwootSelectChatModel.Input(
            itemSelected: collectionView.rx.itemSelected.asDriver(),
            refreshDataTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.itemModels
            .drive(itemsProxy)
            .disposed(by: disposeBag)
        
        output.reloadingFinished
            .drive(
                onNext: { [weak self] in
                    self?.refreshControl.endRefreshing()
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
                    
                    if shouldBlockInteraction {
                        self?.skeletonContainer.showSkeletonAsynchronously()
                    } else {
                        self?.skeletonContainer.hideSkeleton()
                    }
                }
            )
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
        mainContainerView.layerCornerRadius = 24
        mainContainerView.layer.maskedCorners = .topCorners
        
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(cellWithClass: ChatCell.self)
        
        collectionView.refreshControl = refreshControl
    }
    
}

extension ChatwootSelectChatController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let chat = (try? itemsProxy.value())?[safe: indexPath.row] else {
            return .zero
        }
        
        let height = ChatCell.preferredHeight(
            for: UIScreen.main.bounds.width - 32,
            title: chat.name
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
        return UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)
    }
    
}

extension ChatwootSelectChatController: UICollectionViewDataSource {
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
        
        let cell = collectionView.dequeueReusableCell(withClass: ChatCell.self, for: indexPath)
        cell.configure(chat: data[safe: indexPath.row]?.name)
        
        return cell
    }
    
}
