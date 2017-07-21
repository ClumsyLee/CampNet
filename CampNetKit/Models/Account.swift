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
            guard case .online = status else {
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
            
            Defaults[.accountProfile(of: self.identifier)] = vars
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
            guard case .offline = status else {
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
