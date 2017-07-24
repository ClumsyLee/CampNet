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
    public var configurationIdentifier: String
    public var name: String
    public var identifier: String
    
    public var baseFee: Double
    public var steps: [(usage: Int, price: Double)]
    public var freeUsage: Int {
        return steps.first?.0 ?? 0
    }
    
    public func maxUsage(balance: Double, usage: Int) -> Int {
        var balance = balance
        var usage = usage
        var price = 0.0
        
        for step in steps {
            if step.usage > usage {
                // Calculate last step.
                let margin = Double(step.usage - usage) * price
                if balance <= margin {
                    break
                }
                
                balance -= margin
                usage = step.usage
            }
            price = step.price
        }
        
        usage += Int(balance / price)
        return usage
    }
    
    public func fee(at usage: Int) -> Double{
        var fee = 0.0
        var lastStep = (usage: 0, price: 0.0)
        
        for step in steps {
            if step.usage >= usage {
                break
            }
            fee += Double(step.usage - lastStep.usage) * lastStep.price
            lastStep = step
        }
        
        fee += Double(usage - lastStep.usage) * lastStep.price
        return fee
    }
    
    init?(configurationIdentifier: String, name: String, yaml: Yaml) {
        self.configurationIdentifier = configurationIdentifier
        self.name = name
        self.identifier = "\(configurationIdentifier).billing_groups.\(name)"
        
        self.baseFee = yaml["base_fee"].double ?? 0.0
        self.steps = yaml["steps"].steps ?? []
    }
}
