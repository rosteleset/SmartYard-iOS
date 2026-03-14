//
//  ServiceFromOfficeView.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import PMNibLinkableView
import RxSwift
import RxCocoa
import CoreLocation
import MapboxMaps
import UIKit

final class ServiceFromOfficeView: PMNibLinkableView {
    
    private enum MapPointConstants {
        static let mapPointImageName = "MapPoint"
        static let mapPointSpriteName = "MapPointExtendedTapArea"
        static let mapPointMinimumTapSide: CGFloat = 44
    }

    @IBOutlet fileprivate weak var doSoButton: BlueButton!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var instructionsLabel: UILabel!
    private var shownAnnotation: ViewAnnotation?
    private var mapView: MapView!
    
    private var styleURI: StyleURI!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }
    
    fileprivate func configureUI() {
        instructionsLabel.text = L10n.Address.Confirmation.Office.instructions
        doSoButton.setTitle(L10n.Address.Confirmation.Office.iLlDoSoButton, for: .normal)
        let cameraOptions = CameraOptions(
            center: Constants.defaultMapCenterCoordinates,
            zoom: 8,
            bearing: .zero,
            pitch: .zero
        )
        if traitCollection.userInterfaceStyle == .dark {
            styleURI = StyleURI(url: URL(string: "mapbox://styles/mapbox/dark-v11")!)!
        } else {
            styleURI = StyleURI(url: URL(string: "mapbox://styles/mapbox/streets-v11")!)!
        }
        let options = MapInitOptions(
            cameraOptions: cameraOptions,
            styleURI: styleURI
        )
        mapView = MapView(frame: containerView.bounds, mapInitOptions: options)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(mapView)
        containerView.sendSubviewToBack(mapView)
        mapView.alignToView(containerView)
    }
    
    private func createSampleView(withText text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = .black
        label.backgroundColor = .SmartYard.secondBackgroundColor
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.sizeToFit()
        return label
    }
    
    private func showViewAnnotation(with text: String, at coordinate: CLLocationCoordinate2D) {
        if let shownAnnotation = self.shownAnnotation {
            shownAnnotation.remove()
            self.shownAnnotation = nil
        }
        
        let sampleView = createSampleView(withText: text)
        let annotation = ViewAnnotation(coordinate: coordinate, view: sampleView)
        annotation.allowOverlap = false
        annotation.variableAnchors = [ViewAnnotationAnchorConfig(anchor: .top, offsetY: -14)]
        mapView.viewAnnotations.add(annotation)
        
        self.shownAnnotation = annotation
    }

    private func makeMapPointImageWithExpandedTapArea() -> UIImage {
        guard let mapPointImage = UIImage(named: MapPointConstants.mapPointImageName) else {
            assertionFailure("Missing \(MapPointConstants.mapPointImageName) asset")
            return UIImage()
        }

        let expandedSize = CGSize(
            width: max(mapPointImage.size.width, MapPointConstants.mapPointMinimumTapSide),
            height: max(mapPointImage.size.height, MapPointConstants.mapPointMinimumTapSide)
        )
        let renderer = UIGraphicsImageRenderer(size: expandedSize)

        return renderer.image { _ in
            let origin = CGPoint(
                x: (expandedSize.width - mapPointImage.size.width) / 2,
                y: (expandedSize.height - mapPointImage.size.height) / 2
            )
            mapPointImage.draw(at: origin)
        }
    }
    
    func setOffices(offices: [APIOffice]) {
        let annotationManager = self.mapView.annotations.makePointAnnotationManager()
        annotationManager.annotations = []
        let mapPointImage = makeMapPointImageWithExpandedTapArea()
        
        let officesPoints = offices.map { value -> PointAnnotation in
            var point = PointAnnotation(coordinate: CLLocationCoordinate2D(latitude: value.lat, longitude: value.lon))
            point.tapHandler = { [weak self] _ in
                self?.showViewAnnotation(
                    with: value.address,
                    at: CLLocationCoordinate2D(latitude: value.lat, longitude: value.lon)
                )
                return true
            }
            point.image = .init(image: mapPointImage, name: MapPointConstants.mapPointSpriteName)
            point.iconAnchor = .center
            return point
        }
        
        annotationManager.iconAllowOverlap = true
        annotationManager.annotations = officesPoints
        
        let annotationCoordinates = officesPoints
            .map { $0.point.coordinates }
        
        switch annotationCoordinates.withoutDuplicates().count {
        case 1:
            let camera = CameraOptions(center: annotationCoordinates.first!, zoom: 17)
            self.mapView.mapboxMap.setCamera(to: camera)
        case let count where count > 1:
            let camera = self.mapView.mapboxMap.camera(
                for: annotationCoordinates,
                padding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                bearing: .none,
                pitch: .none
            )
            self.mapView.mapboxMap.setCamera(to: camera)
        default:
            let camera = CameraOptions(center: Constants.defaultMapCenterCoordinates, zoom: 17)
            self.mapView.mapboxMap.setCamera(to: camera)
        }
    }
}

extension Reactive where Base: ServiceFromOfficeView {
    
    var doSoButtonTapped: ControlEvent<Void> {
        return base.doSoButton.rx.tap
    }
    
}

extension ServiceFromOfficeView {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateMapStyle()
    }
    
    func updateMapStyle() {
        if traitCollection.userInterfaceStyle == .dark {
            styleURI = StyleURI(url: URL(string: "mapbox://styles/mapbox/dark-v11")!)!
        } else {
            styleURI = StyleURI(url: URL(string: "mapbox://styles/mapbox/streets-v11")!)!
        }
        mapView.mapboxMap.loadStyle(styleURI)
    }

}
