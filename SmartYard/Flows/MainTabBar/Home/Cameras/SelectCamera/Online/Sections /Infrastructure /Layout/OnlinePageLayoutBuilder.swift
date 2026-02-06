//
//  OnlinePageLayoutBuilder.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit

struct OnlinePageLayoutBuilder {

    private let numberLayout = CameraNumberCarouselLayout()

    func makeLayout(onTopCenteredIndex: ((Int) -> Void)? = nil) -> UICollectionViewCompositionalLayout {

        return UICollectionViewCompositionalLayout { sectionIndex, env in
            switch sectionIndex {
            case 0:
                return CameraCarouselLayout().make(with: env, onCenteredIndex: onTopCenteredIndex)
            case 1:
                return numberLayout.make(with: env)
            default:
                return nil
            }
        }
    }
}
