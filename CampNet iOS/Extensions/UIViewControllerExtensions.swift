//
//  UIViewControllerExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/21.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: NSLocalizedString("OK", comment: "OK button on alerts that display errors."), style: .default)
        alert.addAction(action)
        
        present(alert, animated: true)
    }
}
