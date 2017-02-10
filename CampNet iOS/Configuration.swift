//
//  Configuration.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/18.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import NetworkExtension

import PromiseKit
import SwiftyUserDefaults
import Yaml

enum Status {
    case online(configurationIdentifier: String, username: String?, startTime: Date?, usage: Int?)
    case offline(configurationIdentifier: String)
    case offcampus
}

struct Session {
    var ip: String
    
    var id: String?
    var startTime: Date?
    var usage: Int?
    var mac: String?
    var device: String?
}

struct Profile {
    var balance: Double
    
    var billing: String?
    var name: String?
    var usage: Int?
    var customMaxOnlineNumber: Int?
    var sessions: [Session]?
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

class Configuration {
    let identifier: String

    var ssids: [String]
    var billings: [String: Billing] = [:]
    var actions: [Action.Role: Action] = [:]
    
    init?(identifier: String) {
        print("Loading configuration \(identifier).")
        
        guard let url = Bundle.main.url(forResource: identifier, withExtension: "yaml", subdirectory: "Configs") else {
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
        
        if let billings = yaml["billings"].dictionary {
            for (key, value) in billings {
                guard let name = key.string else {
                    print("Billing names must be strings in \(identifier).")
                    return nil
                }
                guard let billing = Billing(configurationIdentifier: identifier, name: name, yaml: value) else {
                    print("Invalid billing \(name) in \(identifier).")
                    return nil
                }

                self.billings[name] = billing
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
    
    func canManage(_ network: NEHotspotNetwork) -> Bool {
        return ssids.contains(network.ssid) && !network.isSecure
    }
    
    func login(username: String, password: String, on queue: DispatchQueue, requestBinder: RequestBinder? = nil) -> Promise<Void> {
        guard let action = actions[.login] else {
            return Promise(error: CampNetError.invalidConfiguration)
        }

        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then { _ in Promise(value: ()) }
    }
    
    func status(username: String, password: String, on queue: DispatchQueue, requestBinder: RequestBinder? = nil) -> Promise<Status> {
        guard let action = actions[.status] else {
            return Promise(error: CampNetError.invalidConfiguration)
        }

        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then(on: queue) { vars in
            guard let statusString = vars["status"]?.string else {
                print("No status in vars.")
                throw CampNetError.invalidConfiguration
            }
            
            switch statusString {
            case "online":
                let username = vars["username"]?.string
                let startTime = vars["start_time"]?.date
                let usage = vars["usage"]?.usage
                return Promise(value: .online(configurationIdentifier: self.identifier, username: username, startTime: startTime, usage: usage))
            case "offline":
                return Promise(value: .offline(configurationIdentifier: self.identifier))
            case "offcampus":
                return Promise(value: .offcampus)
            default:
                print("Unknown status string: \(statusString)")
                return Promise(error: CampNetError.invalidConfiguration)
            }
        }
        .recover(on: queue) { error -> Promise<Status> in
            if case CampNetError.networkError = error {
                return Promise(value: .offcampus)
            } else {
                throw error
            }
        }
    }
        
    func profile(username: String, password: String, on queue: DispatchQueue, requestBinder: RequestBinder? = nil) -> Promise<Profile> {
        guard let action = actions[.profile] else {
            return Promise(error: CampNetError.invalidConfiguration)
        }
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then(on: queue) { vars in
            guard let balance = vars["balance"]?.double else {
                print("No balance in vars.")
                throw CampNetError.invalidConfiguration
            }
            
            let billing = vars["billing"]?.string
            let name = vars["name"]?.string
            let usage = vars["usage"]?.usage
            let customMaxOnlineNumber = vars["custom_max_online_num"]?.innerInt
            
            var sessions: [Session]?
            if let ips = vars["[ip]"]?.ipArray {
                sessions = []
                
                let ids = vars["[id]"]?.stringArray
                let startTimes = vars["[start_time]"]?.dateArray
                let usages = vars["[usage]"]?.usageArray
                let macs = vars["[mac]"]?.macArray
                let devices = vars["[device]"]?.stringArray
                
                for (index, ip) in ips.enumerated() {
                    sessions?.append(Session(ip: ip, id: ids?[safe: index], startTime: startTimes?[safe: index], usage: usages?[safe: index], mac: macs?[safe: index], device: devices?[safe: index]))
                }
            } else {
                sessions = nil
            }
            
            return Promise(value: Profile(balance: balance, billing: billing, name: name, usage: usage, customMaxOnlineNumber: customMaxOnlineNumber, sessions: sessions))
        }
    }
    
    func modifyCustomMaxOnlineNumber(username: String, password: String, newValue: Int, on queue: DispatchQueue, requestBinder: RequestBinder? = nil) -> Promise<Void> {
        guard let action = actions[.modifyCustomMaxOnlineNum] else {
            return Promise(error: CampNetError.invalidConfiguration)
        }
        
        return action.commit(username: username, password: password, extraVars: ["new_value": newValue.string], on: queue, requestBinder: requestBinder).then { _ in Promise(value: ()) }
    }

    func login(username: String, password: String, ip: String, on queue: DispatchQueue, requestBinder: RequestBinder? = nil) -> Promise<Void> {
        guard let action = actions[.loginIp] else {
            return Promise(error: CampNetError.invalidConfiguration)
        }
        
        return action.commit(username: username, password: password, extraVars: ["ip": ip], on: queue, requestBinder: requestBinder).then { _ in Promise(value: ()) }
    }
    
    func logoutSession(username: String, password: String, ip: String, id: String?, on queue: DispatchQueue, requestBinder: RequestBinder? = nil) -> Promise<Void> {
        guard let action = actions[.logoutSession] else {
            return Promise(error: CampNetError.invalidConfiguration)
        }
        
        return action.commit(username: username, password: password, extraVars: ["ip": ip, "id": id ?? ""], on: queue, requestBinder: requestBinder).then { _ in Promise(value: ()) }
    }

    func history(username: String, password: String, from: Date, to: Date, on queue: DispatchQueue, requestBinder: RequestBinder? = nil) -> Promise<[HistorySession]> {
        guard let action = actions[.history] else {
            return Promise(error: CampNetError.invalidConfiguration)
        }
        
        let from = Calendar(identifier: .republicOfChina).dateComponents([.year, .month, .day], from: from)
        let to = Calendar(identifier: .republicOfChina).dateComponents([.year, .month, .day], from: to)
        let extraVars = [
            "start_time.year": String(format: "%04d", from.year!),
            "start_time.month": String(format: "%02d", from.month!),
            "start_time.day": String(format: "%02d", from.day!),
            "end_time.year": String(format: "%04d", to.year!),
            "end_time.month": String(format: "%02d", to.month!),
            "end_time.day": String(format: "%02d", to.day!)
        ]

        return action.commit(username: username, password: password, extraVars: extraVars, on: queue, requestBinder: requestBinder).then(on: queue) { vars in
            var sessions: [HistorySession] = []
            
            if let ips = vars["[ip]"]?.ipArray,
               let startTimes = vars["[start_time]"]?.dateArray,
               let endTimes = vars["[end_time]"]?.dateArray,
               ips.count == startTimes.count && ips.count == endTimes.count {

                let usages = vars["[usage]"]?.usageArray
                let costs = vars["[cost]"]?.doubleArray
                let macs = vars["[mac]"]?.macArray
                let devices = vars["[device]"]?.stringArray
                
                for (index, ip) in ips.enumerated() {
                    sessions.append(HistorySession(ip: ip, startTime: startTimes[index], endTime: endTimes[index], usage: usages?[safe: index], cost: costs?[safe: index], mac: macs?[safe: index], device: devices?[safe: index]))
                }
            }
            
            return Promise(value: sessions)
        }
    }
    
    func logout(username: String, password: String, on queue: DispatchQueue, requestBinder: RequestBinder? = nil) -> Promise<Void> {
        guard let action = actions[.logout] else {
            return Promise(error: CampNetError.invalidConfiguration)
        }
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then { _ in Promise(value: ()) }
    }
}
