//
//  YardMapViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import MapboxMaps
import JGProgressHUD
import RxSwift
import RxCocoa

class YardMapViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var containerView: TopRoundedView!
    private var mapView: MapView!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    var loader: JGProgressHUD?
    
    private let viewModel: YardMapViewModel
    
    private let cameraSelectedTrigger = PublishSubject<Int>()
    private let camerasProxy = BehaviorSubject<[CameraObject]>(value: [])
    private var annotationViews: [UIView] = []
    
    init(viewModel: YardMapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func configureMapBox() {
        let cameraOptions = CameraOptions(
            center: Constants.defaultMapCenterCoordinates,
            zoom: 9,
            bearing: .zero,
            pitch: .zero
        )
        let options = MapInitOptions(
            cameraOptions: cameraOptions,
            styleURI: StyleURI(url: URL(string: "mapbox://styles/mapbox/streets-v11")!)
        )
        mapView = MapView(frame: containerView.bounds, mapInitOptions: options)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(mapView)
        mapView.alignToView(containerView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMapBox()
        bind()
        
    }

    fileprivate func updateAnnotations(_ cameras: [CameraObject]) {
        self.annotationViews = cameras.map { camera -> UIView in
            let point = CamerasMapPointView()
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
            
            return point
        }
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
                    
                    self.updateAnnotations(cameras)
                    
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
        self.annotationViews.forEach {
            self.mapView.viewAnnotations.remove($0)
        }
    }
}
