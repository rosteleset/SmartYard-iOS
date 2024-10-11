//
//  CameraPreviewCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 23.03.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import Lottie

enum CameraPreviewCellOrder: Equatable {
    case first
    case last
    case regular
    case single
}

class CameraPreviewCell: UICollectionViewCell {
    
    @IBOutlet private weak var cameraLabel: UILabel!
    @IBOutlet private weak var previewImage: UIImageView!
    @IBOutlet private weak var loadingAnimationView: LottieAnimationView!

    var urlString: String?
    
    override var isSelected: Bool {
        didSet {
            cameraLabel.textColor = isSelected ? UIColor.SmartYard.blue : .lightGray
            previewImage.layerBorderColor = isSelected ? .white : .clear
        }
    }
    
    private func viewLoader() {
        let animation = LottieAnimation.named("LoaderAnimation")
        
        loadingAnimationView.animation = animation
        loadingAnimationView.loopMode = .loop
        loadingAnimationView.backgroundBehavior = .pauseAndRestore
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        viewLoader()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    func imageIsLoaded(image: UIImage) {
        previewImage.image = image
        loadingAnimationView.stop()
        loadingAnimationView.isHidden = true
    }

    func configureCell(camera: CameraExtendedObject, urlString: String, cache: NSCache<NSString, UIImage>) {
        cameraLabel.text = ""
        
        self.urlString = urlString
        cameraLabel.text = camera.name
        
        if let image = cache.object(forKey: NSString(string: urlString)) {
            previewImage.image = image
            loadingAnimationView.isHidden = true
            loadingAnimationView.stop()
        } else {
            previewImage.image = nil
            loadingAnimationView.isHidden = false
            loadingAnimationView.play()
        }
        
//        guard let url = URL(string: previewString) else {
//            previewImage.image = nil
//            return
//        }
//
//        currentTask?.cancel()
//        
//        let urlSession = URLSession.shared
//
//        let task = urlSession.dataTask(with: url) { (data, response, error) in
//            if let data = data, let image = UIImage(data: data) {
//                DispatchQueue.main.async {
//                    guard let self = self else {
//                        return
//                    }
//                    if let cell = collection.cellForItem(at: indexPath) as? 
//                    self.previewImage.image = image
//                }
//            }
//        }
//        task.resume()
//        DispatchQueue.main.async { [weak self] in
//            guard let image = try? UIImage(url: url) else {
//                self?.previewImage.image = nil
//                return
//            }
//            let height = image.size.height / image.size.width * width / 5
//            let imageresized = image.imageResized(to: CGSize(width: width / 5, height: height))
//            print("DEBUG CAMERA URL", url, image.size, imageresized.bytesSize)
//            self?.previewImage.image = imageresized
//        }
//        ScreenshotHelper.generateThumbnailFromVideoUrlAsync(
//            url: url,
//            forTime: .zero
//        ) { [weak self] cgImage in
//            guard let cgImage = cgImage else {
//                return
//            }
//
//            DispatchQueue.main.async {
//                self?.previewImage.image = UIImage(cgImage: cgImage)
//            }
//        }

    }
    
}

extension UIImage {
    func imageResized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
