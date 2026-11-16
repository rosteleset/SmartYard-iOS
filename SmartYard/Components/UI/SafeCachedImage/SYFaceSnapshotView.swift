//
//  SYFaceSnapshotView.swift
//  SmartYard
//
//  Created by Александр Попов on 16.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import UIKit

final class SYFaceSnapshotView: SafeCachedImageView {
    private var faceInImage: CGRect?
    private var outlineColor: UIColor = .SmartYard.incorrectDataRed

    private lazy var outline: CAShapeLayer = {
        let outline = CAShapeLayer()
        outline.fillColor = nil
        outline.lineWidth = 3
        layer.addSublayer(outline)
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance, action: #selector(outlineAppearanceChanged))
        return outline
    }()

    override var image: UIImage? {
        didSet { setNeedsLayout() }
    }

    func showFace(_ face: CGRect?, isRegistered: Bool) {
        faceInImage = face
        outlineColor = isRegistered ? .SmartYard.darkGreen : .SmartYard.incorrectDataRed
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        outline.frame = bounds
        outline.strokeColor = outlineColor.resolvedColor(with: traitCollection).cgColor
        outline.path = faceFrame().map(Self.cornerPath)
    }

    private func faceFrame() -> CGRect? {
        guard let image, let faceInImage, faceInImage.width > 0, faceInImage.height > 0,
              image.size.width > 0, image.size.height > 0, !bounds.isEmpty else { return nil }
        let pixels = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let scaleX = bounds.width / pixels.width
        let scaleY = bounds.height / pixels.height
        let scale = contentMode == .scaleAspectFill ? max(scaleX, scaleY) : min(scaleX, scaleY)
        let origin = CGPoint(x: (bounds.width - pixels.width * scale) / 2, y: (bounds.height - pixels.height * scale) / 2)
        return faceInImage.applying(.init(a: scale, b: 0, c: 0, d: scale, tx: origin.x, ty: origin.y))
    }

    private static func cornerPath(in frame: CGRect) -> CGPath {
        let length = min(frame.width, frame.height) / 4
        let (left, right, top, bottom) = (frame.minX, frame.maxX, frame.minY, frame.maxY)
        let path = CGMutablePath()
        path.addLines(between: [.init(x: left + length, y: top), .init(x: left, y: top), .init(x: left, y: top + length)])
        path.addLines(between: [.init(x: right - length, y: top), .init(x: right, y: top), .init(x: right, y: top + length)])
        path.addLines(between: [.init(x: left + length, y: bottom), .init(x: left, y: bottom), .init(x: left, y: bottom - length)])
        path.addLines(between: [.init(x: right - length, y: bottom), .init(x: right, y: bottom), .init(x: right, y: bottom - length)])
        return path
    }

    @objc private func outlineAppearanceChanged() { setNeedsLayout() }
}
