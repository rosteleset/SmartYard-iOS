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

class ServiceFromOfficeView: PMNibLinkableView {
    
    @IBOutlet fileprivate weak var doSoButton: BlueButton!
    @IBOutlet private weak var mapView: MapView!
    private var shownAnnotationView: UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
        if let shownView = self.shownAnnotationView {
            mapView.viewAnnotations.remove(shownView)
            self.shownAnnotationView = nil
        }
        
        let sampleView = createSampleView(withText: text)
        
        let options = ViewAnnotationOptions(
            geometry: Point(coordinate),
            width: sampleView.bounds.width + 20,
            height: sampleView.bounds.height,
            allowOverlap: false,
            anchor: .top,
            offsetY: -14
        )
        
        try? mapView.viewAnnotations.add(sampleView, options: options)
        self.shownAnnotationView = sampleView
    }
    
    func setOffices(offices: [APIOffice]) {
        let annotationManager = self.mapView.annotations.makePointAnnotationManager()
        annotationManager.delegate = self
        annotationManager.annotations = []
        
        let officesPoints = offices.map { value -> PointAnnotation in
            var point = PointAnnotation(coordinate: CLLocationCoordinate2D(latitude: value.lat, longitude: value.lon))
            point.userInfo = ["LabelText": value.address]
            point.image = .init(image: UIImage(named: "MapPoint")!, name: "MapPoint")
            point.iconAnchor = .center
            return point
        }
        
        annotationManager.iconAllowOverlap = true
        annotationManager.annotations = officesPoints
        let cameraOptions = CameraOptions(center: Constants.tambovCoordinates, zoom: 8)
        self.mapView.mapboxMap.setCamera(to: cameraOptions)
    }
}

extension ServiceFromOfficeView: AnnotationInteractionDelegate {
    func annotationManager(_ manager: AnnotationManager,
                           didDetectTappedAnnotations annotations: [Annotation]) {
        guard let annotation = annotations.first as? PointAnnotation,
            let labelText = annotation.userInfo?["LabelText"] as? String else {
            return
        }
        showViewAnnotation(with: labelText, at: annotation.point.coordinates)
    }

}

extension Reactive where Base: ServiceFromOfficeView {
    
    var doSoButtonTapped: ControlEvent<Void> {
        return base.doSoButton.rx.tap
    }
    
}
