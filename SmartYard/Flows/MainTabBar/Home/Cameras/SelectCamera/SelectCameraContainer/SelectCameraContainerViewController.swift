//
//  SelectCameraContainerViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 13.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AVKit

class SelectCameraContainerViewController: BaseViewController {

    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var cameraNameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var segmentControlView: SmartYardSegmentedControl!
    @IBOutlet private weak var onlineView: OnlineView!
    @IBOutlet private weak var archiveView: ArchiveView!
    
    private var playerViewController: AVPlayerViewController?
    private var player: AVPlayer?
    
    private let viewModel: SelectCameraContainerViewModel
    
    let selectDateTrigger = PublishSubject<Date>()
    let selectCameraTrigger = PublishSubject<CameraObject>()
    
    init(viewModel: SelectCameraContainerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        archiveView.parentViewWillTransition(to: size, with: coordinator)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureOnlineView()
        configureArchiveView()
        
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        archiveView.setupCalendar()
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
    
    private func configureUI() {
        segmentControlView.segmentItems = ["Онлайн", "Архив"]
        archiveView.isHidden = true
        onlineView.isHidden = false
    }
    
    private func configureOnlineView() {
        let playerViewController = AVPlayerViewController()
        playerViewController.videoGravity = .resizeAspect
        self.playerViewController = playerViewController
        
        let player = AVPlayer()
        playerViewController.player = player
        self.player = player
        
        addChild(playerViewController)
        onlineView.setPlayer(player, playerView: playerViewController.view)
        playerViewController.didMove(toParent: self)
        
        onlineView.delegate = self
    }
    
    private func configureArchiveView() {
        archiveView.delegate = self
    }
    
    private func bind() {
        segmentControlView.rx
            .selectedIndex
            .asDriver()
            .drive(
                onNext: { [weak self] index in
                    guard index == 0 else {
                        self?.archiveView.isHidden = false
                        self?.onlineView.isHidden = true
                        
                        return
                    }
                    
                    self?.archiveView.isHidden = true
                    self?.onlineView.isHidden = false
                }
            )
            .disposed(by: disposeBag)
        
        let input = SelectCameraContainerViewModel.Input(
            selectedCameraTrigger: selectCameraTrigger.asDriverOnErrorJustComplete(),
            selectedDateTrigger: selectDateTrigger.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.address
            .drive(
                onNext: { [weak self] in
                    self?.addressLabel.text = $0
                }
            )
            .disposed(by: disposeBag)
        
        output.cameraConfiguration
            .drive(
                onNext: { [weak self] config in
                    self?.onlineView.setCameras(config.cameras, selectedCamera: config.preselectedCamera)
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension SelectCameraContainerViewController: OnlineViewDelegate {
    
    func onlineView(_ onlineView: OnlineView, didSelectCamera camera: CameraObject) {
        selectCameraTrigger.onNext(camera)
        
        cameraNameLabel.text = camera.name
    }
    
}

extension SelectCameraContainerViewController: ArchiveViewDelegate {
    
    func archiveView(_ archiveView: ArchiveView, didSelectDate date: Date) {
        selectDateTrigger.onNext(date)
    }
    
}
