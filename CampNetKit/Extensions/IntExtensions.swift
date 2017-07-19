//
//  IntExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/19.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

extension Int {
    public func usageString(decimalUnits: Bool) -> String {
        let step = decimalUnits ? 1000.0 : 1024.0
        var number = Double(self)
        
        if number < step {
            return String(format: "%.0f B", number)
        }
        number /= step
        if number < step {
            return String(format: "%.1f KB", number)
        }
        number /= step
        if number < step {
            return String(format: "%.1f MB", number)
        }
        number /= step
        return String(format: "%.1f GB", number)
    }
}
