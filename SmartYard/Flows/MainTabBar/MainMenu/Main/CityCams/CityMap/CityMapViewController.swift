//
//  CityMapViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 14.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import Mapbox
import JGProgressHUD
import RxSwift
import RxCocoa

class CameraAnnotation: MGLPointAnnotation {
    var cameraNumber: Int?
}
class CityMapViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var mapView: MGLMapView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    var loader: JGProgressHUD?
    
    private let viewModel: CityMapViewModel
    
    private let cameraSelectedTrigger = PublishSubject<Int>()
    private let camerasProxy = BehaviorSubject<[CityCameraObject]>(value: [])
    
    init(viewModel: CityMapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func configureView() {
        fakeNavBar.setText("Меню")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        mapView.delegate = self
        bind()
    }
    
    func bind() {
        let input = CityMapViewModel.Input(
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
                    
                    let pointAnnotations = cameras.map { camera -> CameraAnnotation in
                        let point = CameraAnnotation()
                        point.coordinate = camera.position
                        point.cameraNumber = camera.cameraNumber
                        return point
                    }
                    
                    self.mapView.addAnnotations(pointAnnotations)
                    
                    let differentCoordinatesCount = pointAnnotations
                        .map { $0.coordinate }
                        .withoutDuplicates()
                        .count
                    
                    switch differentCoordinatesCount {
                    case 1:
                        self.mapView.setCenter(pointAnnotations[0].coordinate, zoomLevel: 17, animated: false)
                        
                    case let count where count > 1:
                        self.mapView.showAnnotations(
                            pointAnnotations,
                            edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                            animated: false,
                            completionHandler: nil
                        )
                        
                    default: break
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    guard let self = self else {
                        return
                    }
                    self.updateLoader(isEnabled: isLoading, detailText: nil, loaderContainer: self.mapView)
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

extension CityMapViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        guard let cameras = try? self.camerasProxy.value(),
              let annotation = annotation as? CameraAnnotation,
              let camera = (cameras.first { $0.cameraNumber == annotation.cameraNumber }) else {
            return nil
        }

        let annotationView = CityCamerasMapPointView()

        annotationView.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        annotationView.configure(cameraNumber: camera.cameraNumber)

        return annotationView
    }
        
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return false
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotationView: MGLAnnotationView) {
        guard let cameraNumber = (annotationView as? CityCamerasMapPointView)?.cameraNumber else {
            return
        }
        
        cameraSelectedTrigger.onNext(cameraNumber)
    }
    
}
