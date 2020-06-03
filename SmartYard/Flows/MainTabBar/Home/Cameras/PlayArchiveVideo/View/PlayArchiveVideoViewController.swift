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
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var videoContainer: UIView!
    
    @IBOutlet private weak var periodCollectionView: UICollectionView!
    
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var halfSpeedButton: UIButton!
    @IBOutlet private weak var oneAndHalfSpeedButton: UIButton!
    
    private var playerViewController: AVPlayerViewController?
    private var player: AVPlayer?
    
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
        configurePlayer()
        
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
                    
                    self.playButton.isSelected = newState
                    
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
    
    private func configurePlayer() {
        let playerViewController = AVPlayerViewController()
        playerViewController.videoGravity = .resizeAspect
        self.playerViewController = playerViewController
        
        let player = AVPlayer()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = false
        self.player = player
        
        addChild(playerViewController)
        videoContainer.addSubview(playerViewController.view)
        playerViewController.didMove(toParent: self)
        
        player.rx
            .observeWeakly(AVPlayer.Status.self, "status", options: [.new])
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] status in
                    guard let self = self else {
                        return
                    }
                    
                    [self.halfSpeedButton, self.playButton, self.oneAndHalfSpeedButton].forEach {
                        $0?.isEnabled = status == .readyToPlay
                    }
                }
            )
            .disposed(by: disposeBag)
        
        let urlString = "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"
        let url = URL(string: urlString)!
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
    }

    private func bind() {
        let input = PlayArchiveVideoViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
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
    }

}

extension PlayArchiveVideoViewController: UICollectionViewDataSource {
    
    var periods: [String] {
        return [
            "00.00 - 03.00",
            "03.00 - 06.00",
            "06.00 - 09.00",
            "09.00 - 12.00",
            "12.00 - 15.00",
            "15.00 - 18.00",
            "18.00 - 21.00",
            "21.00 - 00.00"
        ]
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return periods.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: VideoPeriodPickerCell.self, for: indexPath)
        
        cell.setTitle(periods[indexPath.row])
        
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
        print(indexPath.row)
    }
    
}
