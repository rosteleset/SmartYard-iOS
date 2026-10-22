//
//  HistoryVideoSoundControl.swift
//  SmartYard
//
//  Created by Александр Попов on 12.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import AVFoundation
import UIKit

@MainActor
final class HistoryVideoSoundControl {
    private static let buttonSize: CGFloat = 44

    let button = UIButton(type: .custom)

    private weak var player: AVPlayer?
    private var observer: PlayerAudioAvailabilityObserver?
    private var audioAvailability: PlayerAudioAvailabilityObserver.Availability = .unknown
    private var fallbackHasAudio = false
    private var isSoundOn = false

    init() {
        button.setImage(UIImage(named: "SoundOff")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(UIImage(named: "SoundOn")?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        button.layer.cornerRadius = Self.buttonSize / 2
        button.accessibilityIdentifier = "history.soundToggle"
        button.isHidden = true
    }

    func install(in container: UIView) {
        container.addSubview(button) { make in
            make.size.equalTo(Self.buttonSize)
            make.trailing.bottom.equalToSuperview().inset(12)
        }
    }

    func observe(_ item: AVPlayerItem, in player: AVPlayer, fallbackHasAudio: Bool) {
        self.player = player
        self.fallbackHasAudio = fallbackHasAudio
        observer = PlayerAudioAvailabilityObserver(item: item) { [weak self, weak item] availability in
            guard let self, let item, self.player?.currentItem === item else { return }
            self.audioAvailability = availability
            self.updateSoundState()
        }
        updateSoundState()
    }

    func resetPlayback() {
        observer = nil
        audioAvailability = .unknown
        player = nil
        button.isHidden = true
    }

    func setSoundEnabled(_ isEnabled: Bool) {
        isSoundOn = isEnabled
        updateSoundState()
    }

    private func updateSoundState() {
        guard let player else { return }
        let hasSound = audioAvailability.hasAudio(fallback: fallbackHasAudio)
        let soundEnabled = hasSound && isSoundOn

        if soundEnabled, player.isMuted {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            } catch {
                Logger.logError("Failed to configure event playback audio: \(error)")
            }
        }

        player.isMuted = !soundEnabled
        button.isHidden = !hasSound
        button.isSelected = soundEnabled
        button.accessibilityLabel = soundEnabled ? L10n.History.Event.muteSound : L10n.History.Event.unmuteSound
    }
}
