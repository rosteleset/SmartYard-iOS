//
//  AdvancedSettingsViewController.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import TouchAreaInsets
import RxSwift
import RxCocoa
import JGProgressHUD

final class FacesSettingsViewController: BaseViewController, LoaderPresentable {
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var facesCollectionView: UICollectionView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var registeredFacesLabel: UILabel!
    @IBOutlet private weak var registrationHintLabel: UILabel!
    private let viewModel: FacesSettingsViewModel
    
    var loader: JGProgressHUD?
    
    private var addFaceTrigger = PublishSubject<Void>()
    private var deleteFaceTrigger = PublishSubject<(Int, UIImage?)>()
    private var selectFaceTrigger = PublishSubject<(Int, UIImage?)>()
    
    private var registeredFaces: [APIFace] = []
    private var canAddFace = false
    private lazy var emptyStateView = makeEmptyStateView()
    private var emptyStateLabelLeadingConstraint: NSLayoutConstraint?
    
    init(viewModel: FacesSettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
       }
    
    private func configureUI() {
        titleLabel.text = L10n.Settings.Faces.faceRegistration
        registeredFacesLabel.text = L10n.Settings.Faces.registeredFaces
        registrationHintLabel.text = L10n.Settings.Faces.registrationHint
        mainContainerView.layerCornerRadius = 24
        mainContainerView.layer.maskedCorners = .topCorners
        
        scrollView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
        
        facesCollectionView.delegate = self
        facesCollectionView.dataSource = self
        facesCollectionView.backgroundView = emptyStateView
        
        if let flowLayout = facesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .horizontal
        }
        
        facesCollectionView.register(nibWithCellClass: AddFaceCell.self)
        facesCollectionView.register(nibWithCellClass: FaceCell.self)
        
    }
    
    private func bind() {
        let input = FacesSettingsViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            addFaceTrigger: addFaceTrigger.asDriverOnErrorJustComplete(),
            deleteFaceTrigger: deleteFaceTrigger.asDriverOnErrorJustComplete(),
            selectFaceTrigger: selectFaceTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
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
        
        output.shouldShowInitialLoading
            .drive(
                onNext: { [weak self] shouldShowInitialLoading in
                    shouldShowInitialLoading ? self?.showInitialLoading() : self?.finishInitialLoading()
                }
            )
            .disposed(by: disposeBag)
        
        output.registeredFaces
            .drive(
                onNext: { [weak self] faces in
                    self?.registeredFaces = faces
                    self?.facesCollectionView.reloadData()
                    self?.updateEmptyState()
                }
            )
            .disposed(by: disposeBag)

        output.canAddFace
            .distinctUntilChanged()
            .drive(with: self) { owner, canAddFace in
                owner.canAddFace = canAddFace
                owner.registrationHintLabel.text = canAddFace ? L10n.Settings.Faces.registrationHint : nil
                owner.registrationHintLabel.isHidden = !canAddFace
                owner.emptyStateLabelLeadingConstraint?.constant = canAddFace ? 88 : 32
                owner.facesCollectionView.reloadData()
            }
            .disposed(by: disposeBag)
    }

    private func makeEmptyStateView() -> UIView {
        let containerView = UIView(frame: facesCollectionView.bounds)
        containerView.backgroundColor = .clear
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.isHidden = true

        let titleLabel = UILabel.make(
            .bodySemibold,
            text: L10n.Settings.Faces.emptyStateMessage
        )
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .SmartYard.gray
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        containerView.addSubview(titleLabel)

        let leadingConstraint = titleLabel.leadingAnchor.constraint(
            equalTo: containerView.leadingAnchor,
            constant: 32
        )
        emptyStateLabelLeadingConstraint = leadingConstraint

        NSLayoutConstraint.activate([
            leadingConstraint,
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        return containerView
    }

    private func updateEmptyState() {
        emptyStateView.isHidden = !registeredFaces.isEmpty
    }
    
    private func showInitialLoading() {
        // TODO: сделать отображение скелетонов
    }
    
    private func finishInitialLoading() {
        // MARK: Если показать сразу, то пользователь увидит, как меняется положение тумблеров
        // Т.к. мы подгружаем стейт с сервера. Поэтому решил это закрыть за скелетоном
        
//         DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
//        }
    }
    
}

extension FacesSettingsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 52, height: 92)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 12
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
    }
}

extension FacesSettingsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return registeredFaces.count + (canAddFace ? 1 : 0)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if canAddFace && indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withClass: AddFaceCell.self, for: indexPath)
            cell.configure(
                onTapHandler: { [weak self] in
                    self?.addFaceTrigger.onNext(())
                }
            )
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: FaceCell.self, for: indexPath)
            cell.reset()

            let faceIndex = indexPath.row - (canAddFace ? 1 : 0)
            guard registeredFaces.indices.contains(faceIndex) else {
                return cell
            }
            let face = registeredFaces[faceIndex]
            
            cell.configure(
                faceId: face.faceId,
                faceImageURL: face.image,
                onTapHandler: { [weak self] faceId in
                        self?.selectFaceTrigger.onNext((faceId, cell.getImage()))
                },
                onDeleteHandler: { [weak self] faceId in
                    self?.deleteFaceTrigger.onNext((faceId, cell.getImage()))
                }
            )
            
            return cell
        }
    }
}

extension FacesSettingsViewController {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        scrollView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }
    
}
