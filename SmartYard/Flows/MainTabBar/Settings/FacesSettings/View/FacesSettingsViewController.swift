//
//  AdvancedSettingsViewController.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable line_length

import UIKit
import TouchAreaInsets
import RxSwift
import RxCocoa
import JGProgressHUD

class FacesSettingsViewController: BaseViewController, LoaderPresentable {
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var mainContainerView: UIView!
    @IBOutlet private weak var facesCollectionView: UICollectionView!
    
    private let viewModel: FacesSettingsViewModel
    
    var loader: JGProgressHUD?
    
    private var addFaceTrigger = PublishSubject<Void>()
    private var deleteFaceTrigger = PublishSubject<(Int, UIImage?)>()
    private var selectFaceTrigger = PublishSubject<(Int, UIImage?)>()
    
    private var registeredFaces: [APIFace] = []
    
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
        
        fakeNavBar.configureBlueNavBar()
        configureView()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
       }
    
    private func configureView() {
//        mainContainerView.layerCornerRadius = 24
//        mainContainerView.layer.maskedCorners = .topCorners
        
        facesCollectionView.delegate = self
        facesCollectionView.dataSource = self
        
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
                }
            )
            .disposed(by: disposeBag)
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
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

extension FacesSettingsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return registeredFaces.count + 1
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if indexPath.row == 0 {
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
            
            guard 0...registeredFaces.count ~= indexPath.row - 1 else {
                return cell
            }
            let face = registeredFaces[indexPath.row - 1]
            
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
// swiftlint:enable line_length
