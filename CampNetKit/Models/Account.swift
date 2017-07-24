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
    
    static let statusLifetime: TimeInterval = 86400
    static let estimationLength = 7
    
    static let passwordKeychain = Keychain(service: "\(Configuration.bundleIdentifier).password", accessGroup: Configuration.keychainAccessGroup)
    
    public static var all: [Configuration: [Account]] {
        return AccountManager.shared.all
    }
    
    public static var main: Account? {
        return AccountManager.shared.main
    }
    
    public static func add(configurationIdentifier: String, username: String, password: String? = nil) {
        AccountManager.shared.add(configurationIdentifier: configurationIdentifier, username: username, password: password)
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
            unauthorized = false
        }
    }
    
    public fileprivate(set) var unauthorized: Bool {
        get {
            return Defaults[.accountUnauthorized(of: identifier)]
        }
        set {
            if unauthorized != newValue {
                Defaults[.accountUnauthorized(of: identifier)] = newValue
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .accountAuthorizationChanged, object: self, userInfo: ["account": self])
                }
            }
        }
    }
    
    public var freeUsage: Int? {
        guard let profile = profile,
              let billingGroup = configuration.billingGroups[profile.billingGroupName ?? ""] else {
            return nil
        }
        
        return billingGroup.freeUsage
    }
    
    public var maxUsage: Int? {
        guard let profile = profile,
              let balance = profile.balance,
              let usage = profile.usage,
              let billingGroup = configuration.billingGroups[profile.billingGroupName ?? ""] else {
            return nil
        }
        
        return billingGroup.maxUsage(balance: balance, usage: usage)
    }
    
    public fileprivate(set) var estimatedDailyUsage: Int? {
        get {
            return Defaults[.accountEstimatedDailyUsage(of: identifier)]
        }
        set {
            Defaults[.accountEstimatedDailyUsage(of: identifier)] = newValue
        }
    }

    public var estimatedFee: Double? {
        guard let profile = profile,
              let usage = profile.usage,
              let balance = profile.balance,
              let billingGroup = configuration.billingGroups[profile.billingGroupName ?? ""],
              let estimatedDailyUsage = estimatedDailyUsage else {
            return nil
        }
        
        let today = Date()
        guard let maxDay = Calendar.current.range(of: .day, in: .month, for: today)?.upperBound else {
            return nil
        }
        
        let estimatedUsage = min(usage + estimatedDailyUsage * (maxDay - Calendar.current.component(.day, from: today)),
                                 billingGroup.maxUsage(balance: balance, usage: usage))
        return billingGroup.fee(at: estimatedUsage)
    }
    
    public var status: Status? {
        guard let vars = Defaults[.accountStatus(of: identifier)],
              let status = Status(vars: vars) else {
            return nil
        }
        
        return -status.updatedAt.timeIntervalSinceNow <= Account.statusLifetime ? status : nil
    }
    
    public var profile: Profile? {
        guard let vars = Defaults[.accountProfile(of: identifier)],
              let profile = Profile(vars: vars) else {
            return nil
        }
        
        return Calendar.current.dateComponents([.year, .month], from: Date()) == Calendar.current.dateComponents([.year, .month], from: profile.updatedAt) ? profile : nil
    }
    
    public var history: History? {
        guard let vars = Defaults[.accountHistory(of: identifier)] else {
            return nil
        }
        return History(vars: vars)
    }
    
    init(configuration: Configuration, username: String) {
        self.configuration = configuration
        self.username = username
        self.identifier = "\(configuration.identifier).\(username)"
    }
    
    public func login(on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {

        guard let action = configuration.actions[.login] else {
            print("Login action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging in for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).recover(on: queue) { error -> Promise<[String: Any]> in
            
            print("Failed to login account \(self.identifier). Error: \(error).")
            
            if case CampNetError.unauthorized = error {
                self.unauthorized = true
            }
            
            throw error
        }
        .then(on: queue) { _ in
            return self.status(on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { status in
            guard case .online = status.type else {
                throw CampNetError.unknown
            }
            return Promise(value: ())
        }
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
            
            Defaults[.accountStatus(of: self.identifier)] = vars
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountStatusUpdated, object: self, userInfo: ["account": self, "status": status])
            }
            
            return Promise(value: status)
        }
        .recover(on: queue) { error -> Promise<Status> in
            print("Failed to update status for account \(self.identifier). Error: \(error).")
            
            if case CampNetError.unauthorized = error {
                self.unauthorized = true
            }
            
            throw error
        }
    }
    
    public func profile(on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Profile> {
        
        guard let action = configuration.actions[.profile] else {
            print("Profile action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Updating profile for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then(on: queue) { vars in
            
var vars = vars
vars["ips"] = ["59.66.141.91", "166.111.11.15"]
vars["macs"] = ["78:4f:43:51:83:89", "78:4f:43:51:83:89"]
vars["start_times"] = [Date(), Date()]
vars["usages"] = [123234, 234234334]
vars["devices"] = ["iPhone", "iPad"]

            guard let profile = Profile(vars: vars) else {
                print("No profile in vars (\(vars)).")
                throw CampNetError.invalidConfiguration
            }
            
            Defaults[.accountProfile(of: self.identifier)] = vars
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountProfileUpdated, object: self, userInfo: ["account": self, "profile": profile])
            }
            
            return Promise(value: profile)
        }
        .recover(on: queue) { error -> Promise<Profile> in
            print("Failed to update profile for account \(self.identifier). Error: \(error).")
            
            if case CampNetError.unauthorized = error {
                self.unauthorized = true
            }
            
            throw error
        }
    }
    
    public func login(ip: String, on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {
        
        guard let action = configuration.actions[.loginIp] else {
            print("LoginIp action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging in IP \(ip) for \(identifier).")
        
        return action.commit(username: username, password: password, extraVars: ["ip": ip], on: queue, requestBinder: requestBinder).recover(on: queue) { error -> Promise<[String: Any]> in
            
            print("Failed to login IP \(ip) for account \(self.identifier). Error: \(error).")
            
            if case CampNetError.unauthorized = error {
                self.unauthorized = true
            }
            
            throw error
        }
        .then { _ in
            if self.configuration.actions[.profile] != nil {
                return self.profile(on: queue, requestBinder: requestBinder).then(on: queue) { profile in
                    guard profile.sessions.map({ $0.ip }).contains(ip) else {
                        throw CampNetError.unknown
                    }
                    return Promise(value: ())
                }
            } else {
                return Promise(value: ())
            }
        }
    }
    
    public func logoutSession(session: Session, on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {
        
        guard let action = configuration.actions[.logoutSession] else {
            print("LogoutSession action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging out \(session) for \(identifier).")
        
        return action.commit(username: username, password: password, extraVars: ["ip": session.ip, "id": session.id ?? ""], on: queue, requestBinder: requestBinder).recover(on: queue) { error -> Promise<[String: Any]> in
            
            print("Failed to logout session \(session) for account \(self.identifier). Error: \(error).")
            
            if case CampNetError.unauthorized = error {
                self.unauthorized = true
            }
            
            throw error
        }
        .then { _ in
            return self.profile(on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { profile in
            guard !profile.sessions.map({ $0.ip }).contains(session.ip) else {
                throw CampNetError.unknown
            }
            return Promise(value: ())
        }
    }
    
    public func history(on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<History> {
        
        guard let action = configuration.actions[.history] else {
            print("History action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Fetching history for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then(on: queue) { vars in
            guard let history = History(vars: vars) else {
                print("No history in vars (\(vars)).")
                throw CampNetError.invalidConfiguration
            }
            
            Defaults[.accountHistory(of: self.identifier)] = vars
            if !history.usageSums.isEmpty && history.usageSums.count >= Account.estimationLength + 2 {
                let toIndex = history.usageSums.count - 2  // Avoid today.
                let fromIndex = toIndex - Account.estimationLength
                let usage = history.usageSums[toIndex] - history.usageSums[fromIndex]
                self.estimatedDailyUsage = usage / Account.estimationLength
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountHistoryUpdated, object: self, userInfo: ["account": self, "history": history])
            }
            
            return Promise(value: history)
        }
        .recover(on: queue) { error -> Promise<History> in
            print("Failed to update history for account \(self.identifier). Error: \(error).")
            
            if case CampNetError.unauthorized = error {
                self.unauthorized = true
            }
            
            throw error
        }
    }
    
    public func logout(on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {
        
        guard let action = configuration.actions[.logout] else {
            print("Logout action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging out for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).recover(on: queue) { error -> Promise<[String: Any]> in
            
            print("Failed to logout for account \(self.identifier). Error: \(error).")
            
            if case CampNetError.unauthorized = error {
                self.unauthorized = true
            }
            
            throw error
        }
        .then(on: queue) { _ in
            return self.status(on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { status in
            guard case .offline = status.type else {
                throw CampNetError.unknown
            }
            return Promise(value: ())
        }

    }
}

extension Account: Hashable {
    public var hashValue: Int {
        return identifier.hashValue
    }
    
    public static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
