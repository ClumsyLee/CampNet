//
//  Account.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/10.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

import KeychainAccess
import PromiseKit
import SwiftyUserDefaults

public class Account {
    static let passwordKeychain = Keychain(service: "\(Configuration.bundleIdentifier).password", accessGroup: Configuration.keychainAccessGroup)
    
    public static var all: [Account] {
        return AccountManager.shared.all
    }
    
    public static var main: Account? {
        return AccountManager.shared.main
    }
    
    public static func add(_ account: Account) {
        AccountManager.shared.add(account)
    }
    
    public static func remove(_ account: Account) {
        AccountManager.shared.remove(account)
    }
    
    public static func makeMain(_ account: Account) {
        AccountManager.shared.makeMain(account)
    }
    
    public let configuration: Configuration
    public let username: String
    public let identifier: String
    
    public var password: String {
        get {
            return Account.passwordKeychain[identifier] ?? ""
        }
        set {
            Account.passwordKeychain[identifier] = newValue
        }
    }
    
    public var status: Status? {
        guard let vars = Defaults[.accountStatus(of: identifier)] else {
            return nil
        }
        return Status(vars: vars)
    }
    
    public var profile: Profile? {
        guard let vars = Defaults[.accountProfile(of: identifier)] else {
            return nil
        }
        return Profile(vars: vars)
    }
    
    public init?(_ identifier: String) {
        var parts = identifier.components(separatedBy: ".")
        let username = parts.removeLast()
        guard let configuration = Configuration(parts.joined(separator: ".")) else {
            return nil
        }
        
        self.configuration = configuration
        self.username = username
        self.identifier = identifier
    }
    
    public func login(on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {

        guard let action = configuration.actions[.login] else {
            print("Login action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging in for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then { _ in Promise(value: ()) }
    }
    
    public func status(on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Status> {
        
        guard let action = configuration.actions[.status] else {
            print("Status action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Updating status for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then(on: queue) { vars in
            guard let status = Status(vars: vars) else {
                print("No status in vars (\(vars)).")
                throw CampNetError.invalidConfiguration
            }
            Defaults[.accountProfile(of: self.identifier)] = vars
            return Promise(value: status)
        }
        .recover(on: queue) { error -> Promise<Status> in
            if case CampNetError.networkError = error {
                return Promise(value: .offcampus(updatedAt: Date()))
            } else {
                throw error
            }
        }
    }
    
    public func profile(on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Profile> {
        
        guard let action = configuration.actions[.profile] else {
            print("Profile action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Updating profile for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then(on: queue) { vars in
            guard let profile = Profile(vars: vars) else {
                print("No profile in vars (\(vars)).")
                throw CampNetError.invalidConfiguration
            }
            Defaults[.accountProfile(of: self.identifier)] = vars
            return Promise(value: profile)
        }
    }
    
    public func modifyCustomMaxOnlineNumber(newValue: Int, on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {
        
        guard let action = configuration.actions[.modifyCustomMaxOnlineNum] else {
            print("ModifyCustomMaxOnlineNum action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Modify custom max online number to \(newValue) for \(identifier).")
        
        return action.commit(username: username, password: password, extraVars: ["new_value": String(newValue)], on: queue, requestBinder: requestBinder).then { _ in Promise(value: ()) }
    }
    
    public func login(ip: String, on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {
        
        guard let action = configuration.actions[.loginIp] else {
            print("LoginIp action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging in IP \(ip) for \(identifier).")
        
        return action.commit(username: username, password: password, extraVars: ["ip": ip], on: queue, requestBinder: requestBinder).then { _ in Promise(value: ()) }
    }
    
    public func logoutSession(session: Session, on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {
        
        guard let action = configuration.actions[.logoutSession] else {
            print("LogoutSession action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging out \(session) for \(identifier).")
        
        return action.commit(username: username, password: password, extraVars: ["ip": session.ip, "id": session.id ?? ""], on: queue, requestBinder: requestBinder).then { _ in Promise(value: ()) }
    }
    
//    func history(from: Date, to: Date, on queue: DispatchQueue, requestBinder: RequestBinder? = nil) -> Promise<[HistorySession]> {
//        guard let action = configuration.actions[.history] else {
//            return Promise(error: CampNetError.invalidConfiguration)
//        }
//        
//        let from = Calendar(identifier: .republicOfChina).dateComponents([.year, .month, .day], from: from)
//        let to = Calendar(identifier: .republicOfChina).dateComponents([.year, .month, .day], from: to)
//        let extraVars = [
//            "start_time.year": String(format: "%04d", from.year!),
//            "start_time.month": String(format: "%02d", from.month!),
//            "start_time.day": String(format: "%02d", from.day!),
//            "end_time.year": String(format: "%04d", to.year!),
//            "end_time.month": String(format: "%02d", to.month!),
//            "end_time.day": String(format: "%02d", to.day!)
//        ]
//        
//        return action.commit(username: username, password: password, extraVars: extraVars, on: queue, requestBinder: requestBinder).then(on: queue) { vars in
//            var sessions: [HistorySession] = []
//            
//            if let ips = vars["[ip]"]?.ipArray,
//                let startTimes = vars["[start_time]"]?.dateArray,
//                let endTimes = vars["[end_time]"]?.dateArray,
//                ips.count == startTimes.count && ips.count == endTimes.count {
//                
//                let usages = vars["[usage]"]?.usageArray
//                let costs = vars["[cost]"]?.doubleArray
//                let macs = vars["[mac]"]?.macArray
//                let devices = vars["[device]"]?.stringArray
//                
//                for (index, ip) in ips.enumerated() {
//                    sessions.append(HistorySession(ip: ip, startTime: startTimes[index], endTime: endTimes[index], usage: usages?[safe: index], cost: costs?[safe: index], mac: macs?[safe: index], device: devices?[safe: index]))
//                }
//            }
//            
//            return Promise(value: sessions)
//        }
//    }
    
    public func logout(on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {
        
        guard let action = configuration.actions[.logout] else {
            print("Logout action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging out for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then { _ in Promise(value: ()) }
    }
}
