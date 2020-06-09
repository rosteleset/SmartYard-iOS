//
//  PlayArchiveVideoViewController.swift
//  SmartYard
//
//  Created by admin on 02.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AVKit

class PlayArchiveVideoViewController: BaseViewController {
    
    enum Mode {
        case preview
        case edit
    }
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var videoContainer: UIView!
    @IBOutlet private weak var periodCollectionView: UICollectionView!
    @IBOutlet private weak var playButton: UIButton!
    
    private var playerViewController: AVPlayerViewController?
    private var player: AVPlayer?
    
    // MARK: Preview mode
    
    @IBOutlet private weak var halfSpeedButton: UIButton!
    @IBOutlet private weak var oneAndHalfSpeedButton: UIButton!
    @IBOutlet private weak var progressSlider: SimpleVideoProgressSlider!
    
    // MARK: Edit mode
    
    @IBOutlet private weak var fastForwardButton: UIButton!
    @IBOutlet private weak var fastBackwardButton: UIButton!
    @IBOutlet private weak var rangeSlider: SimpleVideoRangeSlider!
    
    private var preferredPlaybackRate: Float = 1 {
        didSet {
            guard let player = player else {
                return
            }
            
            if player.rate != 0 {
                player.rate = preferredPlaybackRate
            }
        }
    }
    
    private let viewModel: PlayArchiveVideoViewModel
    
    private let periodsProxy = BehaviorSubject<[ArchiveVideoHourPeriod]>(value: [])
    private let periodSelectedTrigger = PublishSubject<ArchiveVideoHourPeriod?>()
    private let currentMode = BehaviorSubject<Mode>(value: .preview)
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    
    init(viewModel: PlayArchiveVideoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePeriodPicker()
        configurePlayButton()
        configureHalfSpeedButton()
        configureOneAndHalfSpeedButton()
        configureFastBackwardButton()
        configureFastForwardButton()
        configurePlayer()
        
        currentMode.onNext(.edit)
        
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        playerViewController?.view.frame = videoContainer.bounds
    }
    
    private func configurePeriodPicker() {
        periodCollectionView.register(nibWithCellClass: VideoPeriodPickerCell.self)
        
        periodCollectionView.dataSource = self
        periodCollectionView.delegate = self
    }
    
    private func configurePlayButton() {
        playButton.configureSelectableButton(
            imageForNormal: UIImage(named: "Play"),
            imageForSelected: UIImage(named: "Pause")
        )
        
        playButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    let newState = !self.playButton.isSelected
                    
                    self.player?.rate = newState ? self.preferredPlaybackRate : 0
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureHalfSpeedButton() {
        halfSpeedButton.setTitleColor(UIColor.SmartYard.gray, for: .normal)
        halfSpeedButton.setTitleColor(UIColor.SmartYard.gray.darken(by: 0.1), for: [.normal, .highlighted])
        halfSpeedButton.setTitleColor(UIColor.SmartYard.blue, for: .selected)
        halfSpeedButton.setTitleColor(UIColor.SmartYard.blue.darken(by: 0.1), for: [.selected, .highlighted])
        
        halfSpeedButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    let newState = !self.halfSpeedButton.isSelected
                    
                    self.halfSpeedButton.isSelected = newState
                    
                    if newState {
                        self.oneAndHalfSpeedButton.isSelected = false
                        self.preferredPlaybackRate = 0.5
                    } else {
                        self.preferredPlaybackRate = 1
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureOneAndHalfSpeedButton() {
        oneAndHalfSpeedButton.setTitleColor(UIColor.SmartYard.gray, for: .normal)
        oneAndHalfSpeedButton.setTitleColor(UIColor.SmartYard.gray.darken(by: 0.1), for: [.normal, .highlighted])
        oneAndHalfSpeedButton.setTitleColor(UIColor.SmartYard.blue, for: .selected)
        oneAndHalfSpeedButton.setTitleColor(UIColor.SmartYard.blue.darken(by: 0.1), for: [.selected, .highlighted])
        
        oneAndHalfSpeedButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    let newState = !self.oneAndHalfSpeedButton.isSelected
                    
                    self.oneAndHalfSpeedButton.isSelected = newState
                    
                    if newState {
                        self.halfSpeedButton.isSelected = false
                        self.preferredPlaybackRate = 1.5
                    } else {
                        self.preferredPlaybackRate = 1
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureFastBackwardButton() {
        fastBackwardButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.rangeSlider?.moveEndIndicatorByValueInSeconds(-15)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureFastForwardButton() {
        fastForwardButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.rangeSlider?.moveEndIndicatorByValueInSeconds(15)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configurePlayer() {
        let playerViewController = AVPlayerViewController()
        playerViewController.videoGravity = .resizeAspect
        self.playerViewController = playerViewController
        
        let player = AVPlayer()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = false
        self.player = player
        
        addChild(playerViewController)
        videoContainer.insertSubview(playerViewController.view, at: 0)
        playerViewController.didMove(toParent: self)
        
        // MARK: Проверка, валидно ли текущее видео
        
        Driver
            .combineLatest(
                player.rx
                    .observe(AVPlayer.Status.self, "status", options: [.new])
                    .asDriver(onErrorJustReturn: nil),
                player.rx
                    .observe(AVPlayerItem.self, "currentItem", options: [.new])
                    .asDriver(onErrorJustReturn: nil)
            )
            .map { args -> Bool in
                let (status, currentItem) = args
                
                guard status == .readyToPlay,
                    let asset = currentItem?.asset,
                    asset.duration.seconds > 0 else {
                    return false
                }
                
                return true
            }
            .drive(
                onNext: { [weak self] isVideoValid in
                    self?.isVideoValid.onNext(isVideoValid)
                }
            )
            .disposed(by: disposeBag)
        
//        player.rx
//            .observe(AVPlayer.Status.self, "status", options: [.new])
//            .asDriver(onErrorJustReturn: nil)
//            .map { [weak self] status -> Bool in
//                guard let self = self,
//                    status == .readyToPlay,
//                    let asset = self.player?.currentItem?.asset,
//                    asset.duration.seconds > 0 else {
//                    return false
//                }
//
//                return true
//            }
//            .drive(
//                onNext: { [weak self] isVideoValid in
//                    self?.isVideoValid.onNext(isVideoValid)
//                }
//            )
//            .disposed(by: disposeBag)
        
        // MARK: Проверка, воспроизводится ли видео в данный момент
        
        player.rx
            .observe(Float.self, "rate", options: [.new])
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] rate in
                    guard let self = self else {
                        return
                    }
                    
                    self.playButton.isSelected = rate != 0
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Привязка к обновлению текущего времени проигрываемого видео
        
        player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] time in
            self?.progressSlider.setCurrentTime(time)
        }
        
        progressSlider.delegate = self
        rangeSlider.delegate = self
    }

    private func bind() {
        let input = PlayArchiveVideoViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            periodSelectedTrigger: periodSelectedTrigger.asDriver(onErrorJustReturn: nil)
        )
        
        let output = viewModel.transform(input)
        
        output.date
            .map { date -> String? in
                guard let date = date else {
                    return nil
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yy"
                
                return "Видео от \(dateFormatter.string(from: date))"
            }
            .drive(dateLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.videoURL
            .drive(
                onNext: { [weak self] url in
                    let playerItem: AVPlayerItem? = {
                        guard let url = url else {
                            return nil
                        }
                        
                        return AVPlayerItem(url: url)
                    }()
                    
                    self?.player?.replaceCurrentItem(with: playerItem)
                    self?.progressSlider.setVideoURL(videoURL: url)
                    self?.rangeSlider?.setVideoURL(videoURL: url)
                }
            )
            .disposed(by: disposeBag)
        
        output.preview
            .drive(
                onNext: { [weak self] url in
                    self?.progressSlider.setFakeThumbnailURL(thumbnailURL: url)
                    self?.rangeSlider?.setFakeThumbnailURL(thumbnailURL: url)
                }
            )
            .disposed(by: disposeBag)
        
        output.periodConfiguration
            .drive(
                onNext: { [weak self] in
                    self?.periodsProxy.onNext($0)
                }
            )
            .disposed(by: disposeBag)
        
        periodsProxy
            .subscribe(
                onNext: { [weak self] _ in
                    self?.periodCollectionView.reloadData()
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: local UI bindings
        
        Driver
            .combineLatest(
                currentMode.asDriverOnErrorJustComplete(), isVideoValid.asDriverOnErrorJustComplete()
            )
            .drive(
                onNext: { [weak self] args in
                    guard let self = self else {
                        return
                    }
                    
                    let (mode, isVideoValid) = args
                    
                    [
                        self.halfSpeedButton,
                        self.oneAndHalfSpeedButton,
                        self.fastBackwardButton,
                        self.fastForwardButton
                    ].forEach {
                        $0?.isEnabled = isVideoValid
                    }
                    
                    self.playButton.isEnabled = isVideoValid && mode == .preview
                }
            )
            .disposed(by: disposeBag)
        
        currentMode
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] mode in
                    self?.halfSpeedButton.isHidden = mode == .edit
                    self?.oneAndHalfSpeedButton.isHidden = mode == .edit
                    self?.progressSlider.isHidden = mode == .edit
                    
                    self?.fastForwardButton.isHidden = mode == .preview
                    self?.fastBackwardButton.isHidden = mode == .preview
                    self?.rangeSlider?.isHidden = mode == .preview
                }
            )
            .disposed(by: disposeBag)
    }

}

extension PlayArchiveVideoViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (try? periodsProxy.value())?.count ?? 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let period = (try? periodsProxy.value())?[safe: indexPath.row] else {
            return VideoPeriodPickerCell()
        }
        
        let cell = collectionView.dequeueReusableCell(withClass: VideoPeriodPickerCell.self, for: indexPath)
        
        cell.setTitle(period.title)
        
        return cell
    }
    
}

extension PlayArchiveVideoViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 96, height: 24)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 18
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 18
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let period = (try? periodsProxy.value())?[safe: indexPath.row] else {
            return
        }
        
        periodSelectedTrigger.onNext(period)
    }
    
}

extension PlayArchiveVideoViewController: SimpleVideoProgressSliderDelegate {
    
    func indicatorDidChangePosition(videoRangeSlider: SimpleVideoProgressSlider, position: Float64) {
        player?.seek(to: CMTime(seconds: position, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }
    
}

extension PlayArchiveVideoViewController: SimpleVideoRangeSliderDelegate {
    
    func didChangeValue(videoRangeSlider: SimpleVideoRangeSlider, startTime: Float64, endTime: Float64) {
        print(startTime, endTime)
    }
    
}
