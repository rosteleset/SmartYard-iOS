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
    
    private var offices = [APIOffice]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mapView.delegate = self
    }
    
    func setOffices(offices: [APIOffice]) {
        self.offices = offices

        var officesPoints = [CustomPointAnnotation]()
        
        self.offices.forEach {
            let point = CustomPointAnnotation()
            point.coordinate = CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)
            point.title = $0.address
            
            officesPoints.append(point)
        }
        
        mapView.addAnnotations(officesPoints)
    }

}

extension ServiceFromOfficeView: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        if let castAnnotation = annotation as? CustomPointAnnotation {
            if castAnnotation.willUseImage {
                return nil
            }
        }
        
        let reuseIdentifier = "reusableDotView"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            annotationView?.layer.cornerRadius = (annotationView?.frame.size.width)! / 2
            annotationView?.layer.borderWidth = 4.0
            annotationView?.layer.borderColor = UIColor.white.cgColor
            annotationView?.backgroundColor = UIColor(red: 0.03, green: 0.80, blue: 0.69, alpha: 1.0)
        }
        
        return annotationView
    }

    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        if let castAnnotation = annotation as? CustomPointAnnotation {
            if !castAnnotation.willUseImage {
                return nil
            }
        }
    
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
