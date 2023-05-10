//
//  FullscreenImageViewController.swift
//  SmartYard
//
//  Created by devcentra on 13.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD

class FullscreenImageViewController: UIViewController, LoaderPresentable {
    
    private var sliderConstraints: [NSLayoutConstraint] = []
    
    private var imageURL: URL?
    private var imageLayer: UIImageView
    private let position: CGRect?

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var collectionView: UICollectionView!

    private var disposeBag = DisposeBag()
    
    var loader: JGProgressHUD?
    
    init(position: CGRect? = nil) {
        loader = JGProgressHUD()
        imageLayer = UIImageView()
        self.position = position
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction private func tapView(_ sender: UITapGestureRecognizer) {
        animatedClose()
//        self.imageLayer.image = nil
//        self.dismiss(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard isBeingDismissed else {
            return
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIViewController.attemptRotationToDeviceOrientation()
        
        self.imageLayer.load(url: self.imageURL, loader: loader)

    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        scrollView.zoomScale = 1.0
        scrollView.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        imageLayer.contentMode = .scaleAspectFit
        imageLayer.frame = contentView.bounds
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        DispatchQueue.main.async {
            self.scrollView.zoomScale = 1.0
            self.scrollView.contentSize = size
            self.imageLayer.contentMode = .scaleAspectFit
            self.imageLayer.frame = self.contentView.bounds
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.zoomScale = 1.0
        scrollView.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        imageLayer.contentMode = .scaleAspectFit
        imageLayer.frame = contentView.bounds
        
        contentView.addSubview(imageLayer)
        loader?.show(in: contentView)

        let swipeLeft = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeLeft.direction = .left
        contentView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeRight.direction = .right
        contentView.addGestureRecognizer(swipeRight)
        
        let swipeUp = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeUp.direction = .up
        contentView.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeDown.direction = .down
        contentView.addGestureRecognizer(swipeDown)
        
    }

    @objc private dynamic func handleSwipeGestureRecognizer(_ recognizer: UISwipeGestureRecognizer) {
        animatedClose()
//        if recognizer.direction == .left {
//            UIView.animate(
//                withDuration: 0.5,
//                delay: 0.0,
//                options: .curveEaseOut,
//                animations: {
//                    self.contentView.frame.origin.x -= self.contentView.frame.size.width
//                    self.contentView.alpha = 0.0
//                },
//                completion: { _ in
//                    self.dismiss(animated: true, completion: nil)
//                }
//            )
//        }
    }
    
    private func animatedClose() {
        self.scrollView.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        UIView.animate(
            withDuration: 0.7,
            delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                if let position = self.position {
                    self.contentView.bounds = position
                    self.contentView.frame = position
                    self.imageLayer.frame = position
                    self.imageLayer.layerCornerRadius = 20
                    self.imageLayer.alpha = 0
                }
            },
            completion: { _ in
                self.dismiss(animated: true, completion: nil)
            }
        )
    }

    func setImageLayer(_ imageURL: URL) {
        self.imageURL = imageURL
    }

}

extension UIImageView {
    func load(url: URL?, loader: JGProgressHUD?) {
        guard let url = url else {
            return
        }
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                        loader?.dismiss(animated: true)
                    }
                }
            }
        }
    }
}

extension FullscreenImageViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }
}
