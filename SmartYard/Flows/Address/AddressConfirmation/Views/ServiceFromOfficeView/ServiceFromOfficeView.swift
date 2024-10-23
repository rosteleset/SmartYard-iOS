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
    
    @IBOutlet fileprivate weak var doSoButton: BlueButton!
    @IBOutlet private weak var containerView: UIView!
    private var shownAnnotation: ViewAnnotation?
    private var mapView: MapView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureMapBox()
    }
    
    fileprivate func configureMapBox() {
        let cameraOptions = CameraOptions(
            center: Constants.defaultMapCenterCoordinates,
            zoom: 8,
            bearing: .zero,
            pitch: .zero
        )
        let options = MapInitOptions(
            cameraOptions: cameraOptions,
            styleURI: StyleURI(url: URL(string: "mapbox://styles/mapbox/streets-v11")!)
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
        label.backgroundColor = .white
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
    
    func setOffices(offices: [APIOffice]) {
        let annotationManager = self.mapView.annotations.makePointAnnotationManager()
        annotationManager.annotations = []
        
        let officesPoints = offices.map { value -> PointAnnotation in
            var point = PointAnnotation(coordinate: CLLocationCoordinate2D(latitude: value.lat, longitude: value.lon))
            point.tapHandler = { [weak self] _ in
                self?.showViewAnnotation(
                    with: value.address,
                    at: CLLocationCoordinate2D(latitude: value.lat, longitude: value.lon)
                )
                return true
            }
            point.image = .init(image: UIImage(named: "MapPoint")!, name: "MapPoint")
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
