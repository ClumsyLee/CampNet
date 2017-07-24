//
//  DoubleExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/24.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

extension Double {
    public var moneyString: String {
        return String(format: "%.2f", self)
    }
}
