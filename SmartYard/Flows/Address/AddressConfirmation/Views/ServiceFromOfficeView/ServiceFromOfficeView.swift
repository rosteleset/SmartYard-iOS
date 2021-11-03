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
import Mapbox

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
        
        let officesPoints = offices.map { value -> MGLPointAnnotation in
            let point = MGLPointAnnotation()
            point.coordinate = CLLocationCoordinate2D(latitude: value.lat, longitude: value.lon)
            point.title = value.address
            return point
        }
        
        mapView.addAnnotations(officesPoints)
        
        mapView.setCenter(Constants.tambovCoordinates, zoomLevel: 8, animated: true)
    }

}

extension ServiceFromOfficeView: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return nil
    }

    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        guard let mapPointIcon = UIImage(named: "MapPoint") else {
            return nil
        }

        return MGLAnnotationImage(image: mapPointIcon, reuseIdentifier: "MapPoint")
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
