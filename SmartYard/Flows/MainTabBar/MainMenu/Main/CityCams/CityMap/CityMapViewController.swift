//
//  CityMapViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 14.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length closure_body_length cyclomatic_complexity

import UIKit
import MapboxMaps
import MapboxCommon
import JGProgressHUD
import RxSwift
import RxCocoa
import CoreLocation

class CityMapViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var containerView: UIView!
    private var mapView: MapView!
    
    var loader: JGProgressHUD?
    var locationManager: CLLocationManager!
    var minZoomMap: Double! = 17
    var maxZoomMap: Double! = 10
    var minDistance: Double! = 4500
    var bottomLeftPoint: CLLocationCoordinate2D?
    var topRightPoint: CLLocationCoordinate2D?
    var cityLocation: CLLocationCoordinate2D = Constants.defaultMapCenterCoordinates
    
    private let viewModel: CityMapViewModel
    private let apiWrapper: APIWrapper

    private let cameraSelectedTrigger = PublishSubject<Int>()
    private let camerasProxy = BehaviorSubject<[CityCameraObject]>(value: [])
    private var annotationViews: [UIView] = []
    private let changeMapPositionOnCity = BehaviorSubject(value: false)
    
    private var mapboxStyle: String {
        if #available(iOS 13.0, *) {
            return UITraitCollection.current.userInterfaceStyle == .dark ? "mapbox://styles/mapbox/dark-v11" : "mapbox://styles/mapbox/streets-v12"
        } else {
            return "mapbox://styles/mapbox/streets-v12"
        }
    }

    init(viewModel: CityMapViewModel, apiWrapper: APIWrapper) {
        self.viewModel = viewModel
        self.apiWrapper = apiWrapper
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func configureMapBox() {
        let cameraOptions = CameraOptions(
            center: cityLocation,
            zoom: 9,
            bearing: .zero,
            pitch: .zero
        )
        let options = MapInitOptions(
            cameraOptions: cameraOptions,
            styleURI: StyleURI(url: URL(string: mapboxStyle)!)
        )
        mapView = MapView(frame: containerView.bounds, mapInitOptions: options)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(mapView)
        
        var configuration = Puck2DConfiguration()

        configuration.topImage = UIImage(named: "UserMapLocation")
        configuration.scale = .constant(0.6)

//        mapView.location.options.puckType = .puck2D(configuration)
        
        mapView.alignToView(containerView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        subscribeToCityLocationNotifications()
        configureMapBox()
        bind()
    }
    
    fileprivate func updateAnnotations(_ cameras: [CityCameraObject]) {
        
        self.annotationViews = cameras.map { camera -> UIView in
            
            let point = CityCamerasMapPointView()
            point.configure(cameraNumber: camera.cameraNumber) { [weak self] in
                self?.cameraSelectedTrigger.onNext(camera.cameraNumber)
            }
            let options = ViewAnnotationOptions(
                geometry: Point(camera.position),
                width: 40,
                height: 40,
                allowOverlap: true,
                anchor: .center
            )
            try? self.mapView.viewAnnotations.add(point, options: options)
            
            if let userpoint = self.mapView.location.latestLocation?.coordinate {
                let distance = camera.position.distance(to: userpoint)
                let zoom = log2(50000 / distance) + 7
                self.minZoomMap = min(zoom, self.minZoomMap)
                self.maxZoomMap = max(zoom, self.maxZoomMap)
                self.minDistance = min(zoom, distance)
            } else {
                let distance = camera.position.distance(to: cityLocation)
                let zoom = log2(50000 / distance) + 7
                self.minZoomMap = min(zoom, self.minZoomMap)
                self.maxZoomMap = max(zoom, self.maxZoomMap)
                self.minDistance = min(zoom, distance)
                if let longtitudeMinPoint = self.bottomLeftPoint?.longitude,
                   let latitudeMinPoint = self.bottomLeftPoint?.latitude {
                    self.bottomLeftPoint?.longitude = min(longtitudeMinPoint, camera.position.longitude)
                    self.bottomLeftPoint?.latitude = min(latitudeMinPoint, camera.position.latitude)
                } else {
                    self.bottomLeftPoint = camera.position
                }
                if let longtitudeMaxPoint = self.topRightPoint?.longitude,
                   let latitudeMaxPoint = self.topRightPoint?.latitude {
                    self.topRightPoint?.longitude = max(longtitudeMaxPoint, camera.position.longitude)
                    self.topRightPoint?.latitude = max(latitudeMaxPoint, camera.position.latitude)
                } else {
                    self.topRightPoint = camera.position
                }
            }
//            var point = PointAnnotation(coordinate: camera.position)
//            point.userInfo = ["camera": camera]
//            point.image = .init(
//                image: (UIImage(named: "CityCam")?.withRenderingMode(.alwaysOriginal))!,
//                name: "MapPoint"
//            )
//            point.iconAnchor = .center
            return point
        }
        
//        annotationManager.iconAllowOverlap = true
//        annotationManager.annotations = points
    }
    
    func bind() {
        let input = CityMapViewModel.Input(
            cameraSelected: cameraSelectedTrigger.asDriverOnErrorJustComplete()
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

//                    let annotationManager = self.mapView.annotations.makePointAnnotationManager()
//                    annotationManager.delegate = self
                    
                    self.updateAnnotations(cameras)
                    
                    let annotationCoordinates = cameras
                        .map { $0.position }
                    
                    if self.minDistance < 4500,
                       (self.mapView.location.latestLocation != nil) {
                        let zoom = (self.maxZoomMap + self.minZoomMap) / 2
                        if zoom < 12 {
                            let camera = CameraOptions(
                                center: self.mapView.location.latestLocation?.coordinate,
                                zoom: 12
                            )
                            self.mapView.mapboxMap.setCamera(to: camera)
                        } else {
                            let camera = CameraOptions(
                                center: self.mapView.location.latestLocation?.coordinate,
                                zoom: (self.maxZoomMap + self.minZoomMap) / 2
                            )
                            self.mapView.mapboxMap.setCamera(to: camera)
                        }
                    } else {
                        switch annotationCoordinates.withoutDuplicates().count {
                        case 1:
                            let camera = CameraOptions(center: annotationCoordinates.first!, zoom: 16)
                            self.mapView.mapboxMap.setCamera(to: camera)
                        case let count where count > 1:
                            if  let bottomPoint = self.bottomLeftPoint,
                                let topPoint = self.topRightPoint {
                                let distance = bottomPoint.distance(to: topPoint)
                                
                                let middlePoint = CLLocationCoordinate2D(
                                    latitude: (bottomPoint.latitude + topPoint.latitude) / 2,
                                    longitude: (bottomPoint.longitude + topPoint.longitude) / 2
                                )
                                
                                switch log2(100000 / distance) + 7 {
                                case let zoom where zoom < 12:
                                    let camera = CameraOptions(
                                        center: self.cityLocation,
                                        zoom: 12
                                    )
                                    self.mapView.mapboxMap.setCamera(to: camera)
                                    self.changeMapPositionOnCity.onNext(true)
                                case let zoom where zoom > 16:
                                    let camera = CameraOptions(
                                        center: middlePoint,
                                        zoom: 16
                                    )
                                    self.mapView.mapboxMap.setCamera(to: camera)
                                default:
                                    let camera = self.mapView.mapboxMap.camera(
                                        for: annotationCoordinates,
                                        padding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                                        bearing: .none,
                                        pitch: .none
                                    )
                                    self.mapView.mapboxMap.setCamera(to: camera)
                                }
                            } else {
                                let camera = self.mapView.mapboxMap.camera(
                                    for: annotationCoordinates,
                                    padding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                                    bearing: .none,
                                    pitch: .none
                                )
                                self.mapView.mapboxMap.setCamera(to: camera)
                            }
                        default: break
                        }
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
        self.annotationViews.forEach {
            self.mapView.viewAnnotations.remove($0)
        }
    }
    
    private func subscribeToCityLocationNotifications() {
        NotificationCenter.default.rx.notification(.updateCityCoordinate)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    guard let self = self,
                          let city = notification.object as? String else {
                        return
                    }
                    /// TODO: При изменении города тут меняем позиционирование карты на новое
                    
                    let activityTracker = ActivityTracker()
                    let errorTracker = ErrorTracker()

                    self.apiWrapper.getCityCoordinate(cityName: city)
                        .trackError(errorTracker)
                        .trackActivity(activityTracker)
                        .asDriver(onErrorJustReturn: nil)
                        .ignoreNil()
                        .drive(
                            onNext: { [weak self] coord in
                                guard let self = self, let location = coord.coordinate else {
                                    return
                                }
                                self.cityLocation = location
                                print("CITY LOCATION CHANGED", city, self.cityLocation)

                            }
                        )
                        .disposed(by: self.disposeBag)
                }
            )
            .disposed(by: disposeBag)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                if let darkURL = URL(string: "mapbox://styles/mapbox/dark-v11"),
                   let lightURL = URL(string: "mapbox://styles/mapbox/streets-v12") {
                    mapView.mapboxMap.styleURI = StyleURI(url: traitCollection.userInterfaceStyle == .dark ? darkURL : lightURL)
                }
            }
        }
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
// swiftlint:enable function_body_length closure_body_length cyclomatic_complexity
