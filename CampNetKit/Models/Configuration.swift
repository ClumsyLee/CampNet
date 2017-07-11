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

public enum Status {
    case online(onlineUsername: String?, startTime: Date?, usage: Int?, updatedAt: Date)
    case offline(updatedAt: Date)
    case offcampus(updatedAt: Date)
    
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
            self = .online(onlineUsername: onlineUsername, startTime: startTime, usage: usage, updatedAt: updatedAt)
        case "offline":
            self = .offline(updatedAt: updatedAt)
        case "offcampus":
            self = .offcampus(updatedAt: updatedAt)
        default:
            return nil
        }
    }
}

public struct Session {
    public var ip: String

    public var id: String?
    public var startTime: Date?
    public var usage: Int?
    public var mac: String?
    public var device: String?
}

public struct Profile {
    public var name: String?
    public var billingType: String?
    public var balance: Double?
    public var usage: Int?
    public var customMaxOnlineNumber: Int?
    public var sessions: [Session]?
    
    public var updatedAt: Date
    
    init?(vars: [String: Any]) {
        guard let updatedAt = vars["updated_at"] as? Date else {
            return nil
        }

        self.name = vars["name"] as? String
        self.billingType = vars["billing_type"] as? String
        self.balance = vars["balance"] as? Double
        self.usage = vars["usage"] as? Int
        self.customMaxOnlineNumber = vars["custom_max_online_num"] as? Int
        
        if let ips = vars["ips"] as? [String] {
            self.sessions = []
            
            let ids = vars["ids"] as? [String]
            let startTimes = vars["start_times"] as? [Date]
            let usages = vars["usages"] as? [Int]
            let macs = vars["macs"] as? [String]
            let devices = vars["devices"] as? [String]
            
            for (index, ip) in ips.enumerated() {
                sessions?.append(Session(ip: ip, id: ids?[safe: index], startTime: startTimes?[safe: index], usage: usages?[safe: index], mac: macs?[safe: index], device: devices?[safe: index]))
            }
        } else {
            self.sessions = nil
        }
        
        self.updatedAt = updatedAt
    }
}

struct HistorySession {
    var ip: String
    var startTime: Date
    var endTime: Date
    
    var usage: Int?
    var cost: Double?
    var mac: String?
    var device: String?
}

public struct Configuration {
    public static let bundleIdentifier = "me.clumsylee.CampNetKit"
    public static let appGroup = "group.me.clumsylee.CampNet-iOS"
    public static let keychainAccessGroup = "7494335NRW.me.clumsylee.CampNet-iOS"
    public static let subdirectory = "Configurations"
    public static let fileExtension = "yaml"
    public static let bundle = Bundle(identifier: bundleIdentifier)!
    
    public static var displayNames: [String: String] {
        var dict: [String: String] = [:]

        let urls = bundle.urls(forResourcesWithExtension: fileExtension, subdirectory: subdirectory) ?? []
        for url in urls {
            let identifier = url.deletingPathExtension().lastPathComponent
            dict[identifier] = displayName(identifier)
        }
        
        return dict
    }
    
    public static func displayName(_ identifier: String) -> String {
        return Configuration.bundle.localizedString(forKey: identifier, value: nil, table: "Configurations")
    }

    public var identifier: String
    
    public var ssids: [String]
    public var billingTypes: [String: BillingType] = [:]
    public var actions: [Action.Role: Action] = [:]
    
    public var displayName: String {
        return Configuration.displayName(identifier)
    }

    public init?(_ identifier: String) {
        print("Loading configuration \(identifier).")
        
        guard let url = Configuration.bundle.url(forResource: identifier, withExtension: Configuration.fileExtension, subdirectory: Configuration.subdirectory) else {
            print("Failed to find configuration \(identifier).")
            return nil
        }
        
        guard let content = try? String(contentsOf: url) else {
            print("Failed to read the configuration \(identifier).")
            return nil
        }
        
        guard let yaml = try? Yaml.load(content) else {
            print("Failed to load YAML out of configuration \(identifier).")
            return nil
        }
        
        self.identifier = identifier
        self.ssids = yaml["ssids"].stringArray ?? []
        
        if let billingTypes = yaml["billing_types"].dictionary {
            for (key, value) in billingTypes {
                guard let typeIdentifier = key.string else {
                    print("Billing names must be strings in \(identifier).")
                    return nil
                }
                guard let billingType = BillingType(configurationIdentifier: identifier, typeIdentifier: typeIdentifier, yaml: value) else {
                    print("Invalid billingType \(typeIdentifier) in \(identifier).")
                    return nil
                }
                
                self.billingTypes[typeIdentifier] = billingType
            }
        }
        
        if let actions = yaml["actions"].dictionary {
            for (key, value) in actions {
                guard let name = key.string,
                    let role = Action.Role(rawValue: name) else {
                        print("Invalid action role \(key) in \(identifier).")
                        return nil
                }
                guard let action = Action(configurationIdentifier: identifier, role: role, yaml: value) else {
                    print("Invalid action \(role) in \(identifier).")
                    return nil
                }
                
                self.actions[role] = action
            }
        }
        
        print("Configuration \(identifier) loaded.")
    }
    
    public func canManage(_ network: NEHotspotNetwork) -> Bool {
        return ssids.contains(network.ssid) && !network.isSecure
    }
}
