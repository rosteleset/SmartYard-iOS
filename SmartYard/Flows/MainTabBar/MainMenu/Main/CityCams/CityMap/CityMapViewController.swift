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

final class CityMapViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var headerView: HeaderView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    private var mapView: MapView!
    
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
    
    fileprivate func configureUI() {
        fakeNavBar.setText(L10n.Tab.menu)

        headerView.setText(L10n.Camera.City.publicCamerasTitle)
    }
    
    fileprivate func configureMapBox() {
        let cameraOptions = CameraOptions(
            center: Constants.defaultMapCenterCoordinates,
            zoom: 8,
            bearing: .zero,
            pitch: .zero
        )
        let styleURI: StyleURI
        if traitCollection.userInterfaceStyle == .dark {
            styleURI = StyleURI(url: URL(string: "mapbox://styles/mapbox/dark-v11")!)!
        } else {
            styleURI = StyleURI(url: URL(string: "mapbox://styles/mapbox/streets-v11")!)!
        }
        let options = MapInitOptions(
            cameraOptions: cameraOptions,
            styleURI: styleURI
        )
        mapView = MapView(frame: containerView.bounds, mapInitOptions: options)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(mapView)
        mapView.alignToView(containerView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureMapBox()
        bind()
    }
    
    private func getCityCamImage() -> UIImage {
        let camView = CircleIconControl(style: .Others.cam, frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        return camView.asImage()
    }

    fileprivate func updateAnnotations(_ annotationManager: PointAnnotationManager, _ cameras: [CityCameraObject]) {
        annotationManager.annotations = []
        
        let points = cameras.map { camera -> PointAnnotation in
            var point = PointAnnotation(coordinate: camera.position)
            point.tapHandler = { [weak self] _ -> Bool in
                self?.cameraSelectedTrigger.onNext(camera.cameraNumber)
                return true
            }
            // point.userInfo = ["camera": camera]
            point.image = .init(
                image: getCityCamImage(),
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

extension CityMapViewController {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateMapStyle()
    }
    
    private func updateMapStyle() {
        let styleURI: StyleURI
        if traitCollection.userInterfaceStyle == .dark {
            styleURI = StyleURI(url: URL(string: "mapbox://styles/mapbox/dark-v11")!)!
        } else {
            styleURI = StyleURI(url: URL(string: "mapbox://styles/mapbox/streets-v11")!)!
        }
        mapView.mapboxMap.loadStyle(styleURI)
    }

}
