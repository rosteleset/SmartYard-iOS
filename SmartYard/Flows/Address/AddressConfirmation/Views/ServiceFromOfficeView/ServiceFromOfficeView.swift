//
//  ServiceFromOfficeView.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import PMNibLinkableView
import RxSwift
import RxCocoa
import CoreLocation
import Mapbox

class CustomPointAnnotation: MGLPointAnnotation {
    
    var willUseImage: Bool = true
    
}

class ServiceFromOfficeView: PMNibLinkableView {
    
    @IBOutlet fileprivate weak var doSoButton: BlueButton!
    @IBOutlet private weak var mapView: MGLMapView!

    override func awakeFromNib() {
        super.awakeFromNib()
        mapView.delegate = self
    }
    
    func setOffices(offices: [APIOffice]) {
        if let annotations = mapView.annotations {
            mapView.removeAnnotations(annotations)
        }
        
        var officesPoints = [CustomPointAnnotation]()
        
        offices.forEach {
            let point = CustomPointAnnotation()
            point.coordinate = CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)
            point.title = $0.address
            
            officesPoints.append(point)
        }
        
        mapView.addAnnotations(officesPoints)
        
        mapView.setCenter(Constants.tambovCoordinates, animated: true)
        mapView.setZoomLevel(8, animated: true)
    }

}

extension ServiceFromOfficeView: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return nil
    }

    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "MapPoint")
        
        if annotationImage == nil {
            annotationImage = MGLAnnotationImage(image: UIImage(named: "MapPoint")!, reuseIdentifier: "MapPoint")
        }
        
        return annotationImage
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
}

extension Reactive where Base: ServiceFromOfficeView {
    
    var doSoButtonTapped: ControlEvent<Void> {
        return base.doSoButton.rx.tap
    }
    
}
