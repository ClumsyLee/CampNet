//
//  WifiAddress.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/8/2.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import NetUtils

public class WiFi {
    public static var ip: String? {
        for interface in Interface.allInterfaces() {
            if interface.isUp && interface.isRunning && interface.name == "en0" && interface.family == .ipv4 {
                return interface.address
            }
        }
        return nil
    }
}
