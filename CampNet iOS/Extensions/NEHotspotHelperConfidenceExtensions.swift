//
//  NEHotspotHelperConfidenceExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 1/22/19.
//  Copyright © 2019 Sihan Li. All rights reserved.
//

import Foundation
import NetworkExtension

extension NEHotspotHelperConfidence: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none: return "none"
        case .low: return "low"
        case .high: return "high"
        }
    }
}
