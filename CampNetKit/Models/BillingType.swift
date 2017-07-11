//
//  Billing.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/11.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import Yaml

public struct BillingType {
    public enum Cycle: String {
        case day
        case month
        case year
    }
    
    public var configurationIdentifier: String
    public var typeIdentifier: String
    public var identifier: String
    
    public var maxOnlineNumber: Int?
    public var base: Double
    public var cycle: Cycle
    public var steps: [(Double, Double)]
    
    init?(configurationIdentifier: String, typeIdentifier: String, yaml: Yaml) {
        self.configurationIdentifier = configurationIdentifier
        self.typeIdentifier = typeIdentifier
        self.identifier = "\(configurationIdentifier).billings.\(typeIdentifier)"
        
        self.maxOnlineNumber = yaml["max_online_num"].int
        self.base = yaml["base"].double ?? 0.0
        self.cycle = BillingType.Cycle(rawValue: yaml["cycle"].string ?? "") ?? BillingType.Cycle.month
        self.steps = yaml["steps"].doublePairArray ?? []
    }
}
