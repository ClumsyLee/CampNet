//
//  Account.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/10.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import NetworkExtension
import UserNotifications

import NetUtils
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
        
        let queue = DispatchQueue.global(qos: .utility)
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
                if account.canManage(network: network) {
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
            guard let account = Account.main, account.canManage(network: network) else {
                network.setConfidence(.none)
                let response = command.createResponse(.success)
                response.setNetwork(network)
                response.deliver()
                return
            }
            
            account.status(on: queue, requestBinder: requestBinder).then(on: queue) { status -> Void in
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
            .catch(on: queue) { _ in
                network.setConfidence(.low)
                
                let response = command.createResponse(.success)
                response.setNetwork(network)
                response.deliver()
            }
            
        case .authenticate:
            guard let network = command.network else {
                return
            }
            guard let account = Account.main, account.canManage(network: network) else {
                command.createResponse(.unsupportedNetwork).deliver()
                return
            }
            
            account.login(on: queue, requestBinder: requestBinder).then(on: queue) { () -> Void in
                if account.configuration.actions[.profile] != nil {
                    account.profile(on: queue, requestBinder: requestBinder).always(on: queue) {
                        command.createResponse(.success).deliver()
                    }
                } else {
                    command.createResponse(.success).deliver()
                }
            }
            .catch(on: queue) { _ in
                command.createResponse(.temporaryFailure).deliver()
            }
            
        case .maintain:
            guard let network = command.network else {
                return
            }
            guard let account = Account.main, account.canManage(network: network) else {
                command.createResponse(.failure).deliver()
                return
            }
            
            account.status(on: queue, requestBinder: requestBinder).then(on: queue) { status -> Void in
                let result: NEHotspotHelperResult
                
                switch status.type {
                case .online: result = .success
                case .offline: result = .authenticationRequired
                case .offcampus: result = .failure
                }
                
                if result == .success && account.configuration.actions[.profile] != nil {
                    account.profile(on: queue, requestBinder: requestBinder).always(on: queue) {
                        command.createResponse(result).deliver()
                    }
                } else {
                    command.createResponse(result).deliver()
                }
            }
            .catch(on: queue) { _ in
                command.createResponse(.failure).deliver()
            }
            
        case .logoff:
            guard let network = command.network else {
                return
            }
            guard let account = Account.main, account.canManage(network: network) else {
                command.createResponse(.failure).deliver()
                return
            }
            
            account.logout(on: queue, requestBinder: requestBinder).then(on: queue) {
                command.createResponse(.success).deliver()
            }
            .catch(on: queue) { _ in
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
        }
    }
    
    public fileprivate(set) var estimatedDailyUsage: Int? {
        get {
            return Defaults[.accountEstimatedDailyUsage(of: identifier)]
        }
        set {
            Defaults[.accountEstimatedDailyUsage(of: identifier)] = newValue
        }
    }
    
    public fileprivate(set) var pastIps: [String] {
        get {
            return Defaults[.accountPastIps(of: identifier)]
        }
        set {
            Defaults[.accountPastIps(of: identifier)] = newValue
        }
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
            print("\(identifier) status changed: \(newValue as Any)")
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
            let oldVars = Defaults[.accountProfile(of: identifier)]
            Defaults[.accountProfile(of: identifier)] = newValue?.vars
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountProfileUpdated, object: self, userInfo: ["account": self, "profile": newValue as Any])
            }
            print("\(identifier) profile changed: \(newValue as Any)")
            
            // Send usage alert if needed.
            let oldUsage = Profile(vars: oldVars ?? [:])?.usage ?? -1
            if let newUsage = newValue?.usage,
               let ratio = Defaults[.usageAlertRatio],
               let maxUsage = maxUsage(profile: newValue) {
                
                let limit = Int(Double(maxUsage) * ratio)
                if oldUsage < limit && newUsage >= limit {
                    // Should send.
                    let percentage = Int((Double(newUsage) / Double(maxUsage)) * 100.0)
                    let usageLeft = (maxUsage - newUsage).usageString(decimalUnits: configuration.decimalUnits)
                    let content = UNMutableNotificationContent()
                    
                    content.title = String.localizedStringWithFormat(NSLocalizedString("\"%@\" has used %d%% of maximum usage", comment: "Usage alert title."), username, percentage)
                    content.body = String.localizedStringWithFormat(NSLocalizedString("Up to %@ can still be used this month.", comment: "Usage alert body."), usageLeft)
                    content.sound = UNNotificationSound.default()

                    let request = UNNotificationRequest(identifier: "\(identifier).usageAlert", content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
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
    
    func handle(error: Error, name: Notification.Name, extraInfo: [String: Any]? = nil) {
        if let error = error as? CampNetError {
            switch error {
            case .offcampus: self.status = Status(type: .offcampus)
            default: break
            }
        }
        
        var userInfo: [String: Any] = ["account": self, "error": error]
        if let extraInfo = extraInfo {
            for (key, value) in extraInfo {
                userInfo[key] = value
            }
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: self, userInfo: userInfo)
        }
    }
    
    public func login(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {

        guard let action = configuration.actions[.login] else {
            print("Login action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging in for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then(on: queue) { _ in
            return self.status(isSubaction: true, on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { status -> Void in
            guard case .online = status.type else {
                throw CampNetError.unknown
            }
        }
        .recover(on: queue) { error -> Void in
            print("Failed to login account \(self.identifier). Error: \(error).")
            if !isSubaction {
                self.handle(error: error, name: .accountLoginError)
            }
            throw error
        }
    }
    
    public func status(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Status> {
        
        guard let action = configuration.actions[.status] else {
            print("Status action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Updating status for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then(on: queue) { vars -> Status in
            
            guard let status = Status(vars: vars) else {
                print("No status in vars (\(vars)).")
                throw CampNetError.invalidConfiguration
            }
            self.status = status
            return status
        }
        .recover(on: queue) { error -> Status in
            if case CampNetError.offcampus = error {
                let status = Status(type: .offcampus)
                self.status = status
                return status
            }
            
            print("Failed to update status for account \(self.identifier). Error: \(error).")
            if !isSubaction {
                self.handle(error: error, name: .accountStatusError)
            }
            throw error
        }
    }
    
    public func profile(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Profile> {
        
        guard let action = configuration.actions[.profile] else {
            print("Profile action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Updating profile for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then(on: queue) { vars -> Profile in

            guard let profile = Profile(vars: vars) else {
                print("No profile in vars (\(vars)).")
                throw CampNetError.invalidConfiguration
            }
            // Logout expired sessions if needed.
            // Do not perform in subactions to avoid recursions.
            if let sessions = profile.sessions, !isSubaction {
                self.updatePastIps(sessions: sessions, on: queue)
            }
            
            self.profile = profile
            return profile
        }
        .recover(on: queue) { error -> Profile in
            print("Failed to update profile for account \(self.identifier). Error: \(error).")
            if !isSubaction {
                self.handle(error: error, name: .accountProfileError)
            }
            throw error
        }
    }
    
    public func login(ip: String, isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {
        
        guard let action = configuration.actions[.loginIp] else {
            print("LoginIp action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging in IP \(ip) for \(identifier).")
        
        return action.commit(username: username, password: password, extraVars: ["ip": ip], on: queue, requestBinder: requestBinder).then(on: queue) { _ in
            if self.configuration.actions[.profile] != nil {
                return self.profile(isSubaction: true, on: queue, requestBinder: requestBinder).then(on: queue) { profile -> Void in
                    // Check sessions if possible.
                    if let sessions = profile.sessions {
                        guard sessions.map({ $0.ip }).contains(ip) else {
                            throw CampNetError.unknown
                        }
                    }
                }
            } else {
                return Promise(value: ())
            }
        }
        .recover(on: queue) { error -> Void in
            print("Failed to login IP \(ip) for account \(self.identifier). Error: \(error).")
            if !isSubaction {
                self.handle(error: error, name: .accountLoginIpError, extraInfo: ["ip": ip])
            }
            throw error
        }
    }
    
    public func logoutSession(session: Session, isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {
        
        guard let action = configuration.actions[.logoutSession] else {
            print("LogoutSession action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging out \(session) for \(identifier).")
        
        return action.commit(username: username, password: password, extraVars: ["ip": session.ip, "id": session.id ?? ""], on: queue, requestBinder: requestBinder).then(on: queue) { _ in
            return self.profile(isSubaction: true, on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { profile -> Void in
            // Check sessions if possible.
            if let sessions = profile.sessions {
                guard !sessions.map({ $0.ip }).contains(session.ip) else {
                    throw CampNetError.unknown
                }
            }
        }
        .recover(on: queue) { error -> Void in
            print("Failed to logout session \(session) for account \(self.identifier). Error: \(error).")
            if !isSubaction {
                self.handle(error: error, name: .accountLogoutSessionError, extraInfo: ["session": session])
            }
            throw error
        }
    }
    
    public func history(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<History> {
        
        guard let action = configuration.actions[.history] else {
            print("History action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Fetching history for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then(on: queue) { vars -> History in
            guard let history = History(vars: vars) else {
                print("No history in vars (\(vars)).")
                throw CampNetError.invalidConfiguration
            }
            self.history = history
            return history
        }
        .recover(on: queue) { error -> History in
            print("Failed to update history for account \(self.identifier). Error: \(error).")
            if !isSubaction {
                self.handle(error: error, name: .accountHistoryError)
            }
            throw error
        }
    }
    
    public func logout(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {
        
        guard let action = configuration.actions[.logout] else {
            print("Logout action not found in \(configuration.identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        print("Logging out for \(identifier).")
        
        return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder).then(on: queue) { _ in
            return self.status(isSubaction: true, on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { status -> Void in
            guard case .offline = status.type else {
                throw CampNetError.unknown
            }
        }
        .recover(on: queue) { error -> Void in
            print("Failed to logout for account \(self.identifier). Error: \(error).")
            if !isSubaction {
                self.handle(error: error, name: .accountLogoutError)
            }
            throw error
        }
    }
    
    public func update(on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<Void> {
        
        // Here we run actions in order to make sure important actions will be executed.
        var promises = [status(on: queue, requestBinder: requestBinder).asVoid()]
        
        if configuration.actions[.profile] != nil {
            promises.append(profile(on: queue, requestBinder: requestBinder).asVoid())
        }
        
        if configuration.actions[.history] != nil {
            if let history = history, history.usageSums.count >= Calendar.current.component(.day, from: Date()) {
                // History still valid, do nothing.
            } else {
                promises.append(history(on: queue, requestBinder: requestBinder).asVoid())
            }
        }
        
        return when(resolved: promises).asVoid()
    }
    
    public func canManage(network: NEHotspotNetwork) -> Bool {
        return (configuration.ssids.contains(network.ssid) ||
                Defaults[.onCampus(id: configuration.identifier, ssid: network.ssid)]) &&
               Defaults[.autoLogin]
    }
    
    public func freeUsage(profile: Profile?) -> Int? {
        guard let profile = profile,
              let billingGroup = configuration.billingGroups[profile.billingGroupName ?? ""] else {
            return nil
        }
        
        return billingGroup.freeUsage
    }
    
    public func maxUsage(profile: Profile?) -> Int? {
        guard let profile = profile,
              let balance = profile.balance,
              let usage = profile.usage,
              let billingGroup = configuration.billingGroups[profile.billingGroupName ?? ""] else {
            return nil
        }
        
        return billingGroup.maxUsage(balance: balance, usage: usage)
    }
    
    public func estimatedFee(profile: Profile?) -> Double? {
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
        return billingGroup.fee(from: usage, to: estimatedUsage)
    }
    
    fileprivate func updatePastIps(sessions: [Session], on queue: DispatchQueue) {
        let ips = sessions.map { $0.ip }
        let currentIp = wifiIp()
        
        var ipsToLogout = pastIps.filter { ips.contains($0) && $0 != currentIp }
        
        if configuration.actions[.logoutSession] != nil, Defaults[.autoLogoutExpiredSessions] {
            var promise = Promise<Void>(value: ())
            for session in sessions {
                if ipsToLogout.contains(session.ip) {
                    promise = promise.then(on: queue) {
                        return self.logoutSession(session: session, on: queue)
                    }
                }
            }
        }
        
        if let currentIp = currentIp {
            ipsToLogout.append(currentIp)
        }
        pastIps = ipsToLogout
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
