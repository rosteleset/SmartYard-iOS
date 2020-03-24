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

class ServiceFromOfficeView: PMNibLinkableView {
    
    @IBOutlet fileprivate weak var doSoButton: BlueButton!
    
    private let accessToken = "pk.eyJ1IjoibWFwYm94IiwiYSI6ImNqMHFiNXN4ZDAxazMyd253cmt3a2hmN2cifQ.q0ntnAWEdwckfZnT0IEy5A"
    private let url = Bundle.main.url(forResource: "MapPoint", withExtension: "pdf")
    
    
}

extension Reactive where Base: ServiceFromOfficeView {
    
    var doSoButtonTapped: ControlEvent<Void> {
        return base.doSoButton.rx.tap
    }
    
}
