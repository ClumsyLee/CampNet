//
//  Device.swift
//  CampNetKit
//
//  Created by Thomas Lee on 2017/10/12.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import Foundation

public class Device {
    public static var inUITest: Bool {
        #if DEBUG
            return ProcessInfo.processInfo.environment["UITest"] != nil
        #else
            return false
        #endif
    }
}
