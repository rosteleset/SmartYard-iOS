//
//  AddressesListDoorPreviewCell.swift
//  SmartYard
//
//  Created by Александр Попов on 21.04.2026.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

private enum EntrancePreviewRefresh {
    static let interval: TimeInterval = 5 * 60
    static let cacheKeyPrefix = "entrance-preview-v2"
    static let transitionDuration: TimeInterval = 0.2
}

private enum EntrancePreviewPlaceholder {
    case loading
    case failed
    case noSource

    var image: UIImage? {
        let imageName: String
        switch self {
        case .loading: imageName = "CameraIcon"
        case .failed: imageName = "CameraErrorIcon"
        case .noSource: imageName = "CameraUnavailableIcon"
        }
        return UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
    }
}

final class AddressesListDoorPreviewCell: CustomBorderCollectionViewCell, HasDisposeBag {

    private let previewImageView = UIImageView()
    private let pendingPreviewImageView = UIImageView()
    private let placeholderIconView = UIImageView(image: EntrancePreviewPlaceholder.loading.image)
    private let entranceIconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let openButton = SmartYardActionModeButton()
    private let bottomScrimStackView = UIStackView.horizontal(
        paddings: NSDirectionalEdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 16),
        spacing: 15,
        alignment: .center
    )

    private let imageProvider: ImageProviding = SYImageProvider()
    private var previewSource: AddressesListDoorPreviewSource?
    private var previewRequestID: UUID?
    private var previewRefreshDisposable: Disposable?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    deinit {
        previewRefreshDisposable?.dispose()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.layer.cornerRadius = layer.cornerRadius
        contentView.layer.maskedCorners = layer.maskedCorners
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        resetDisposeBag()
        previewRefreshDisposable?.dispose()
        previewRefreshDisposable = nil
        previewRequestID = nil
        imageProvider.cancel(on: pendingPreviewImageView)
        resetPendingPreview()
    }

    func configure(
        title: String,
        subtitle: String?,
        iconImageName: String?,
        previewSource: AddressesListDoorPreviewSource?,
        isOpened: Bool
    ) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle?.isEmpty ?? true
        entranceIconView.image = UIImage(named: iconImageName ?? "HouseIcon")?
            .withRenderingMode(.alwaysTemplate)
        openButton.isOn = isOpened

        let shouldKeepCurrentImage = self.previewSource == previewSource
            && previewImageView.image != nil
        self.previewSource = previewSource
        applyPreview(previewSource, keepingCurrentImage: shouldKeepCurrentImage)
        startPreviewRefreshing()
    }

    func bind(with outerSubject: PublishSubject<Void>) {
        openButton.rx.tap
            .bind(to: outerSubject)
            .disposed(by: disposeBag)
    }
}

private extension AddressesListDoorPreviewCell {
    func configureUI() {
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup UI

    func setupUI() {
        backgroundColor = .SmartYard.secondBackgroundColor
        contentView.backgroundColor = .SmartYard.secondBackgroundColor
        contentView.clipsToBounds = true

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.backgroundColor = .SmartYard.grayBorder

        pendingPreviewImageView.contentMode = .scaleAspectFill
        pendingPreviewImageView.clipsToBounds = true
        pendingPreviewImageView.alpha = 0

        placeholderIconView.tintColor = UIColor.white.withAlphaComponent(0.82)
        placeholderIconView.contentMode = .scaleAspectFit

        entranceIconView.tintColor = .SmartYard.mediaOverlaySecondary
        entranceIconView.contentMode = .scaleAspectFit

        titleLabel.font = UIFont.SourceSansPro.semibold(size: 18)
        titleLabel.textColor = .SmartYard.mediaOverlayPrimary
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.font = UIFont.SourceSansPro.regular(size: 13)
        subtitleLabel.textColor = .SmartYard.mediaOverlaySecondary
        subtitleLabel.numberOfLines = 1

        openButton.mode = .open
        openButton.visualStyle = .overImage

        bottomScrimStackView.addBackground(color: UIColor.black.withAlphaComponent(0.4))
    }

    // MARK: - Setup Constraints

    func setupConstraints() {
        contentView.pinSubview(previewImageView)
        contentView.pinSubview(pendingPreviewImageView)

        contentView.addSubview(placeholderIconView) { make in
            make.center.equalToSuperview()
            make.size.equalTo(36)
        }

        let labelsStackView = UIStackView.vertical(spacing: 2).add {
            titleLabel
            subtitleLabel
        }
        labelsStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        bottomScrimStackView.add {
            entranceIconView
            labelsStackView
            HSpacer()
            openButton
        }

        entranceIconView.snp.makeConstraints { make in
            make.size.equalTo(30)
        }

        openButton.snp.makeConstraints { make in
            make.width.equalTo(84)
            make.height.equalTo(36)
        }

        contentView.addSubview(bottomScrimStackView) { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func applyPreview(
        _ previewSource: AddressesListDoorPreviewSource?,
        keepingCurrentImage: Bool = false
    ) {
        let requestID = UUID()
        previewRequestID = requestID
        imageProvider.cancel(on: pendingPreviewImageView)
        resetPendingPreview()

        if !keepingCurrentImage {
            previewImageView.image = nil
        }

        guard let previewSource else {
            updatePlaceholder(.noSource)
            return
        }

        guard let url = URL(string: previewSource.urlString),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              url.host?.isEmpty == false
        else {
            updatePlaceholder(.failed)
            return
        }

        updatePlaceholder(.loading)

        let source: ImageSource = {
            switch previewSource {
            case .image: return .remoteImage(url)
            case .video: return .videoThumbnail(url)
            }
        }()

        imageProvider.setImage(
            on: pendingPreviewImageView,
            key: "\(EntrancePreviewRefresh.cacheKeyPrefix):\(previewSource.urlString)",
            source: source,
            cachePolicy: .refresh(after: EntrancePreviewRefresh.interval)
        ) { [weak self] image in
            guard let self, self.previewRequestID == requestID else {
                return
            }

            guard let image else {
                self.updatePlaceholder(.failed)
                return
            }

            self.showPreviewImage(image, requestID: requestID)
        }
    }

    func showPreviewImage(_ image: UIImage, requestID: UUID) {
        UIView.animate(
            withDuration: UIAccessibility.isReduceMotionEnabled
                ? 0
                : EntrancePreviewRefresh.transitionDuration
        ) {
            self.pendingPreviewImageView.alpha = 1
            self.placeholderIconView.alpha = 0
        } completion: { [weak self] finished in
            guard let self, finished, self.previewRequestID == requestID else {
                return
            }

            self.previewImageView.image = image
            self.placeholderIconView.isHidden = true
            self.resetPendingPreview()
        }
    }

    func updatePlaceholder(_ state: EntrancePreviewPlaceholder) {
        placeholderIconView.image = state.image
        placeholderIconView.isHidden = previewImageView.image != nil
    }

    func resetPendingPreview() {
        pendingPreviewImageView.layer.removeAllAnimations()
        pendingPreviewImageView.alpha = 0
        pendingPreviewImageView.image = nil
        placeholderIconView.layer.removeAllAnimations()
        placeholderIconView.alpha = 1
    }

    func startPreviewRefreshing() {
        previewRefreshDisposable?.dispose()

        guard previewSource != nil else {
            previewRefreshDisposable = nil
            return
        }

        let periodicRefresh = Observable<Int>
            .interval(
                .seconds(Int(EntrancePreviewRefresh.interval)),
                scheduler: MainScheduler.instance
            )
            .mapToVoid()

        let foregroundRefresh = NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .mapToVoid()

        previewRefreshDisposable = Observable
            .merge(periodicRefresh, foregroundRefresh)
            .subscribe(with: self) { owner, _ in
                owner.applyPreview(owner.previewSource, keepingCurrentImage: true)
            }
    }

}
