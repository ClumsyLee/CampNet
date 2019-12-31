//
//  NEHotspotHelperResultExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 1/22/19.
//  Copyright © 2019 Sihan Li. All rights reserved.
//

import Foundation
import NetworkExtension

extension NEHotspotHelperResult: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success: return "success"
        case .failure: return "failure"
        case .uiRequired: return "uiRequired"
        case .commandNotRecognized: return "commandNotRecognized"
        case .authenticationRequired: return "authenticationRequired"
        case .unsupportedNetwork: return "unsupportedNetwork"
        case .temporaryFailure: return "temporaryFailure"
        @unknown default: return "unknown"
        }
    }
}
