//
//  Billing.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/2/3.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import Yaml

struct Billing {
    enum Cycle: String {
        case day
        case month
        case year
    }
    
    var configurationIdentifier: String
    var name: String
    var identifier: String { return "\(configurationIdentifier).billings.\(name)" }

    var maxOnlineNumber: Int?
    var base: Double
    var cycle: Cycle
    var steps: [(Double, Double)]
    
    init?(configurationIdentifier: String, name: String, yaml: Yaml) {
        guard let base = yaml["base"].double,
              let cycleStr = yaml["cycle"].string, let cycle = Billing.Cycle(rawValue: cycleStr),
              let steps = yaml["steps"].doublePairArray else {
                print("Invalid billing.")
                return nil
        }
        
        self.configurationIdentifier = configurationIdentifier
        self.name = name

        self.maxOnlineNumber = yaml["max_online_num"].int
        self.base = base
        self.cycle = cycle
        self.steps = steps
    }
}
