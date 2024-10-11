//
//  PayTypeSelectViewController.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 17.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

@objc protocol PayTypeViewCellProtocol {
    func didTapDeleteCard(for cell: PayTypeViewCell)
}

class PayTypeSelectViewController: BaseViewController {
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var animatedView: UIView!
    @IBOutlet private weak var selectTypeButton: BlueButton!
    @IBOutlet private weak var typesCollectionView: UICollectionView!
    
    @IBOutlet private var animatedViewHeightConstraint: NSLayoutConstraint!

    private var cards: [PayTypeObject] = []
    
    private let selectedNumberTrigger = BehaviorSubject<Int?>(value: nil)
    private let cardDeleteTrigger = PublishSubject<PayTypeObject?>()
    private var selectedNumber: Int?

    private var swipeDismissInteractor: SwipeInteractionController?
    private let viewModel: PayTypeSelectViewModel
    private let viewHeight: CGFloat

    init(viewModel: PayTypeSelectViewModel, height: CGFloat) {
        self.viewModel = viewModel
        self.viewHeight = height
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureCollectionView()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        animatedView.roundCorners([.topLeft, .topRight], radius: 12.0)
    }
    
    private func configureView() {
        animatedViewHeightConstraint.constant = viewHeight
        configureSwipeAction()
        view.backgroundColor = .clear
    }

    private func configureCollectionView() {
        typesCollectionView.delegate = self
        typesCollectionView.dataSource = self
        
        typesCollectionView.register(nibWithCellClass: PayTypeViewCell.self)
    }
    
    private func bind() {
        let input = PayTypeSelectViewModel.Input(
            selectedNumberTrigger: selectedNumberTrigger.asDriver(onErrorJustReturn: nil),
            deleteCardTrigger: cardDeleteTrigger.asDriver(onErrorJustReturn: nil),
            saveButtonTrigger: selectTypeButton.rx.tap.asDriverOnErrorJustComplete()
        )

        let output = viewModel.transform(input: input)

        output.cards
            .drive(
                onNext: { [weak self] cards in
                    self?.updateCards(cards)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureSwipeAction() {
        swipeDismissInteractor = SwipeInteractionController(
            viewController: self,
            animatedView: animatedView
        )
        
        swipeDismissInteractor?.velocityThreshold = 1500
        
        transitioningDelegate = self
    }
    
    private func updateCards(_ payTypes: [PayTypeObject]) {
        cards = payTypes
        cards.map { if $0.isSelected { selectedNumberTrigger.onNext($0.number) }}
        typesCollectionView.reloadData()
    }
}

extension PayTypeSelectViewController: UICollectionViewDelegate {
    
}

extension PayTypeSelectViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: PayTypeViewCell.self, for: indexPath)
        guard !cards.isEmpty else {
            return cell
        }
        cell.configureCell(payType: cards[indexPath.row], isDeletable: cards[indexPath.row].paymentWay == .CARD)
        if cards[indexPath.row].paymentWay == .CARD {
            cell.delegate = self
        }
        return cell
    }
}

extension PayTypeSelectViewController: PayTypeViewCellProtocol {
    func didTapDeleteCard(for cell: PayTypeViewCell) {
        cardDeleteTrigger.onNext(cell.payType)
    }
}

extension PayTypeSelectViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.layer.bounds.width, height: 54)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 6
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard indexPath.row != selectedNumber else {
            return
        }
        selectedNumber = indexPath.row
        selectedNumberTrigger.onNext(indexPath.row)
        cards = cards.map { element in
            var newelement = element
            newelement.isSelected = element.number == selectedNumber
            return newelement
        }
        collectionView.reloadData()
    }
    
}

extension PayTypeSelectViewController: PickerAnimatable {
    
    var animatedBackgroundView: UIView { return backgroundView }
    
    var animatedMovingView: UIView { return animatedView }
    
}

extension PayTypeSelectViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
        return PickerPresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PickerDismissAnimator()
    }
    
    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
        ) -> UIViewControllerInteractiveTransitioning? {
        guard let interactionInProgress = swipeDismissInteractor?.interactionInProgress else {
            return nil
        }
        return interactionInProgress ? swipeDismissInteractor : nil
    }
}
