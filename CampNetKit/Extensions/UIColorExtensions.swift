//
//  UIColorExtensions.swift
//  CampNetKit
//
//  Created by Thomas Lee on 12/31/19.
//  Copyright © 2019 Sihan Li. All rights reserved.
//

import Foundation
import UIKit

// See https://noahgilmore.com/blog/dark-mode-uicolor-compatibility/.
extension UIColor {
    public class var labelOrColor: UIColor {
        if #available(iOS 13.0, *) {
             return .label
         } else {
             return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1.0)
         }
    }

    public class var secondaryLabelOrColor: UIColor {
        if #available(iOS 13.0, *) {
             return .secondaryLabel
         } else {
             return #colorLiteral(red: 60, green: 60, blue: 67, alpha: 0.6)
         }
    }

    public class var systemFillOrColor: UIColor {
        if #available(iOS 13.0, *) {
             return .systemFill
         } else {
             return #colorLiteral(red: 120, green: 120, blue: 128, alpha: 0.2)
         }
    }
}
