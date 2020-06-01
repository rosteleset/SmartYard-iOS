//
//  YardMapViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import Mapbox
import JGProgressHUD
import RxSwift
import RxCocoa

class YardMapViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var mapView: MGLMapView!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    var loader: JGProgressHUD?
    
    private let viewModel: YardMapViewModel
    
    private let cameraSelectedTrigger = PublishSubject<Int>()
    private let camerasProxy = BehaviorSubject<[CameraObject]>(value: [])
    
    init(viewModel: YardMapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        bind()
    }

    func bind() {
        let input = YardMapViewModel.Input(
            cameraSelected: cameraSelectedTrigger.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.cameras
            .drive(
                onNext: { [weak self] cameras in
                    guard let self = self else {
                        return
                    }
                    
                    self.camerasProxy.onNext(cameras)
                    self.removeAllAnnotations()
                    
                    let pointAnnotations = cameras.map { camera -> MGLPointAnnotation in
                        let point = MGLPointAnnotation()
                        point.coordinate = camera.position
                        return point
                    }
                    
                    self.mapView.addAnnotations(pointAnnotations)
                    
                    self.mapView.showAnnotations(
                        pointAnnotations,
                        edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                        animated: false,
                        completionHandler: nil
                    )
                }
            )
            .disposed(by: disposeBag)
        
        output.address
            .drive(addressLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func removeAllAnnotations() {
        guard let uAnnotations = mapView.annotations else {
            return
        }
        
        mapView.removeAnnotations(uAnnotations)
    }
    
}

extension YardMapViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        guard let cameras = try? self.camerasProxy.value(),
            let camera = (cameras.first { $0.position == annotation.coordinate }) else {
            return nil
        }

        let annotationView = CamerasMapPointView()

        annotationView.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        annotationView.configure(cameraNumber: camera.cameraNumber)

        return annotationView
    }
        
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return false
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotationView: MGLAnnotationView) {
        guard let cameraNumber = (annotationView as? CamerasMapPointView)?.cameraNumber else {
            return
        }
        
        cameraSelectedTrigger.onNext(cameraNumber)
    }
    
}
