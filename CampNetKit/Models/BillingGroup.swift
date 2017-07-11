//
//  Billing.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/11.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import Yaml

public struct BillingGroup {
    public enum Cycle: String {
        case day
        case month
        case year
    }
    
    public var configurationIdentifier: String
    public var name: String
    public var identifier: String
    
    public var maxOnlineNumber: Int?
    public var base: Double
    public var cycle: Cycle
    public var steps: [(Double, Double)]
    
    init?(configurationIdentifier: String, name: String, yaml: Yaml) {
        self.configurationIdentifier = configurationIdentifier
        self.name = name
        self.identifier = "\(configurationIdentifier).billing_groups.\(name)"
        
        self.maxOnlineNumber = yaml["max_online_num"].int
        self.base = yaml["base"].double ?? 0.0
        self.cycle = BillingGroup.Cycle(rawValue: yaml["cycle"].string ?? "") ?? BillingGroup.Cycle.month
        self.steps = yaml["steps"].doublePairArray ?? []
    }
}
