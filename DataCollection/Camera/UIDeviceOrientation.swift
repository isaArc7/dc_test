//
//  UIDeviceOrientation.swift
//  DataCollection
//
//  Created by 汤笑寒 on 2024-09-20.
//

import Foundation
import UIKit

extension UIDeviceOrientation {
    var videoRotationAngle: CGFloat {
        switch self {
        case .landscapeLeft:
            0
        case .portrait:
            90
        case .landscapeRight:
            180
        case .portraitUpsideDown:
            270
        default:
            90
        }
    }
}
