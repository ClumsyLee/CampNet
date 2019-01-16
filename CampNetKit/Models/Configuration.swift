//
//  Configuration.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/10.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//


import Foundation
import NetworkExtension
import Yaml

public enum StatusType {
    case online(onlineUsername: String?, startTime: Date?, usage: Int?)
    case offline
    case offcampus
}

public struct Status {
    public var type: StatusType
    public var updatedAt: Date

    var vars: [String: Any] {
        var vars: [String: Any] = [:]

        switch type {
        case let .online(onlineUsername: onlineUsername, startTime: startTime, usage: usage):
            vars["status"] = "online"
            vars["online_username"] = onlineUsername
            vars["start_time"] = startTime
            vars["usage"] = usage
        case .offline:
            vars["status"] = "offline"
        case .offcampus:
            vars["status"] = "offcampus"
        }

        vars["updated_at"] = updatedAt

        return vars
    }

    init(type: StatusType, updatedAt: Date = Date()) {
        self.type = type
        self.updatedAt = updatedAt
    }

    init?(vars: [String: Any]) {
        guard let statusString = vars["status"] as? String,
              let updatedAt = vars["updated_at"] as? Date else {
            return nil
        }

        switch statusString {
        case "online":
            let onlineUsername = vars["online_username"] as? String
            let startTime = vars["start_time"] as? Date
            let usage = vars["usage"] as? Int
            self.type = .online(onlineUsername: onlineUsername, startTime: startTime, usage: usage)
        case "offline":
            self.type = .offline
        case "offcampus":
            self.type = .offcampus
        default:
            return nil
        }

        self.updatedAt = updatedAt
    }
}

extension Status: CustomStringConvertible {
    public var description: String {
        switch type {
        case let .online(onlineUsername: onlineUsername, startTime: startTime, usage: usage):
            return "online(\(onlineUsername ?? "nil"), \(startTime?.description ?? "nil"), " +
                   "\(usage?.description ?? "nil"))"
        case .offline:
            return "offline"
        case .offcampus:
            return "offcampus"
        }
    }
}

public struct Session {
    public var ip: String

    public var id: String?
    public var startTime: Date?
    public var usage: Int64?
    public var mac: String?
    public var device: String?

    var vars: [String: Any] {
        var vars: [String: Any] = [:]

        vars["ip"] = ip
        vars["id"] = id
        vars["start_time"] = startTime
        vars["usage"] = usage
        vars["mac"] = mac
        vars["device"] = device

        return vars
    }

    init(ip: String, id: String? = nil, startTime: Date? = nil, usage: Int64? = nil, mac: String? = nil,
         device: String? = nil) {
        self.ip = ip
        self.id = id
        self.startTime = startTime
        self.usage = usage
        self.mac = mac
        self.device = device
    }

    init?(vars: [String: Any]) {
        guard let ip = vars["ip"] as? String else {
            return nil
        }

        self.ip = ip
        self.id = vars["id"] as? String
        self.startTime = vars["start_time"] as? Date
        self.usage = vars["usage"] as? Int64
        self.mac = vars["mac"] as? String
        self.device = vars["device"] as? String
    }
}

extension Session: CustomStringConvertible {
    public var description: String {
        return vars.description
    }
}

public struct Profile {
    public var name: String?
    public var billingGroupName: String?
    public var balance: Double?
    public var usage: Int64?
    public var sessions: [Session]?

    public var updatedAt: Date

    var vars: [String: Any] {
        var vars: [String: Any] = [:]

        vars["name"] = name
        vars["billing_group_name"] = billingGroupName
        vars["balance"] = balance
        vars["usage"] = usage
        vars["sessions"] = sessions?.map { $0.vars }

        vars["updated_at"] = updatedAt

        return vars
    }

    init(name: String? = nil, billingGroupName: String? = nil, balance: Double? = nil, usage: Int64? = nil,
         sessions: [Session]? = nil, updatedAt: Date = Date()) {
        self.name = name
        self.billingGroupName = billingGroupName
        self.balance = balance
        self.usage = usage
        self.sessions = sessions
        self.updatedAt = updatedAt
    }

    init?(vars: [String: Any]) {
        guard let updatedAt = vars["updated_at"] as? Date else {
            return nil
        }

        self.name = vars["name"] as? String
        self.billingGroupName = vars["billing_group_name"] as? String
        self.balance = vars["balance"] as? Double
        self.usage = vars["usage"] as? Int64

        if let sessions = vars["sessions"] as? [[String: Any]] {
            self.sessions = []
            for sessionVars in sessions {
                if let session = Session(vars: sessionVars) {
                    self.sessions?.append(session)
                }
            }
        } else {
            self.sessions = nil
        }

        self.updatedAt = updatedAt
    }
}

extension Profile: CustomStringConvertible {
    public var description: String {
        return vars.description
    }
}

public struct History {
    public var year: Int
    public var month: Int
    public var usageSums: [Int64]

    var vars: [String: Any] {
        var vars: [String: Any] = [:]

        vars["year"] = year
        vars["month"] = month
        vars["usage_sums"] = usageSums

        return vars
    }

    init(year: Int, month: Int, usageSums: [Int64]) {
        self.year = year
        self.month = month
        self.usageSums = usageSums
    }

    init?(vars: [String: Any]) {
        guard let year = vars["year"] as? Int,
              let month = vars["month"] as? Int,
              let usageSums = vars["usage_sums"] as? [Int64] else {
            return nil
        }

        self.year = year
        self.month = month
        self.usageSums = usageSums
    }
}

extension History: CustomStringConvertible {
    public var description: String {
        return vars.description
    }
}

public class Configuration {
    public static let bundleIdentifier = "me.clumsylee.CampNetKit"
    public static let appGroup = "group.me.clumsylee.CampNet-iOS"
    public static let keychainAccessGroup = "7494335NRW.me.clumsylee.CampNet-iOS"
    public static let subdirectory = "Configurations"
    public static let fileExtension = "yaml"
    public static let bundle = Bundle(identifier: bundleIdentifier)!
    public static let customIdentifier = "custom.self"

    public static var displayNames: [String: String] {
        var dict: [String: String] = [:]
        var identifiers = bundle.urls(forResourcesWithExtension: fileExtension, subdirectory: subdirectory)?.map { url in url.deletingPathExtension().lastPathComponent } ?? []

        identifiers.append(customIdentifier)
        for identifier in identifiers {
            dict[identifier] = displayName(identifier)
        }

        return dict
    }

    public static func displayName(_ identifier: String) -> String {
        return Configuration.bundle.localizedString(forKey: identifier, value: nil, table: "Configurations")
    }

    public let identifier: String
    public let displayName: String
    public var logo: UIImage? {
        return UIImage(named: identifier)
    }

    public let ssids: Set<String>
    public let decimalUnits: Bool
    public let billingGroups: [String: BillingGroup]
    public let actions: [Action.Role: Action]

    public init?(_ identifier: String) {
        var yamlString: String

        if identifier == Configuration.customIdentifier {
            yamlString = Defaults[.customConfiguration]
        } else {
            guard let url = Configuration.bundle.url(forResource: identifier, withExtension: Configuration.fileExtension,
                                                     subdirectory: Configuration.subdirectory) else {
                                                        log.error("\(identifier): Failed to find.")
                                                        return nil
            }
            guard let content = try? String(contentsOf: url) else {
                log.error("\(identifier): Failed to read.")
                return nil
            }
            yamlString = content
        }

        guard let yaml = try? Yaml.load(yamlString) else {
            log.error("\(identifier): Failed to load YAML.")
            return nil
        }

        self.identifier = identifier
        self.displayName = Configuration.displayName(identifier)
        self.decimalUnits = yaml["decimal_units"].bool ?? false
        self.ssids = Set(yaml["ssids"].stringArray ?? [])

        var billingGroups: [String: BillingGroup] = [:]
        if let billingGroupsYaml = yaml["billing_groups"].dictionary {
            for (key, value) in billingGroupsYaml {
                guard let name = key.string else {
                    log.error("\(identifier): Billing group names must be strings.")
                    return nil
                }

                billingGroups[name] = BillingGroup(configurationIdentifier: identifier, name: name,
                                                   decimalUnits: decimalUnits, yaml: value)
            }
        }
        self.billingGroups = billingGroups

        var actions: [Action.Role: Action] = [:]
        if let actionsYaml = yaml["actions"].dictionary {
            for (key, value) in actionsYaml {
                guard let name = key.string,
                    let role = Action.Role(rawValue: name) else {
                        log.error("\(identifier): Invalid action role \(key).")
                        return nil
                }
                guard let action = Action(configurationIdentifier: identifier, role: role, yaml: value) else {
                    return nil
                }

                actions[role] = action
            }
        }
        self.actions = actions

        log.debug("\(identifier): Loaded.")
    }

    public func canManage(_ network: NEHotspotNetwork) -> Bool {
        return (ssids.contains(network.ssid) ||
                Defaults[.onCampus(id: identifier, ssid: network.ssid)]) &&
               Defaults[.autoLogin]
    }
}

extension Configuration: Hashable {
    public var hashValue: Int {
        return identifier.hashValue
    }

    public static func ==(lhs: Configuration, rhs: Configuration) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
