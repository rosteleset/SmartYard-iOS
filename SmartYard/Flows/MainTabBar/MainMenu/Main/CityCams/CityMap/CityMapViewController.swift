//
//  CityMapViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 14.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import MapboxMaps
import JGProgressHUD
import RxSwift
import RxCocoa

class CityMapViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var mapView: MapView!
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
        bind()
    }
    
    fileprivate func updateAnnotations(_ annotationManager: PointAnnotationManager, _ cameras: [CityCameraObject]) {
        annotationManager.annotations = []
        
        let points = cameras.map { camera -> PointAnnotation in
            var point = PointAnnotation(coordinate: camera.position)
            point.userInfo = ["camera": camera]
            point.image = .init(
                image: (UIImage(named: "CityCam")?.withRenderingMode(.alwaysOriginal))!,
                name: "MapPoint"
            )
            point.iconAnchor = .center
            return point
        }
        
        annotationManager.iconAllowOverlap = true
        annotationManager.annotations = points
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
                    let annotationManager = self.mapView.annotations.makePointAnnotationManager()
                    annotationManager.delegate = self
                    
                    self.updateAnnotations(annotationManager, cameras)
                    
                    let annotationCoordinates = cameras
                        .map { $0.position }
                    
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
}

extension CityMapViewController: AnnotationInteractionDelegate {
    func annotationManager(
        _ manager: AnnotationManager,
        didDetectTappedAnnotations annotations: [Annotation]
    ) {
        guard let annotation = annotations.first as? PointAnnotation,
              let camera = annotation.userInfo?["camera"] as? CityCameraObject else {
            return
        }
        cameraSelectedTrigger.onNext(camera.cameraNumber)
    }

}
