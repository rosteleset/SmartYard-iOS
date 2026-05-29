//
//  TrackedEventsView.swift
//  SmartYard
//
//  Created by Александр Попов on 29.05.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

final class TrackedEventsView: UIView {
    let fakeNavBar: FakeNavBar = {
        guard let view = Bundle.main.loadNibNamed("FakeNavBar", owner: nil)?.first as? FakeNavBar else {
            return FakeNavBar(frame: .zero)
        }

        return view
    }()
    let addressLabel = UILabel()
    let tableView = UITableView(frame: .zero, style: .plain)
    let addButton = UIButton(type: .system)

    private let backgroundImageView = UIImageView(image: UIImage(named: "MainBackground"))
    private let titleLabel = UILabel()
    private let grayBackgroundView = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let addressContainerView = UIView()
    private let mainContainerView = UIView()
    private let emptyStateLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .gray)
    private var mainContainerTopConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Match AddressSettings: address card overlaps gray background by 24pt, then content starts 8pt below it.
        mainContainerTopConstraint?.constant = addressContainerView.bounds.height - 24 + 8
    }

    func setEmptyStateVisible(_ isVisible: Bool) {
        emptyStateLabel.isHidden = !isVisible
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func setupUI() {
        backgroundColor = .SmartYard.backgroundColor

        backgroundImageView.contentMode = .scaleAspectFill

        titleLabel.text = L10n.Settings.TrackedEvents.title
        titleLabel.font = .SourceSansPro.bold(size: 32)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0

        grayBackgroundView.backgroundColor = .SmartYard.backgroundColor
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        addressContainerView.backgroundColor = .SmartYard.secondBackgroundColor
        addressContainerView.layerCornerRadius = 12
        addressContainerView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)

        addressLabel.font = .SourceSansPro.semibold(size: 18)
        addressLabel.textColor = .SmartYard.semiBlack
        addressLabel.numberOfLines = 0

        mainContainerView.backgroundColor = .clear

        tableView.backgroundColor = .SmartYard.backgroundColor
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.register(TrackedEventCell.self, forCellReuseIdentifier: TrackedEventCell.reuseIdentifier)

        emptyStateLabel.text = L10n.Settings.TrackedEvents.emptyState
        emptyStateLabel.font = .SourceSansPro.regular(size: 16)
        emptyStateLabel.textColor = .SmartYard.gray
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true

        addButton.setTitle(L10n.Common.add, for: .normal)
        addButton.setTitleColor(.SmartYard.blue, for: .normal)
        addButton.tintColor = .SmartYard.blue
        addButton.layerCornerRadius = 12
        addButton.layerBorderWidth = 1
        addButton.layerBorderColor = UIColor.SmartYard.blue
        addButton.titleLabel?.font = .SourceSansPro.semibold(size: 18)

        activityIndicator.hidesWhenStopped = true
    }

    private func setupConstraints() {
        [
            backgroundImageView,
            fakeNavBar,
            titleLabel,
            grayBackgroundView,
            addressContainerView,
            addButton
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        [
            scrollView,
            contentView,
            mainContainerView,
            tableView,
            emptyStateLabel,
            activityIndicator
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        grayBackgroundView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mainContainerView)
        addressContainerView.pinSubview(addressLabel, with: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24))

        [
            tableView,
            emptyStateLabel,
            activityIndicator
        ].forEach {
            mainContainerView.addSubview($0)
        }

        mainContainerTopConstraint = mainContainerView.topAnchor.constraint(
            equalTo: contentView.topAnchor,
            constant: 60
        )
        mainContainerTopConstraint?.priority = .defaultHigh

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            fakeNavBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            fakeNavBar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            fakeNavBar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            fakeNavBar.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 56),
            titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),

            grayBackgroundView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 54),
            grayBackgroundView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            grayBackgroundView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            grayBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            addressContainerView.topAnchor.constraint(equalTo: grayBackgroundView.topAnchor, constant: -24),
            addressContainerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            addressContainerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: grayBackgroundView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: grayBackgroundView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: grayBackgroundView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: grayBackgroundView.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            mainContainerTopConstraint!,
            mainContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            mainContainerView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor, constant: -76),

            addButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 32),
            addButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -32),
            addButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 60),

            tableView.topAnchor.constraint(equalTo: mainContainerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: mainContainerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: mainContainerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -16),

            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: tableView.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: tableView.trailingAnchor, constant: -16),

            activityIndicator.centerXAnchor.constraint(equalTo: mainContainerView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: mainContainerView.centerYAnchor)
        ])
    }
}
