//
//  MyYardViewController.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 05.04.2024.
//  Copyright © 2024 Layka. All rights reserved.
//
// swiftlint:disable function_body_length type_body_length

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import JGProgressHUD
import SkeletonView
import DropDown

@objc protocol MyYardCellProtocol {
    func didTapPreviewImage(for cell: CamerasViewCell)
}

@objc protocol MyYardIntercomsCellProtocol {
    func didTapEvents(for cell: IntercomsViewCell)
    func didTapCodeRefresh(for cell: IntercomsViewCell)
    func didTapFaceID(for cell: IntercomsViewCell)
    func didTapShare(for cell: IntercomsViewCell)
    func didTapFullScreen(for cell: IntercomsViewCell)
    func didTapOpenDoor(for cell: IntercomsViewCell)
}

class MyYardViewController: BaseViewController, LoaderPresentable, UIGestureRecognizerDelegate {
 
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var camerasView: UIView!
    @IBOutlet private weak var camerasCollectionView: UICollectionView!
    @IBOutlet private weak var camerasMenuButton: UIButton!
    @IBOutlet private weak var intercomsCollectionView: UICollectionView!
    @IBOutlet private weak var notIntercomView: UIView!
    @IBOutlet private weak var notIntercomText: UITextView!
    @IBOutlet private weak var notIntercomAddButton: BlueButton!
    @IBOutlet private weak var skeletonContainer: UIView!

    @IBOutlet private var intercomsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var viewHeightConstraint: NSLayoutConstraint!
    
    @IBAction private func showCamerasMenu() {
        camerasMenu.show()
    }
    @IBAction private func addAddressTap() {
        addAddressTrigger.onNext(())
    }
    
    @IBOutlet private var camerasCollectionViewHeightConstraint: NSLayoutConstraint!

    private let camerasMenu = DropDown()
    
    private var cameras = [CameraExtendedObject]()
    private var intercoms = [IntercomCamerasObject]()
    private var refreshControl = UIRefreshControl()
    private let viewModel: MyYardViewModel
    private let accessService: AccessService

    let selectCameraTrigger = PublishSubject<CameraExtendedObject>()
    let selectCamerasTrigger = PublishSubject<Void>()
    
    let shareOpendoorTrigget = PublishSubject<IntercomCamerasObject>()
    let eventsTrigger = PublishSubject<IntercomCamerasObject>()
    let faceidTrigger = PublishSubject<IntercomCamerasObject>()
    let fullscreenTrigger = PublishSubject<CameraInversObject>()
    let doorCodeRefreshTrigger = PublishSubject<IntercomCamerasObject>()
    let openDoorTrigger = PublishSubject<IntercomCamerasObject>()
    let addAddressTrigger = PublishSubject<Void>()
    let chatSelectTrigger = PublishSubject<String>()
    let callPhoneTrigger = PublishSubject<String>()

    var loader: JGProgressHUD?
    
    init(viewModel: MyYardViewModel, accessService: AccessService) {
        self.viewModel = viewModel
        self.accessService = accessService
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
        configureIntercomCollectionView()
        bind()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        for row in 0..<intercoms.count {
            if let cell = intercomsCollectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? AddressIntercomsViewCell {
                cell.stopAllPlayers()
            }
        }
    }
    
    private func configureView() {
        scrollView.refreshControl = refreshControl

        camerasMenuButton.setBackgroundColor(color: UIColor.SmartYard.blue.withAlphaComponent(0.5), forState: .highlighted)
        
        camerasMenu.anchorView = camerasMenuButton
        camerasMenu.direction = .bottom
        camerasMenu.bottomOffset = CGPoint(x: 0, y: (camerasMenu.anchorView?.plainView.bounds.height)!)
        camerasMenu.backgroundColor = UIColor.white
        camerasMenu.separatorColor = UIColor.darkGray
        camerasMenu.dismissMode = .onTap
        camerasMenu.cellHeight = 44
        camerasMenu.cornerRadius = 8
        
        camerasMenu.dataSource = ["Все камеры в архиве"]
        camerasMenu.cellNib = UINib(nibName: "CamerasMenuCell", bundle: nil)
        camerasMenu.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) -> Void in
            guard let cell = cell as? CamerasMenuCell else {
                return
            }
            cell.separatorInset = .zero
            cell.layoutMargins = .zero
        }
        camerasMenu.selectionAction = { [weak self] (index: Int, item: String) in
            if index == .zero {
                self?.selectCamerasTrigger.onNext(())
            }
            self?.camerasMenu.deselectRow(at: index)
        }
        
        let text = "Для доступа к функционалу домофонии необходимо авторизоваться по номеру договора. " +
                   "Его вы можете уточнить в документах, полученных при подключении, " +
                   "по телефону контакт-центра +7(3843)756-000 или в чате этого приложения :)"
        let linkPhone = "+7(3843)756-000"
        let linkChat = "чате"
        let linkPhoneRange = (text as NSString).range(of: linkPhone)
        let linkChatRange = (text as NSString).range(of: linkChat)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.SmartYard.textAddon,
            .font: UIFont.SourceSansPro.regular(size: 16),
            .paragraphStyle: {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                paragraph.lineSpacing = 4
                return paragraph
            }()
        ]
        let linkPhoneAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.SmartYard.blue,
            .phoneAction: "tel://73843756000"
        ]
        let linkChatAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.SmartYard.blue,
            .chatAction: "p"
        ]
        
        let attributedString = NSMutableAttributedString(string: text, attributes: attributes)
        attributedString.addAttributes(linkPhoneAttributes, range: linkPhoneRange)
        attributedString.addAttributes(linkChatAttributes, range: linkChatRange)
        notIntercomText.attributedText = attributedString
        notIntercomText.translatesAutoresizingMaskIntoConstraints = false
        notIntercomText.isUserInteractionEnabled = true
        
        let textTap = UITapGestureRecognizer(target: self, action: #selector(textHandleTap))
        textTap.delegate = self
        notIntercomText.addGestureRecognizer(textTap)
        notIntercomView.isHidden = true
    }
    
    @objc func textHandleTap(_ sender: UITapGestureRecognizer) {
        guard let textView = sender.view as? UITextView else {
            return
        }
        let layoutManager = textView.layoutManager
        
        var location = sender.location(in: textView)
        location.x -= textView.textContainerInset.left
        location.y -= textView.textContainerInset.top
        
        let characterIndex = layoutManager.characterIndex(for: location, in: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if characterIndex < textView.textStorage.length {
            let range = NSRange(location: characterIndex, length: 1)
            let substring = (textView.attributedText.string as NSString).substring(with: range)
            
            let attributePhone = NSAttributedString.Key.phoneAction
            let attributeChat = NSAttributedString.Key.chatAction
            
            let valuePhone = textView.attributedText?.attribute(attributePhone, at: characterIndex, effectiveRange: nil)
            let valueChat = textView.attributedText?.attribute(attributeChat, at: characterIndex, effectiveRange: nil)
            
            if let value = valuePhone as? String {
                callPhoneTrigger.onNext(value)
            }
            if let value = valueChat as? String {
                chatSelectTrigger.onNext(value)
            }
        }
    }
    
    private func configureCollectionView() {
        camerasCollectionView.delegate = self
        camerasCollectionView.dataSource = self
        
        camerasCollectionView.register(nibWithCellClass: CamerasViewCell.self)
    }
    
    private func configureIntercomCollectionView() {
        intercomsCollectionView.delegate = self
        intercomsCollectionView.dataSource = self
        
        intercomsCollectionView.register(nibWithCellClass: AddressIntercomsViewCell.self)
        intercomsCollectionView.rx
            .observeWeakly(CGSize.self, "contentSize")
            .subscribe(
                onNext: { [weak self] size in
                    guard let self = self, let uSize = size else {
                        return
                    }
                    self.intercomsViewHeightConstraint.constant = uSize.height
                    self.view.setNeedsLayout()
                }
            )
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if skeletonContainer.sk.isSkeletonActive {
            skeletonContainer.showSkeletonAsynchronously()
        }
    }
    
    private func bind() {
        let input = MyYardViewModel.Input(
            selectCameraTrigger: selectCameraTrigger.asDriverOnErrorJustComplete(),
            refreshDataTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver(),
            camerasHintTrigger: selectCamerasTrigger.asDriverOnErrorJustComplete(),
            addAddressTrigger: addAddressTrigger.asDriverOnErrorJustComplete(),
            shareOpendoorTrigget: shareOpendoorTrigget.asDriverOnErrorJustComplete(),
            eventsTrigger: eventsTrigger.asDriverOnErrorJustComplete(),
            faceidTrigger: faceidTrigger.asDriverOnErrorJustComplete(),
            fullscreenTrigger: fullscreenTrigger.asDriverOnErrorJustComplete(),
            doorCodeRefreshTrigger: doorCodeRefreshTrigger.asDriverOnErrorJustComplete(),
            openDoorTrigger: openDoorTrigger.asDriverOnErrorJustComplete(),
            callPhoneTrigger: callPhoneTrigger.asDriverOnErrorJustComplete(),
            chatSelectTrigger: chatSelectTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.cameras
            .drive(
                onNext: { [weak self] cameras in
                    guard let self = self else {
                        return
                    }
                    self.setCameras(cameras)
                }
            )
            .disposed(by: disposeBag)
        
        output.intercoms
            .drive(
                onNext: { [weak self] intercoms in
                    guard let self = self else {
                        return
                    }
                    self.setIntercoms(intercoms)
                }
            )
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
                    self?.camerasView.isHidden = shouldBlockInteraction
                    self?.intercomsCollectionView.isHidden = shouldBlockInteraction
                    self?.skeletonContainer.isHidden = !shouldBlockInteraction
                    
                    if shouldBlockInteraction {
                        self?.skeletonContainer.showSkeletonAsynchronously()
                    } else {
                        self?.skeletonContainer.hideSkeleton()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.code
            .drive(
                onNext: { [weak self] args in
                    let (number, doorcode) = args
                    
                    let indexPath = IndexPath(row: number, section: 0)
                    guard let self = self, let cell = self.intercomsCollectionView.cellForItem(at: indexPath) as? AddressIntercomsViewCell else {
                        return
                    }
                    self.intercoms[number].doorcode = doorcode
                    cell.updateCode(code: doorcode)
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.stopAllCamerasPlaying)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    guard let self = self,
                          let camera = notification.object as? CameraInversObject else {
                        return
                    }
                    
                    for row in 0..<self.intercoms.count {
                        if let cell = self.intercomsCollectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? AddressIntercomsViewCell {
                            cell.stopAllPlayers(camera)
                        }
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // При уходе с окна или при сворачивании приложения - останавливаем обновление изображений и загрузку видео
        Driver
            .merge(
                NotificationCenter.default.rx
                    .notification(UIApplication.didEnterBackgroundNotification)
                    .asDriverOnErrorJustComplete()
                    .mapToVoid(),
                rx.viewDidDisappear.asDriver().mapToVoid()
            )
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    self.stopAllRefresh()
                }
            )
            .disposed(by: disposeBag)
        
        // При заходе на окно - обновляем изображения и восстанавливаем видеопоток для домофонов
        rx.viewDidAppear
            .asDriver()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    self.restoreAllRefresh()
                }
            )
            .disposed(by: disposeBag)
        
        // При разворачивании приложения (если окно открыто) - обновляем изображения
        
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(rx.isVisible.asDriverOnErrorJustComplete())
            .isTrue()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    self.restoreAllRefresh()
                }
            )
            .disposed(by: disposeBag)
   }
    
    func stopAllRefresh() {
        for row in 0..<self.cameras.count {
            if row < 1 {
                if let cell = self.camerasCollectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? CamerasViewCell {
                    cell.stopAllRefresh()
                }
            } else {
                if let cell = self.camerasCollectionView.cellForItem(at: IndexPath(row: row - 1, section: 1)) as? CamerasViewCell {
                    cell.stopAllRefresh()
                }
            }
        }
        
        for row in 0..<self.intercoms.count {
            if let cell = self.intercomsCollectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? AddressIntercomsViewCell {
                cell.stopAllRefresh()
            }
        }
    }
    
    func restoreAllRefresh() {
        for row in 0..<self.cameras.count {
            if row < 1 {
                if let cell = self.camerasCollectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? CamerasViewCell {
                    cell.restoreAllRefresh()
                }
            } else {
                if let cell = self.camerasCollectionView.cellForItem(at: IndexPath(row: row - 1, section: 1)) as? CamerasViewCell {
                    cell.restoreAllRefresh()
                }
            }
        }
        self.camerasCollectionView.reloadData()

        for row in 0..<self.intercoms.count {
            if let cell = self.intercomsCollectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? AddressIntercomsViewCell {
                cell.restoreAllRefresh()
                cell.reloadCollectionData()
            }
        }
    }
    
    func setCameras(_ cameras: [CameraExtendedObject]) {
        self.cameras = cameras
        camerasCollectionView.reloadData()
    }
    
    func setIntercoms(_ intercoms: [IntercomCamerasObject]) {
        self.intercoms = intercoms
        guard !intercoms.isEmpty else {
            intercomsCollectionView.isHidden = true
            notIntercomView.isHidden = false
//            viewHeightConstraint.constant = intercomsViewHeightConstraint.constant + 320 + notIntercomText.sizeThatFits(notIntercomText.bounds.size).height
            viewHeightConstraint.constant = 320 + notIntercomText.sizeThatFits(notIntercomText.bounds.size).height
            return
        }
        intercomsCollectionView.isHidden = false
        notIntercomView.isHidden = true

        viewHeightConstraint.constant = 543

        intercomsCollectionView.reloadData()
    }
}

extension NSAttributedString.Key {
    static let phoneAction = NSAttributedString.Key(rawValue: "callPhone")
    static let chatAction = NSAttributedString.Key(rawValue: "chatLink")
}

extension MyYardViewController: UICollectionViewDelegate {
    
}

extension MyYardViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == camerasCollectionView {
            return 2
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == intercomsCollectionView {
            return intercoms.count
        }
        if section == 0 {
            return 1
        }
        return cameras.count - 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == camerasCollectionView {
            return camerasCollectionView(collectionView, cellForItemAt: indexPath)
        }
        return intercomsCollectionView(collectionView, cellForItemAt: indexPath)
    }
    
    private func intercomsCollectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: AddressIntercomsViewCell.self, for: indexPath)
        
        cell.configureCell(intercom: intercoms[indexPath.row], delegate: self, accessService: accessService, dateCache: datesCache)
        
        return cell
    }
    
    private func camerasCollectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: CamerasViewCell.self, for: indexPath)

        if indexPath.section == 0 {
            if !cameras.isEmpty {
                let camera = cameras[indexPath.row]
                let previewString = accessService.backendURL +
                "/event/get/url/" + String(camera.id)
                
                cell.configureCell(camera: camera, urlString: previewString, dateCache: datesCache)
            }
        } else {
            let row = indexPath.row + 1
            
            let previewString = accessService.backendURL +
            "/event/get/url/" + String(cameras[row].id)
            
            cell.configureCell(camera: cameras[row], urlString: previewString, dateCache: datesCache)
        }

        cell.delegate = self
        return cell
    }
    
}

extension MyYardViewController: MyYardCellProtocol {
    
    func didTapPreviewImage(for cell: CamerasViewCell) {
        guard let camera = cell.camera else {
            return
        }
        selectCameraTrigger.onNext(camera)
    }
    
}

extension MyYardViewController: MyYardIntercomsCellProtocol {
    func didTapEvents(for cell: IntercomsViewCell) {
        guard let camera = cell.intercom else {
            return
        }
        eventsTrigger.onNext(camera)
    }
    
    func didTapCodeRefresh(for cell: IntercomsViewCell) {
        guard let camera = cell.intercom else {
            return
        }
        doorCodeRefreshTrigger.onNext(camera)
    }
    
    func didTapFaceID(for cell: IntercomsViewCell) {
        guard let camera = cell.intercom else {
            return
        }
        faceidTrigger.onNext(camera)
    }
    
    func didTapShare(for cell: IntercomsViewCell) {
        guard let camera = cell.intercom else {
            return
        }
        shareOpendoorTrigget.onNext(camera)
    }
    
    func didTapFullScreen(for cell: IntercomsViewCell) {
        guard let camera = cell.camera else {
            return
        }
        fullscreenTrigger.onNext(camera)
    }
    
    func didTapOpenDoor(for cell: IntercomsViewCell) {
        guard let camera = cell.intercom else {
            return
        }
        openDoorTrigger.onNext(camera)
    }
}

extension MyYardViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == camerasCollectionView {
            if indexPath.section == 0 {
                return CGSize(width: 225, height: camerasCollectionViewHeightConstraint.constant)
            }
            let height = (camerasCollectionViewHeightConstraint.constant - 1) / 2
            let width = height / 9 * 16
            return CGSize(width: width, height: height)
        }
        let height = (UIScreen.main.bounds.width - 16) / 16 * 9 + 74 + (intercoms[indexPath.row].cameras.count < 2 ? 0 : 26)
        
        return CGSize(width: UIScreen.main.bounds.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == camerasCollectionView {
            return 1
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == camerasCollectionView {
            return 1
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == .zero, collectionView == camerasCollectionView {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 1)
        }
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}
// swiftlint:enable function_body_length type_body_length
