//
//  CameraCollectionViewCell.swift
//  SmartYard
//
//  Created by Александр Попов on 27.01.2024.
//  Copyright © 2024 Sesameware. All rights reserved.
//

import UIKit
import SnapKit
import SmartYardVideoPlayer

final class OnlineCameraFullscreenButton: UIButton {
    var onTap: (() -> Void)?

    init(isFullscreen: Bool) {
        super.init(frame: .zero)
        tintColor = .white
        setImage(SYPlayerConfig.shared.icon(isFullscreen ? .fullscreenExit : .fullscreenEnter), for: .normal)
        imageView?.contentMode = .scaleAspectFit
        contentEdgeInsets = .init(top: 6, left: 6, bottom: 6, right: 6)
        accessibilityLabel = NSLocalizedString(
            isFullscreen ? "camera.fullscreen.exit" : "camera.fullscreen.enter",
            comment: "Camera fullscreen button"
        )
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        onTap?()
    }
}

enum OnlineCameraPreviewRequest {
    static let cacheInterval: TimeInterval = 5 * 60

    static func key(cameraId: CameraID, url: URL) -> String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        components?.fragment = nil
        let stableURL = components?.url?.absoluteString ?? url.absoluteString
        return "online-camera-preview-v2:\(cameraId):\(stableURL)"
    }

    static func source(url: URL) -> ImageSource {
        url.pathExtension.lowercased() == "mp4"
            ? .videoThumbnail(url)
            : .remoteImage(url)
    }
}

final class OnlineCameraPreviewView: UIImageView {
    private enum Configuration {
        static let transitionDuration: TimeInterval = 0.15
    }

    private let imageProvider: ImageProviding = SYImageProvider()
    private var currentCameraId: CameraID?
    private var currentURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFit
        clipsToBounds = true
        backgroundColor = .black
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(cameraId: CameraID, url: URL?) {
        let shouldKeepCurrentImage = currentCameraId == cameraId
            && currentURL == url
            && image != nil
        currentCameraId = cameraId
        currentURL = url

        guard !shouldKeepCurrentImage else { return }

        imageProvider.cancel(on: self)
        image = nil
        alpha = 0

        guard let url else { return }

        let startedAt = Date()
        Logger.logDebug("preview load start id=\(cameraId) type=\(url.pathExtension.lowercased())")
        imageProvider.setImage(
            on: self,
            key: OnlineCameraPreviewRequest.key(cameraId: cameraId, url: url),
            source: OnlineCameraPreviewRequest.source(url: url),
            cachePolicy: .refresh(after: OnlineCameraPreviewRequest.cacheInterval)
        ) { [weak self] loadedImage in
            guard let self,
                  currentCameraId == cameraId,
                  currentURL == url
            else {
                return
            }

            let elapsed = Date().timeIntervalSince(startedAt)
            guard loadedImage != nil else {
                Logger.logWarning(
                    "preview load failed id=\(cameraId) elapsed=\(String(format: "%.3f", elapsed))s"
                )
                return
            }

            Logger.logDebug(
                "preview load finished id=\(cameraId) elapsed=\(String(format: "%.3f", elapsed))s"
            )

            UIView.animate(
                withDuration: UIAccessibility.isReduceMotionEnabled
                    ? 0
                    : Configuration.transitionDuration
            ) {
                self.alpha = 1
            }
        }
    }

    func reset() {
        imageProvider.cancel(on: self)
        currentCameraId = nil
        currentURL = nil
        layer.removeAllAnimations()
        image = nil
        alpha = 0
    }
}

final class CameraViewCell: UICollectionViewCell, PlayerAttachable {
    private let shadowContainerView = UIView()
    private let previewImageView = OnlineCameraPreviewView(frame: .zero)
    private let fullscreenButton = OnlineCameraFullscreenButton(isFullscreen: false)
    let playerContainerView = UIView()

    private var currentCameraId: CameraID?
    private var shadowBounds: CGRect = .zero
    var onRequestFullscreen: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentCameraId = nil
        onRequestFullscreen = nil
        previewImageView.reset()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard shadowBounds != shadowContainerView.bounds else { return }
        shadowBounds = shadowContainerView.bounds
        shadowContainerView.layer.shadowPath = UIBezierPath(roundedRect: shadowBounds, cornerRadius: 12).cgPath
    }

    func configure(with item: CameraViewCellModel) {
        currentCameraId = item.id
        previewImageView.configure(cameraId: item.id, url: item.previewURL)
    }
}

private extension CameraViewCell {
    func configureUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .black
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        shadowContainerView.layer.cornerRadius = 12
        shadowContainerView.layer.masksToBounds = false
        shadowContainerView.layer.shadowColor = UIColor.black.cgColor
        shadowContainerView.layer.shadowOpacity = 0.15
        shadowContainerView.layer.shadowRadius = 8
        shadowContainerView.layer.shadowOffset = CGSize(width: 4, height: 4)

        contentView.addSubview(shadowContainerView)
        shadowContainerView.addSubview(playerContainerView)
        playerContainerView.pinSubview(previewImageView)
        fullscreenButton.onTap = { [weak self] in self?.onRequestFullscreen?() }
        contentView.addSubview(fullscreenButton) { make in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview().inset(10)
            make.size.equalTo(44)
        }

        shadowContainerView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
            $0.height.equalTo(contentView.snp.width).multipliedBy(9.0 / 16.0)
        }

        playerContainerView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
}
