//
//  DebugNetworkPanelViewController.swift
//  SmartYard
//
//  Created by Александр Попов on 18.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit

final class DebugNetworkPanelViewController: UIViewController {
    private let controller: DebugNetworkController

    // MARK: - UI

    private let containerView = UIView()

    private let internetControl = UISegmentedControl(
        items: ["Auto", "Offline", "Online"]
    )

    private let backendControl = UISegmentedControl(
        items: ["Auto", "Down", "Up"]
    )

    private let resetButton = UIButton(type: .system)

    // MARK: - Init

    init(controller: DebugNetworkController) {
        self.controller = controller
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        syncFromState()
        bindActions()
    }

    // MARK: - Setup
    private func configureUI() {
        view.backgroundColor = .clear

        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        let internetLabel = makeLabel("Internet")
        let backendLabel = makeLabel("Backend")

        resetButton.setTitle("Reset", for: .normal)
        resetButton.tintColor = .systemRed

        let stack = UIStackView(arrangedSubviews: [
            internetLabel,
            internetControl,
            backendLabel,
            backendControl,
            resetButton
        ])

        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stack)

        NSLayoutConstraint.activate([
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 16),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 220),

            stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])

        // Drag gesture
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        containerView.addGestureRecognizer(pan)
    }

    private func bindActions() {
        internetControl.addTarget(self, action: #selector(internetChanged), for: .valueChanged)
        backendControl.addTarget(self, action: #selector(backendChanged), for: .valueChanged)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
    }

    // MARK: - Sync

    private func syncFromState() {
        switch controller.state.internet {
        case .auto: internetControl.selectedSegmentIndex = 0
        case .offline: internetControl.selectedSegmentIndex = 1
        case .online: internetControl.selectedSegmentIndex = 2
        }

        switch controller.state.backend {
        case .auto: backendControl.selectedSegmentIndex = 0
        case .unavailable: backendControl.selectedSegmentIndex = 1
        case .available: backendControl.selectedSegmentIndex = 2
        }
    }

    // MARK: - Actions

    @objc private func internetChanged() {
        let value: DebugNetworkController.InternetOverride
        switch internetControl.selectedSegmentIndex {
        case 1: value = .offline
        case 2: value = .online
        default: value = .auto
        }
        controller.setInternet(value)
    }

    @objc private func backendChanged() {
        let value: DebugNetworkController.BackendOverride
        switch backendControl.selectedSegmentIndex {
        case 1: value = .unavailable
        case 2: value = .available
        default: value = .auto
        }
        controller.setBackend(value)
    }

    @objc private func resetTapped() {
        controller.reset()
        syncFromState()
    }

    // MARK: - Drag

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        gesture.setTranslation(.zero, in: view)
        containerView.center = CGPoint(
            x: containerView.center.x + translation.x,
            y: containerView.center.y + translation.y
        )
    }

    // MARK: - Helpers

    private func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 14)
        return label
    }
}
