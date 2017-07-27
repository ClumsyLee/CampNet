//
//  Account.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/10.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import NetworkExtension

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
    
    public static var handler: NEHotspotHelperHandler = { command in
        print("NEHotspotHelperCommand \(command.commandType) received.")
        
        let requestBinder: RequestBinder = { $0.bind(to: command) }
        
        switch command.commandType {
            
        case .filterScanList:
            guard let networkList = command.networkList,
                let account = Account.main else {
                    let response = command.createResponse(.success)
                    response.deliver()
                    return
            }
            
            var knownList: [NEHotspotNetwork] = []
            for network in networkList {
                if account.canManage(network) {
                    network.setConfidence(.low)
                    knownList.append(network)
                }
            }
            print("Known networks: \(knownList).")
            
            let response = command.createResponse(.success)
            response.setNetworkList(knownList)
            response.deliver()
            
        case .evaluate:
            guard let network = command.network else {
                return
            }
            guard let account = Account.main, account.canManage(network) else {
                network.setConfidence(.none)
                let response = command.createResponse(.success)
                response.setNetwork(network)
                response.deliver()
                return
            }
            
            account.status(requestBinder: requestBinder).then { status -> Void in
                switch status.type {
                case .online, .offline:
                    network.setConfidence(.high)
                case .offcampus:
                    network.setConfidence(.none)
                }
                
                let response = command.createResponse(.success)
                response.setNetwork(network)
                response.deliver()
                }
                .catch { _ in
                    network.setConfidence(.low)
                    
                    let response = command.createResponse(.success)
                    response.setNetwork(network)
                    response.deliver()
            }
            
        case .authenticate:
            guard let network = command.network else {
                return
            }
            guard let account = Account.main, account.canManage(network) else {
                command.createResponse(.unsupportedNetwork).deliver()
                return
            }
            
            account.login(requestBinder: requestBinder).then {
                command.createResponse(.success).deliver()
                }
                .catch { _ in
                    command.createResponse(.temporaryFailure).deliver()
            }
            
        case .maintain:
            guard let network = command.network else {
                return
            }
            guard let account = Account.main, account.canManage(network) else {
                command.createResponse(.failure).deliver()
                return
            }
            
            account.status(requestBinder: requestBinder).then { status -> Void in
                let result: NEHotspotHelperResult
                
                switch status.type {
                case .online: result = .success
                case .offline: result = .authenticationRequired
                case .offcampus: result = .failure
                }
                
                command.createResponse(result).deliver()
                }
                .catch { _ in
                    command.createResponse(.failure).deliver()
            }
            
        case .logoff:
            guard let network = command.network else {
                return
            }
            guard let account = Account.main, account.canManage(network) else {
                command.createResponse(.failure).deliver()
                return
            }
            
            account.logout(requestBinder: requestBinder).then {
                command.createResponse(.success).deliver()
                }
                .catch { _ in
                    command.createResponse(.failure).deliver()
            }
            
        default: break
        }
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
    
    public fileprivate(set) var status: Status? {
        get {
            guard let vars = Defaults[.accountStatus(of: identifier)],
                  let status = Status(vars: vars) else {
                return nil
            }
            
            return -status.updatedAt.timeIntervalSinceNow <= Account.statusLifetime ? status : nil
        }
        set {
            Defaults[.accountStatus(of: identifier)] = newValue?.vars
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountStatusUpdated, object: self, userInfo: ["account": self, "status": newValue as Any])
            }
        }
    }
    
    public fileprivate(set) var profile: Profile? {
        get {
            guard let vars = Defaults[.accountProfile(of: identifier)],
                  let profile = Profile(vars: vars) else {
                return nil
            }
            
            return Calendar.current.dateComponents([.year, .month], from: Date()) == Calendar.current.dateComponents([.year, .month], from: profile.updatedAt) ? profile : nil
        }
        set {
            Defaults[.accountProfile(of: identifier)] = newValue?.vars
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountProfileUpdated, object: self, userInfo: ["account": self, "profile": newValue as Any])
            }
        }
    }
    
    public fileprivate(set) var history: History? {
        get {
            guard let vars = Defaults[.accountHistory(of: identifier)],
                  let history = History(vars: vars) else {
                return nil
            }
            
            let today = Date()
            return (history.year == Calendar.current.component(.year, from: today) &&
                    history.month == Calendar.current.component(.month, from: today)) ? history : nil
        }
        set {
            if let history = newValue {
                if !history.usageSums.isEmpty && history.usageSums.count >= Account.estimationLength + 2 {
                    let toIndex = history.usageSums.count - 2  // Avoid today.
                    let fromIndex = toIndex - Account.estimationLength
                    let usage = history.usageSums[toIndex] - history.usageSums[fromIndex]
                    
                    self.estimatedDailyUsage = usage / Account.estimationLength
                }
            }
            
            Defaults[.accountHistory(of: identifier)] = newValue?.vars
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountHistoryUpdated, object: self, userInfo: ["account": self, "history": newValue as Any])
            }
        }
    }
    
    init(configuration: Configuration, username: String) {
        self.configuration = configuration
        self.username = username
        self.identifier = "\(configuration.identifier).\(username)"
    }
    
    func handle(error: Error, name: Notification.Name) {
        if let error = error as? CampNetError {
            switch error {
            case .unauthorized: self.unauthorized = true
            case .offcampus: self.status = Status(type: .offcampus)
            default: break
            }
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: self, userInfo: ["account": self, "error": error])
        }
    }
    
    public func login(on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {

        guard let action = configuration.actions[.login] else {
            print("Login action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging in for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).recover(on: queue) { error -> Promise<[String: Any]> in
            
            print("Failed to login account \(self.identifier). Error: \(error).")
            self.handle(error: error, name: .accountLoginError)
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
            self.status = status
            return Promise(value: status)
        }
        .recover(on: queue) { error -> Promise<Status> in
            if case CampNetError.offcampus = error {
                let status = Status(type: .offcampus)
                self.status = status
                return Promise(value: status)
            }
            
            print("Failed to update status for account \(self.identifier). Error: \(error).")
            self.handle(error: error, name: .accountStatusError)
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

            guard let profile = Profile(vars: vars) else {
                print("No profile in vars (\(vars)).")
                throw CampNetError.invalidConfiguration
            }
            self.profile = profile
            return Promise(value: profile)
        }
        .recover(on: queue) { error -> Promise<Profile> in
            print("Failed to update profile for account \(self.identifier). Error: \(error).")
            self.handle(error: error, name: .accountProfileError)
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
            self.handle(error: error, name: .accountLoginIpError)
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
            self.handle(error: error, name: .accountLogoutSessionError)
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
            self.history = history
            return Promise(value: history)
        }
        .recover(on: queue) { error -> Promise<History> in
            print("Failed to update history for account \(self.identifier). Error: \(error).")
            self.handle(error: error, name: .accountHistoryError)
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
            self.handle(error: error, name: .accountLogoutError)
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
    
    public func update(on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {
        
        // Here we run actions in order to make sure important actions will be executed.
        var promise = status(on: queue, requestBinder: requestBinder).asVoid()
        
        if configuration.actions[.profile] != nil {
            promise = promise.then { self.profile().asVoid() }
        }
        
        if configuration.actions[.history] != nil {
            promise = promise.then { self.history().asVoid() }
        }
        
        return promise
    }
    
    public func canManage(_ network: NEHotspotNetwork) -> Bool {
        return configuration.ssids.contains(network.ssid) && !network.isSecure
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
