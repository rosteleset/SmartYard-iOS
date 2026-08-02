//
//  WhatsNew.swift
//  SmartYard
//
//  Created by Александр Попов on 02.08.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import SnapKit
import UIKit

struct WhatsNewPage {
    let title: String
    let message: String
    let imageName: String?
    let systemImageName: String

    init(
        title: String,
        message: String,
        imageName: String? = nil,
        systemImageName: String
    ) {
        self.title = title
        self.message = message
        self.imageName = imageName
        self.systemImageName = systemImageName
    }
}

struct WhatsNewRelease {
    let version: String
    let pages: [WhatsNewPage]
}

enum WhatsNewCatalog {
    /// Update this value and the pages below while preparing each release.
    private static let releaseVersion = "1.14.12"

    static var isForcedForDebug: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }

    private static var isAvailableInCurrentBuild: Bool {
        AppMetadata.shortVersion == releaseVersion || isForcedForDebug
    }

    static var currentRelease: WhatsNewRelease? {
        guard isAvailableInCurrentBuild else {
            return nil
        }

        return WhatsNewRelease(
            version: releaseVersion,
            pages: [
                WhatsNewPage(
                    title: L10n.WhatsNew.Language.title,
                    message: L10n.WhatsNew.Language.message,
                    systemImageName: "globe"
                ),
                WhatsNewPage(
                    title: L10n.WhatsNew.CameraSwipe.title,
                    message: L10n.WhatsNew.CameraSwipe.message,
                    systemImageName: "rectangle.stack.fill"
                ),
                WhatsNewPage(
                    title: L10n.WhatsNew.EntrancePreviews.title,
                    message: L10n.WhatsNew.EntrancePreviews.message,
                    systemImageName: "camera.fill"
                )
            ]
        )
    }
}

enum WhatsNewPresentationStore {
    private static let lastPresentedVersionKey = "whatsNew.lastPresentedVersion"

    static func prepareForLaunch(isFirstAppLaunch: Bool) {
        guard isFirstAppLaunch, let version = AppMetadata.shortVersion else {
            return
        }

        UserDefaults.standard.set(version, forKey: lastPresentedVersionKey)
    }

    static func releaseToPresent() -> WhatsNewRelease? {
        guard let release = WhatsNewCatalog.currentRelease else {
            return nil
        }

        guard !WhatsNewCatalog.isForcedForDebug else {
            return release
        }

        let lastPresentedVersion = UserDefaults.standard.string(forKey: lastPresentedVersionKey)
        return lastPresentedVersion == release.version ? nil : release
    }

    static func markPresented(version: String) {
        UserDefaults.standard.set(version, forKey: lastPresentedVersionKey)
    }
}

// swiftlint:disable:next file_types_order
final class WhatsNewModalViewContent: UIView {
    private let release: WhatsNewRelease
    private let dismissCallback: () -> Void

    private let scrollView = IntrinsicHeightPagingScrollView()
    private let pageStackView = UIStackView.horizontal()
    private let pageControl = UIPageControl()
    private let actionButton = BlueButton()

    init(release: WhatsNewRelease, dismissCallback: @escaping () -> Void) {
        self.release = release
        self.dismissCallback = dismissCallback
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        updateControls(for: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - setupUI

    private func setupUI() {
        backgroundColor = .SmartYard.grayBorder

        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = release.pages.count > 1
        scrollView.alwaysBounceVertical = false
        scrollView.isDirectionalLockEnabled = true
        scrollView.semanticContentAttribute = .forceLeftToRight
        scrollView.accessibilityLabel = L10n.WhatsNew.accessibilityPages
        pageStackView.semanticContentAttribute = .forceLeftToRight

        pageControl.numberOfPages = release.pages.count
        pageControl.currentPageIndicatorTintColor = .SmartYard.blue
        pageControl.pageIndicatorTintColor = UIColor.SmartYard.gray.withAlphaComponent(0.3)
        pageControl.hidesForSinglePage = true
        pageControl.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)

        actionButton.titleLabel?.font = .SourceSansPro.semibold(size: 16)
        actionButton.setTitleColor(.SmartYard.secondBackgroundColor, for: .normal)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)

        release.pages.forEach { page in
            let pageView = WhatsNewPageView(page: page)
            pageStackView.addArrangedSubview(pageView)
        }
    }

    // MARK: - setupConstraints

    private func setupConstraints() {
        let titleLabel = UILabel.make(
            .whatsNewHeader,
            text: String(format: L10n.WhatsNew.titleFormat, release.version)
        )

        scrollView.addSubview(pageStackView) { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
        }

        pageStackView.arrangedSubviews.forEach { pageView in
            pageView.snp.makeConstraints { make in
                make.width.equalTo(scrollView.frameLayoutGuide)
            }
        }

        let stackView = UIStackView.vertical().add {
            titleLabel
            VSpacer(20)
            scrollView
            VSpacer(8)
            pageControl
            VSpacer(20)
            actionButton
        }

        actionButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }

        pinSubview(stackView, with: .init(inset: 24))
    }

    @objc private func pageControlChanged() {
        showPage(pageControl.currentPage, animated: true)
    }

    @objc private func actionButtonTapped() {
        let nextPage = pageControl.currentPage + 1

        guard nextPage < release.pages.count else {
            dismissCallback()
            return
        }

        showPage(nextPage, animated: true)
    }

    private func showPage(_ page: Int, animated: Bool) {
        scrollView.setContentOffset(
            CGPoint(x: CGFloat(page) * scrollView.bounds.width, y: 0),
            animated: animated
        )
        updateControls(for: page)
    }

    private func updateControls(for page: Int) {
        pageControl.currentPage = page
        let isLastPage = page == release.pages.count - 1
        let title = isLastPage ? L10n.WhatsNew.done : L10n.WhatsNew.next
        actionButton.setTitle(title, for: .normal)
        actionButton.accessibilityLabel = title
    }
}

private final class WhatsNewPageView: UIView {
    private let page: WhatsNewPage

    init(page: WhatsNewPage) {
        self.page = page
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - setupUI

    private func setupUI() {
        isAccessibilityElement = true
        accessibilityLabel = "\(page.title). \(page.message)"
    }

    // MARK: - setupConstraints

    private func setupConstraints() {
        let imageContainer = UIView()
        imageContainer.backgroundColor = UIColor.SmartYard.blue.withAlphaComponent(0.12)
        imageContainer.layer.cornerRadius = 24

        let imageView = UIImageView()
        imageView.tintColor = .SmartYard.blue
        if let imageName = page.imageName, let image = UIImage(named: imageName) {
            imageView.image = image
            imageView.contentMode = .scaleAspectFit
            imageContainer.pinSubview(imageView, with: .init(inset: 12))
        } else {
            imageView.image = UIImage(
                systemName: page.systemImageName,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 56, weight: .semibold)
            )
            imageContainer.addSubview(imageView) { make in
                make.center.equalToSuperview()
                make.width.height.lessThanOrEqualTo(72)
            }
        }
        let titleLabel = UILabel.make(.whatsNewPageTitle, text: page.title)
        let messageLabel = UILabel.make(.whatsNewPageMessage, text: page.message)

        let stackView = UIStackView.vertical(spacing: 12).add {
            imageContainer
            titleLabel
            messageLabel
        }

        imageContainer.snp.makeConstraints { make in
            make.height.equalTo(imageContainer.snp.width)
                .multipliedBy(0.36)
                .priority(.high)
            make.height.lessThanOrEqualTo(160)
        }

        pinSubview(stackView, with: .init(top: 0, left: 8, bottom: 0, right: 8))
    }
}

private final class IntrinsicHeightPagingScrollView: UIScrollView {
    override var contentSize: CGSize {
        didSet {
            guard abs(contentSize.height - oldValue.height) > 0.5 else { return }
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: max(contentSize.height, 1)
        )
    }
}

extension WhatsNewModalViewContent: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }

        let page = Int((scrollView.contentOffset.x / scrollView.bounds.width).rounded())
        let validPage = min(max(page, 0), max(release.pages.count - 1, 0))
        updateControls(for: validPage)
    }
}

private extension LabelConfig {
    static let whatsNewHeader = LabelConfig(
        font: .SourceSansPro.bold(size: 24),
        color: .SmartYard.semiBlack,
        alignment: .center,
        numberOfLines: 0,
        lineBreakMode: .byWordWrapping,
        adjustsFontSizeToFitWidth: false,
        minimumScaleFactor: 0
    )

    static let whatsNewPageTitle = LabelConfig(
        font: .SourceSansPro.semibold(size: 20),
        color: .SmartYard.semiBlack,
        alignment: .center,
        numberOfLines: 0,
        lineBreakMode: .byWordWrapping,
        adjustsFontSizeToFitWidth: false,
        minimumScaleFactor: 0
    )

    static let whatsNewPageMessage = LabelConfig(
        font: .SourceSansPro.regular(size: 15),
        color: .SmartYard.semiBlack,
        alignment: .center,
        numberOfLines: 0,
        lineBreakMode: .byWordWrapping,
        adjustsFontSizeToFitWidth: false,
        minimumScaleFactor: 0
    )
}
