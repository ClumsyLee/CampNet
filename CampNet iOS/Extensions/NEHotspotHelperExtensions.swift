//
//  NEHotspotHelperExtensions.swift
//  CampNetKit
//
//  Created by Thomas Lee on 2017/10/12.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import NetworkExtension

import CampNetKit

extension NEHotspotHelper {
    public class func register(displayName: String) {
        let options = [kNEHotspotHelperOptionDisplayName: displayName as NSObject]
        let queue = DispatchQueue.global(qos: .userInitiated)

        let result = NEHotspotHelper.register(options: options, queue: queue) { command in
            let requestBinder: RequestBinder = { $0.bind(to: command) }

            switch command.commandType {
            case .filterScanList: command.filterScanList()
            case .evaluate: command.evaluate(on: queue, requestBinder: requestBinder)
            case .authenticate: command.authenticate(on: queue, requestBinder: requestBinder)
            case .maintain: command.maintain(on: queue, requestBinder: requestBinder)
            case .logoff: command.logoff(on: queue, requestBinder: requestBinder)
            default: break
            }
        }

        if result {
            log.info("HotspotHelper registered.")
        } else {
            log.error("Unable to register HotspotHelper.")
        }
    }
}
