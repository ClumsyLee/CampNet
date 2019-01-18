//
//  Billing.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/11.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import Foundation
import Yaml

public struct BillingGroup {
    static func steps(decimalUnits: Bool, yaml: Yaml) -> [(usage: Int64, price: Double)]? {
        let ratio: Int64 = decimalUnits ? 1000 * 1000 : 1024 * 1024

        guard let array = yaml.array else {
            return nil
        }

        var pairs: [(usage: Int64, price: Double)] = []
        var lastUsage = Int64(0)
        for element in array {
            guard let first = element[0].int, let second = element[1].double else {
                return nil
            }

            let step = (usage: Int64(first) * ratio, price: second / Double(ratio))
            if lastUsage > step.usage {
                return nil
            }
            lastUsage = step.usage
            pairs.append(step)
        }
        return pairs
    }

    public var configurationIdentifier: String
    public var name: String
    public var identifier: String

    public var baseFee: Double
    public var steps: [(usage: Int64, price: Double)]

    public var displayName: String? {
        return Configuration.bundle.localizedString(forKey: identifier, value: nil, table: "Configurations")
    }

    public var freeUsage: Int64 {
        return steps.first?.0 ?? 0
    }

    public func maxUsage(balance: Double, usage: Int64) -> Int64 {
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

        if price.isZero {
            return freeUsage
        } else {
            return usage + Int64(balance / price)
        }
    }

    public func fee(from: Int64, to: Int64) -> Double{
        var fee = 0.0
        var lastStep = (usage: Int64(0), price: 0.0)

        for step in steps {
            if step.usage < from {
                lastStep.usage = from
                lastStep.price = step.price
                continue
            }

            if step.usage >= to {
                break
            }
            fee += Double(step.usage - lastStep.usage) * lastStep.price
            lastStep = step
        }

        fee += Double(to - lastStep.usage) * lastStep.price
        return fee
    }

    init(configurationIdentifier: String, name: String, decimalUnits: Bool, yaml: Yaml) {
        self.configurationIdentifier = configurationIdentifier
        self.name = name
        self.identifier = "\(configurationIdentifier).billing_groups.\(name)"

        self.baseFee = yaml["base_fee"].double ?? 0.0
        self.steps = BillingGroup.steps(decimalUnits: decimalUnits, yaml: yaml["steps"]) ?? []
    }
}
