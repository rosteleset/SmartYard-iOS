//
//  CamerasMapPointView.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import MapboxMaps
import SnapKit

final class CamerasMapPointView: UIView {

    private(set) var cameraNumber: Int?
    private var tapCallback: (() -> Void)?

    private let cameraImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "CameraIcon")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.SmartYard.gray
        return imageView
    }()

    private let cameraNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.SourceSansPro.semibold(size: 14)
        label.textColor = UIColor.SmartYard.blue
        label.textAlignment = .center
        return label
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    @objc func handleTap(sender: UITapGestureRecognizer) {
        self.tapCallback?()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(cameraNumber: Int, _ onTap: @escaping (() -> Void)) {
        self.cameraNumber = cameraNumber
        self.tapCallback = onTap
        self.cameraNumberLabel.text = "\(cameraNumber)"
    }
}

private extension CamerasMapPointView {
    func setupUI() {
        backgroundColor = .SmartYard.secondBackgroundColor

        snp.makeConstraints { make in
            make.size.equalTo(40)
        }

        addSubview(cameraImageView) { make in
            make.width.equalTo(15)
            make.height.equalTo(13)
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
        }

        addSubview(cameraNumberLabel) { make in
            make.height.equalTo(15)
            make.top.equalTo(cameraImageView.snp.bottom)
            make.centerX.equalToSuperview()
        }

        clipsToBounds = true
        layerCornerRadius = 20

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.addGestureRecognizer(tapGesture)
    }
}
