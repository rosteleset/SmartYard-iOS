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
}

final class AddressesListDoorPreviewCell: CustomBorderCollectionViewCell, HasDisposeBag {

    private let previewImageView = UIImageView()
    private let overlayView = LinearGradientView(frame: .zero)
    private let placeholderIconView = UIImageView(image: UIImage(named: "CameraIcon")?.withRenderingMode(.alwaysTemplate))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let openButton = SmartYardActionModeButton()
    private let streamIndicatorView = UIView()

    private let imageProvider: ImageProviding = SYImageProvider()
    private var previewSource: AddressesListDoorPreviewSource?
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
        previewSource = nil
        previewRefreshDisposable?.dispose()
        previewRefreshDisposable = nil
        imageProvider.cancel(on: previewImageView)
    }

    func configure(
        title: String,
        subtitle: String?,
        previewSource: AddressesListDoorPreviewSource?,
        hasCamera: Bool,
        isOpened: Bool
    ) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle?.isEmpty ?? true
        openButton.isOn = isOpened
        streamIndicatorView.isHidden = !hasCamera

        self.previewSource = previewSource
        applyPreview(previewSource)
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

        overlayView.colors = [
            UIColor(white: 0.18, alpha: 0.08),
            UIColor(white: 0.18, alpha: 0.64)
        ]
        overlayView.gradientLayer.locations = [0.0, 1.0]

        placeholderIconView.tintColor = UIColor.white.withAlphaComponent(0.82)
        placeholderIconView.contentMode = .scaleAspectFit

        titleLabel.font = UIFont.SourceSansPro.semibold(size: 18)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        subtitleLabel.font = UIFont.SourceSansPro.regular(size: 13)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.numberOfLines = 1

        openButton.mode = .open
        openButton.visualStyle = .overImage

        streamIndicatorView.backgroundColor = UIColor.SmartYard.blue
        streamIndicatorView.layer.cornerRadius = 4
    }

    // MARK: - Setup Constraints

    func setupConstraints() {
        contentView.pinSubview(previewImageView)
        contentView.pinSubview(overlayView)

        contentView.addSubview(placeholderIconView) { make in
            make.center.equalToSuperview()
            make.size.equalTo(36)
        }

        streamIndicatorView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        streamIndicatorView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        openButton.widthAnchor.constraint(equalToConstant: 84).isActive = true
        openButton.heightAnchor.constraint(equalToConstant: 36).isActive = true

        let streamIndicatorColumn = UIStackView.vertical(alignment: .leading)
        streamIndicatorColumn.add {
            VSpacer(4)
            streamIndicatorView
            VSpacer()
        }
        streamIndicatorColumn.widthAnchor.constraint(equalToConstant: 8).isActive = true

        let topStackView = UIStackView.horizontal(alignment: .top).add {
            streamIndicatorColumn
            HSpacer()
            openButton
        }

        let labelsStackView = UIStackView.vertical(spacing: 4).add {
            titleLabel
            subtitleLabel
        }

        let contentStackView = UIStackView.vertical().add {
            topStackView
            VSpacer()
            labelsStackView
        }

        contentView.pinSubview(
            contentStackView,
            with: UIEdgeInsets(top: 16, left: 20, bottom: 18, right: 16)
        )
    }

    func applyPreview(
        _ previewSource: AddressesListDoorPreviewSource?,
        keepingCurrentImage: Bool = false
    ) {
        if !keepingCurrentImage {
            previewImageView.image = nil
            placeholderIconView.isHidden = false
        }
        imageProvider.cancel(on: previewImageView)

        guard
            let previewSource,
            let url = URL(string: previewSource.urlString)
        else {
            return
        }

        let source: ImageSource = {
            switch previewSource {
            case .image: return .remoteImage(url)
            case .video: return .videoThumbnail(url)
            }
        }()

        imageProvider.setImage(
            on: previewImageView,
            key: "\(EntrancePreviewRefresh.cacheKeyPrefix):\(previewSource.urlString)",
            source: source,
            cachePolicy: .refresh(after: EntrancePreviewRefresh.interval)
        ) { [weak self] image in
            guard let self, self.previewSource == previewSource else {
                return
            }

            self.placeholderIconView.isHidden = image != nil || self.previewImageView.image != nil
        }
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
