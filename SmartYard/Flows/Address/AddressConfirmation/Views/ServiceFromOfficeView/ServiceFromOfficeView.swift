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
import MapboxStatic

class ServiceFromOfficeView: PMNibLinkableView {
    
    @IBOutlet private weak var mapImageView: UIImageView!
    // swiftlint:disable:next strict_fileprivate
    @IBOutlet fileprivate weak var doSoButton: BlueButton!
    
    // TODO: ничего не понятно с этим экраном, пусть пока останется так. Это 100% будет переделано
    private let accessToken = "pk.eyJ1IjoibWFwYm94IiwiYSI6ImNqMHFiNXN4ZDAxazMyd253cmt3a2hmN2cifQ.q0ntnAWEdwckfZnT0IEy5A"
    private let url = Bundle.main.url(forResource: "MapPoint", withExtension: "pdf")
    
    func setPreview() {
        guard let mapPointImageUrl = url else {
            return
        }
        
        let markerOverlay = Marker(
            coordinate: CLLocationCoordinate2D(latitude: 54.32881096780029, longitude: 48.38518549809816),
            size: .medium,
            iconName: "cafe"
        )
        
        let camera = SnapshotCamera(
            lookingAtCenter: CLLocationCoordinate2D(
                latitude: 54.32881096780029,
                longitude: 48.38518549809816
            ),
            zoomLevel: 15
        )
        
        let options = SnapshotOptions(
            styleURL: URL(string: "mapbox://styles/mapbox/streets-v9")!,
            camera: camera,
            size: mapImageView.bounds.size
        )
        
        options.overlays.append(markerOverlay)
        
        _ = Snapshot(options: options, accessToken: accessToken).image { [weak self] image, error in
            if let error = error {
                print(error)
                return
            }
            
            self?.mapImageView.image = image
        }
    }
}

extension Reactive where Base: ServiceFromOfficeView {
    
    var doSoButtonTapped: ControlEvent<Void> {
        return base.doSoButton.rx.tap
    }
    
}
