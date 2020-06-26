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
import JGProgressHUD

class PlayArchiveVideoViewController: BaseViewController, LoaderPresentable {
    
    enum Mode {
        case preview
        case edit
    }
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    var loader: JGProgressHUD?
    
    @IBOutlet private var buttonsContainerToCollectionViewConstraint: NSLayoutConstraint!
    
    // MARK: Preview mode
    
    @IBOutlet private weak var previewDateLabel: UILabel!
    
    @IBOutlet private weak var halfSpeedButton: UIButton!
    @IBOutlet private weak var oneAndHalfSpeedButton: UIButton!
    
    @IBOutlet private weak var periodCollectionView: UICollectionView!
    @IBOutlet private weak var previewButtonsContainer: UIView!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var selectFragmentButton: BlueButton!
    
    @IBOutlet private weak var realVideoContainer: UIView!
    @IBOutlet private weak var progressSlider: SimpleVideoProgressSlider!
    
    private var realVideoPlayerViewController: AVPlayerViewController?
    private var realVideoPlayer: AVPlayer?
    
    private var preferredPlaybackRate: Float = 1 {
        didSet {
            guard let player = realVideoPlayer else {
                return
            }
            
            if player.rate != 0 {
                player.rate = preferredPlaybackRate
            }
        }
    }
    
    // MARK: Edit mode
    
    @IBOutlet private weak var editDateLabel: UILabel!
    
    @IBOutlet private weak var shiftTimelineBackwardButton: UIButton!
    @IBOutlet private weak var shiftTimelineForwardButton: UIButton!
    
    @IBOutlet private weak var editButtonsContainer: UIView!
    @IBOutlet private weak var backToPreviewButton: UIButton!
    @IBOutlet private weak var downloadButton: BlueButton!
    
    @IBOutlet private weak var screenshotContainer: UIView!
    @IBOutlet private weak var screenshotImageView: UIImageView!
    @IBOutlet private weak var rangeSlider: SimpleVideoRangeSlider!
    
    private let viewModel: PlayArchiveVideoViewModel
    
    private let periodsProxy = BehaviorSubject<[ArchiveVideoHourPeriod]>(value: [])
    private let periodSelectedTrigger = PublishSubject<ArchiveVideoHourPeriod?>()
    private let startEndSelectedTrigger = PublishSubject<(Date, Date)>()
    private let screenshotTrigger = PublishSubject<Date>()
    
    private let currentMode = BehaviorSubject<Mode>(value: .preview)
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let currentPlaybackTime = BehaviorSubject<CMTime>(value: .zero)
    
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
        
        // Preview mode
        
        configurePeriodPicker()
        configurePlayButton()
        configureHalfSpeedButton()
        configureOneAndHalfSpeedButton()
        configureSelectFragmentButton()
        configureRealVideoPlayer()
        
        // Edit mode

        configureTimelineButtons()
        configureBackToPreviewButton()
        
        // Common
        
        configureSliders()
        configureUIBindings()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        realVideoPlayerViewController?.view.frame = realVideoContainer.bounds
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
                    
                    self.realVideoPlayer?.rate = newState ? self.preferredPlaybackRate : 0
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
    
    private func configureSelectFragmentButton() {
        selectFragmentButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.currentMode.onNext(.edit)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureTimelineButtons() {
        shiftTimelineBackwardButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.rangeSlider.shiftTimelineByValueInSeconds(-900)
                }
            )
            .disposed(by: disposeBag)
        
        shiftTimelineForwardButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.rangeSlider.shiftTimelineByValueInSeconds(900)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureBackToPreviewButton() {
        backToPreviewButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.currentMode.onNext(.preview)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureRealVideoPlayer() {
        let playerViewController = AVPlayerViewController()
        playerViewController.videoGravity = .resizeAspect
        self.realVideoPlayerViewController = playerViewController
        
        let player = AVPlayer()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = false
        self.realVideoPlayer = player
        
        addChild(playerViewController)
        realVideoContainer.insertSubview(playerViewController.view, at: 0)
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
            self?.currentPlaybackTime.onNext(time)
        }
    }
    
    private func configureSliders() {
        progressSlider.delegate = self
        rangeSlider.delegate = self
    }
    
    private func configureUIBindings() {
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
                    
                    self.updateUI(mode: mode, isVideoValid: isVideoValid)
                }
            )
            .disposed(by: disposeBag)
        
        currentPlaybackTime
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] time in
                    self?.progressSlider.setCurrentTime(time)
                }
            )
            .disposed(by: disposeBag)
        
        let currentPlaybackTimeDistinctSeconds = currentPlaybackTime
            .asDriverOnErrorJustComplete()
            .map { $0.seconds }
            .distinctUntilChanged { lhs, rhs in
                abs(lhs - rhs) < 0.001
            }
        
        Driver
            .combineLatest(
                periodSelectedTrigger.asDriverOnErrorJustComplete(),
                currentPlaybackTimeDistinctSeconds
            )
            .drive(
                onNext: { [weak self] args in
                    guard let self = self else {
                        return
                    }
                    
                    let (period, playbackTime) = args
                    
                    guard let uPeriod = period else {
                        return
                    }
                    
                    // MARK: Максимальная дата, которую можно выбрать. Равняется текущей дате по МСК
                    // Если у нас 00:00, то в Москве еще 23:00. Соответственно, максимум можно выбрать 23:00
                    // Поэтому вычитаем разницу между локальной таймзоной и МСК из текущего времени
                    
                    let diffWithMoscow = TimeZone.current.secondsFromGMT() / 3600 - Date.moscowOffsetFromGMT
                    
                    let upperBound = Date().adding(.hour, value: -diffWithMoscow)
                    let lowerBound = upperBound.adding(.day, value: -7)
                    
                    let visibleTimelineEndDate = uPeriod.baseDate
                        .adding(.hour, value: uPeriod.startHours)
                        .addingTimeInterval(playbackTime)
                        .adding(.minute, value: 30)
                    
                    self.rangeSlider.setTimelineConfiguration(
                        visibleTimelineEndDate: visibleTimelineEndDate,
                        lowerBound: lowerBound,
                        upperBound: upperBound
                    )
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func updateUI(mode: Mode, isVideoValid: Bool) {
        [
            halfSpeedButton,
            oneAndHalfSpeedButton,
            selectFragmentButton
        ].forEach {
            $0?.isEnabled = isVideoValid
        }
        
        progressSlider.isHidden = mode == .edit || !isVideoValid
        playButton.isEnabled = mode == .preview && isVideoValid
        
        previewButtonsContainer.isHidden = mode == .edit
        halfSpeedButton.isHidden = mode == .edit
        oneAndHalfSpeedButton.isHidden = mode == .edit
        selectFragmentButton.isHidden = mode == .edit
        playButton.isHidden = mode == .edit
        realVideoContainer.isHidden = mode == .edit
        periodCollectionView.isHidden = mode == .edit
        previewDateLabel.isHidden = mode == .edit
        
        editButtonsContainer.isHidden = mode == .preview
        shiftTimelineBackwardButton.isHidden = mode == .preview
        shiftTimelineForwardButton.isHidden = mode == .preview
        downloadButton.isHidden = mode == .preview
        backToPreviewButton.isHidden = mode == .preview
        screenshotContainer.isHidden = mode == .preview
        editDateLabel.isHidden = mode == .preview
        
        buttonsContainerToCollectionViewConstraint.isActive = mode == .preview
        
        if mode == .edit {
            realVideoPlayer?.rate = 0
        }
    }

    private func bind() {
        let input = PlayArchiveVideoViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            downloadTrigger: downloadButton.rx.tap.asDriver(),
            periodSelectedTrigger: periodSelectedTrigger.asDriver(onErrorJustReturn: nil),
            startEndSelectedTrigger: startEndSelectedTrigger.asDriverOnErrorJustComplete(),
            screenshotTrigger: screenshotTrigger.asDriverOnErrorJustComplete()
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
            .drive(previewDateLabel.rx.text)
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
                    
                    self?.realVideoPlayer?.replaceCurrentItem(with: playerItem)
                    self?.progressSlider.setVideoURL(videoURL: url)
                }
            )
            .disposed(by: disposeBag)
        
        output.videoThumbnailURL
            .drive(
                onNext: { [weak self] url in
                    guard let thumbnailUrl = url else {
                        return
                    }
                    
                    let image = ScreenshotHelper.generateThumbnailFromVideoUrl(url: thumbnailUrl, forTime: .zero)
                    
                    self?.progressSlider.setFakeThumbnailImage(image)
                    self?.rangeSlider.setFakeThumbnailImage(image)
                }
            )
            .disposed(by: disposeBag)
        
        output.screenshotURL
            .drive(
                onNext: { [weak self] url in
                    guard let screenshotUrl = url else {
                        return
                    }
                    
                    let image = ScreenshotHelper.generateThumbnailFromVideoUrl(url: screenshotUrl, forTime: .zero)
                    self?.screenshotImageView.image = image
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
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
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
    
    func indicatorDidChangePosition(
        videoRangeSlider: SimpleVideoProgressSlider,
        isReceivingGesture: Bool,
        position: Float64
    ) {
        guard !isReceivingGesture else {
            return
        }
        
        realVideoPlayer?.seek(
            to: CMTime(seconds: position, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }
    
}

extension PlayArchiveVideoViewController: SimpleVideoRangeSliderDelegate {
    
    func didChangeDate(
        videoRangeSlider: SimpleVideoRangeSlider,
        isReceivingGesture: Bool,
        startDate: Date,
        endDate: Date,
        isLowerBoundReached: Bool,
        isUpperBoundReached: Bool,
        screenshotPolicy: SimpleVideoRangeSlider.ScreenshotPolicy
    ) {
        startEndSelectedTrigger.onNext((startDate, endDate))
        
        shiftTimelineBackwardButton.isEnabled = !isLowerBoundReached
        shiftTimelineForwardButton.isEnabled = !isUpperBoundReached
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        
        editDateLabel.text = "Видео от \(dateFormatter.string(from: startDate))"
        
        guard !isReceivingGesture else {
            return
        }
        
        switch screenshotPolicy {
        case .start:
            screenshotTrigger.onNext(startDate)
            
        case .end:
            screenshotTrigger.onNext(endDate)
            
        case .middle:
            let diff = endDate.timeIntervalSince(startDate)
            let dateInMiddle = startDate.addingTimeInterval(diff / 2)
            
            screenshotTrigger.onNext(dateInMiddle)
            
        case .none:
            break
        }
    }
    
}
