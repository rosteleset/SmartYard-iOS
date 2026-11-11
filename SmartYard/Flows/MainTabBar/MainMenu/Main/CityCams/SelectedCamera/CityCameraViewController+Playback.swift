// Created by Александр Попов. Copyright © 2026 Sesameware.

import UIKit
import JGProgressHUD
import RxSwift
import RxCocoa
import RxDataSources
import AVKit
import Lottie

extension CityCameraViewController {
    fileprivate func fixButton() {
        if self.buttonState == .requestRec {
            self.button.setTitle(L10n.Camera.City.requestRecordButton, for: .normal)
            self.button.backgroundColor = UIColor.SmartYard.blue
            self.button.setTitleColor(UIColor.SmartYard.secondBackgroundColor, for: .normal)
            self.buttonState = .requestRec

        } else {
            self.button.setTitle(
                "\(L10n.Camera.City.incidentsTitle) (" + String(self.videos?.count ?? 0) + ")",
                for: .normal
            )
            self.button.backgroundColor = UIColor.SmartYard.secondBackgroundColor
            self.button.setTitleColor(UIColor.SmartYard.blue, for: .normal)
            self.buttonState = .incidents
        }
        if viewState == .compact {
                self.cameraNameConstraints.forEach { $0.isActive = false }
                self.cameraNameConstraintsMini.forEach { $0.isActive = true }
                self.cameraAddress.isHidden = true
                self.cameraName.font = self.cameraName.font.withSize(24)
                self.cameraName.textAlignment = .center
                self.view.layoutIfNeeded()
        }
    }

    func configurePlayer() {
        let player = AVPlayer()
        player.isMuted = true
        self.player = player

        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
        }

        playerLayer = AVPlayerLayer(player: player)
        cameraContainer.layer.insertSublayer(playerLayer!, at: 0)
        playerLayer?.frame = cameraContainer.bounds
        playerLayer?.removeAllAnimations()
        playerLayer?.backgroundColor = UIColor.black.cgColor

        // MARK: Настройка лоадера

        let animation = LottieAnimation.named("LoaderAnimation")

        videoLoadingAnimationView.animation = animation
        videoLoadingAnimationView.loopMode = .loop
        videoLoadingAnimationView.backgroundBehavior = .pauseAndRestore

        bindFullscreenReturn()

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
                    asset.duration.seconds > 0 || asset.duration.flags.rawValue == 17 else {
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
    }

    private func bindFullscreenReturn() {
        // MARK: Когда полноэкранное видео будет закрыто, нужно добавить слой заново

        NotificationCenter.default.rx
            .notification(.onlineFullscreenModeClosed)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self, let playerLayer = self.playerLayer else {
                        return
                    }

                    var shouldTurnOnSound = true
                    do {
                        shouldTurnOnSound = try !(self.isSoundOn.value() || self.player?.isMuted ?? true)
                    } catch {
                        Logger.logError("Getting isSoundOn value: \(error)")
                    }

                    playerLayer.removeFromSuperlayer()
                    self.cameraContainer.layer.insertSublayer(playerLayer, at: 0)

                    playerLayer.frame = self.cameraContainer.bounds
                    playerLayer.removeAllAnimations()

                    self.isSoundOn.onNext(shouldTurnOnSound)
                    self.player?.play()

                    // странный баг на iOS 12.4
                    // если был переход в полноэкранный режим, потом поворот экрана и возврат назад, то у кнопки менялся свет текста на непойми какой.
                    // приходится ручками при возврате из полноэкранного режима обновлять значения полей.
                    self.fixButton()
                }
            )
            .disposed(by: disposeBag)
    }

    func configureSoundToggleButton() {
        soundToggleButton.setImage(UIImage(named: "SoundOff"), for: .normal)
        soundToggleButton.setImage(UIImage(named: "SoundOn"), for: .selected)

        soundToggleButton.touchAreaInsets = UIEdgeInsets(inset: 12)

        soundToggleButton.rx.tap
            .withLatestFrom(isSoundOn) { _, isSoundOn in !isSoundOn }
            .bind(to: isSoundOn)
            .disposed(by: disposeBag)
    }

    private func updateSoundButtonVisibility(for hasSound: Bool) {
        soundToggleButton.isHidden = !hasSound
    }

    func configureFullscreenButton() {
        fullscreenButton.setImage(UIImage(named: "Fullscreen"), for: .normal)
        fullscreenButton.setImage(UIImage(named: "Fullscreen")?.darkened(), for: [.normal, .highlighted])

        fullscreenButton.touchAreaInsets = UIEdgeInsets(inset: 12)

        // MARK: При нажатии на кнопку фуллскрина показываем новый VC с видео на весь экран

        fullscreenButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self,
                          let playerLayer = self.playerLayer else {
                        return
                    }

                    playerLayer.removeFromSuperlayer()

                    var shouldTurnOnSound = false
                    do {
                        shouldTurnOnSound = try self.isSoundOn.value()
                    } catch {
                        Logger.logError("Getting isSoundOn value: \(error)")
                    }

                    let fullscreenVc = FullscreenPlayerViewController(
                        playedVideoType: .online,
                        preferredPlaybackRate: 1,
                        hasSound: self.hasSound,
                        isSoundOn: shouldTurnOnSound
                    )

                    fullscreenVc.modalPresentationStyle = .overFullScreen
                    fullscreenVc.modalTransitionStyle = .crossDissolve
                    fullscreenVc.setPlayerLayer(playerLayer)

                    self.present(fullscreenVc, animated: true) {
                        self.player?.play()
                    }
                }
            )
            .disposed(by: disposeBag)
    }

    fileprivate func startToPlay(_ url: URL) {
        let asset = AVAsset(url: url)

        loadingAsset = asset

        isVideoBeingLoaded.onNext(true)

        asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) { [weak self, weak asset] in
            guard let asset = asset else {
                return
            }

            var tracksError: NSError?
            var durationError: NSError?

            let tracksStatus = asset.statusOfValue(forKey: "tracks", error: &tracksError)
            let durationStatus = asset.statusOfValue(forKey: "duration", error: &durationError)

            if tracksStatus == .cancelled ||
                tracksStatus == .failed ||
                durationStatus == .cancelled ||
                durationStatus == .failed {
                self?.isVideoBeingLoaded.onNext(false)
                return
            }

            guard tracksStatus == .loaded, durationStatus == .loaded else {
                return
            }

            self?.isVideoBeingLoaded.onNext(false)

            DispatchQueue.main.async {
                // MARK: Ассет загружен, больше хранить его не нужно

                self?.loadingAsset = nil

                // MARK: Видео готово к просмотру, засовываем его в плеер

                let playerItem = AVPlayerItem(asset: asset)

                // Необходимо для того, чтобы в HLS потоке мог быть выбран поток с разрешением превышающим разрешение экрана телефона
                playerItem.preferredMaximumResolution = CGSize(width: 3840, height: 2160)

                self?.player?.replaceCurrentItem(with: playerItem)

                if self?.isVisible == true {
                    self?.player?.play()
                }
            }
        }
    }

    func loadVideo() {

        player?.replaceCurrentItem(with: nil)

        loadingAsset?.cancelLoading()
        loadingAsset = nil
        guard let camera = camera else {
            return
        }
        camera.updateURLAndExec { [weak self] urlString in
            guard let self = self, let url = URL(string: urlString) else {
                return
            }
            self.updateSoundButtonVisibility(for: camera.hasSound)
            self.hasSound = camera.hasSound
            self.startToPlay(url)
        }
    }
}
