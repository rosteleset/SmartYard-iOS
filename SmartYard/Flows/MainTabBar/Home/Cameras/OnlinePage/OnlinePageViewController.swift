//
//  OnlinePageViewController.swift
//  SmartYard
//
//  Created by admin on 15.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AVKit
import TouchAreaInsets

protocol OnlinePageViewControllerDelegate: AnyObject {
    
    func onlinePageViewController(_ vc: OnlinePageViewController, didSelectCamera camera: CameraObject)
    
}

class OnlinePageViewController: BaseViewController {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var cameraContainer: UIView!
    @IBOutlet private weak var fullscreenButton: UIButton!
    
    private var playerViewController: AVPlayerViewController?
    private var player: AVPlayer?
    
    @IBOutlet private var collectionViewHeightConstraint: NSLayoutConstraint!
    
    private var cameras = [CameraObject]()
    private var selectedCameraNumber: Int?
    
    weak var delegate: OnlinePageViewControllerDelegate?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        title = "Онлайн"
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePlayer()
        configureFullscreenButton()
        configureCollectionView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        playerViewController?.view.frame = cameraContainer.bounds
    }
    
    func setCameras(_ cameras: [CameraObject], selectedCamera: CameraObject?) {
        self.cameras = cameras
        
        collectionView.reloadData { [weak self] in
            guard let selectedCamera = selectedCamera,
                let index = cameras.firstIndex(of: selectedCamera) else {
                return
            }

            let indexPath = IndexPath(row: index, section: 0)

            self?.collectionView.selectItem(
                at: indexPath,
                animated: false,
                scrollPosition: .top
            )

            self?.reloadCameraIfNeeded(selectedIndexPath: indexPath)
        }
    }
    
    private func configurePlayer() {
        let playerViewController = AVPlayerViewController()
        playerViewController.videoGravity = .resizeAspect
        playerViewController.showsPlaybackControls = false
        self.playerViewController = playerViewController
        
        let player = AVPlayer()
        playerViewController.player = player
        self.player = player
        
        addChild(playerViewController)
        cameraContainer.insertSubview(playerViewController.view, at: 0)
        playerViewController.didMove(toParent: self)
        
        // MARK: Когда полноэкранное видео будет закрыто, нужно добавить child controller заново
        
        NotificationCenter.default.rx
            .notification(.onlineFullscreenModeClosed)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self, let playerVc = self.playerViewController else {
                        return
                    }
                    
                    playerVc.showsPlaybackControls = false
                    playerVc.willMove(toParent: nil)
                    playerVc.view.removeFromSuperview()
                    playerVc.removeFromParent()
                    
                    self.addChild(playerVc)
                    self.cameraContainer.insertSubview(playerVc.view, at: 0)
                    playerVc.didMove(toParent: self)
                    playerVc.player?.play()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureFullscreenButton() {
        fullscreenButton.setImage(UIImage(named: "Fullscreen"), for: .normal)
        fullscreenButton.setImage(UIImage(named: "Fullscreen")?.darkened(), for: [.normal, .highlighted])
        
        fullscreenButton.touchAreaInsets = UIEdgeInsets(inset: 12)
        
        // MARK: При нажатии на кнопку фуллскрина показываем новый VC с видео на весь экран
        
        fullscreenButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let playerVc = self?.playerViewController else {
                        return
                    }
                    
                    playerVc.showsPlaybackControls = true
                    playerVc.willMove(toParent: nil)
                    playerVc.view.removeFromSuperview()
                    playerVc.removeFromParent()

                    let fullscreenVc = FullscreenPlayerViewController(
                        playedVideoType: .online,
                        preferredPlaybackRate: 1
                    )
                    
                    fullscreenVc.modalPresentationStyle = .overFullScreen
                    fullscreenVc.modalTransitionStyle = .crossDissolve
                    fullscreenVc.setPlayerViewController(playerVc)

                    self?.present(fullscreenVc, animated: true) {
                        playerVc.player?.play()
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(nibWithCellClass: CameraNumberCell.self)
        
        collectionView.rx
            .observeWeakly(CGSize.self, "contentSize")
            .subscribe(
                onNext: { [weak self] size in
                    guard let self = self, let uSize = size else {
                        return
                    }
                    
                    self.collectionViewHeightConstraint.constant = uSize.height
                    self.view.setNeedsLayout()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func reloadCameraIfNeeded(selectedIndexPath: IndexPath) {
        let camera = cameras[selectedIndexPath.row]
        
        print("Selected Camera #\(camera.cameraNumber)")
        
        guard camera.cameraNumber != selectedCameraNumber else {
            return
        }
        
        selectedCameraNumber = camera.cameraNumber
        
        delegate?.onlinePageViewController(self, didSelectCamera: camera)
        
        let resultingString = camera.video + "/index.m3u8" + "?token=\(camera.token)"
        
        let item: AVPlayerItem? = {
            guard let url = URL(string: resultingString) else {
                return nil
            }
            
            return AVPlayerItem(url: url)
        }()
        
        player?.replaceCurrentItem(with: item)
        player?.play()
    }
    
}

extension OnlinePageViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cameras.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: CameraNumberCell.self, for: indexPath)

        cell.configure(curCamera: cameras[indexPath.row])

        return cell
    }

}

extension OnlinePageViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 36, height: 36)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 28
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 24
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 0, bottom: 24, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        reloadCameraIfNeeded(selectedIndexPath: indexPath)
    }
    
}
