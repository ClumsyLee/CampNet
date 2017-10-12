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
    static let profileAutoUpdateInterval: TimeInterval = 600
    static let estimationLength = 7

    static let passwordKeychain = Keychain(service: "\(Configuration.bundleIdentifier).password",
                                           accessGroup: Configuration.keychainAccessGroup)

    public static var identifier: String? {
        return Defaults[.mainAccount]
    }

    public static func decimalUnits(of identifier: String) -> Bool {
        return Defaults[.accountDecimalUnits(of: identifier)]
    }

    public static func status(of identifier: String) -> Status? {
        guard let vars = Defaults[.accountStatus(of: identifier)] else {
            return nil
        }
        return Status(vars: vars)
    }

    public static func profile(of identifier: String) -> Profile? {
        guard let vars = Defaults[.accountProfile(of: identifier)], let profile = Profile(vars: vars) else {
            return nil
        }
        return (Device.inUITest ||
                Calendar.current.dateComponents([.year, .month], from: Date()) ==
                Calendar.current.dateComponents([.year, .month], from: profile.updatedAt)) ? profile : nil
    }

    public static func history(of identifier: String) -> History? {
        guard let vars = Defaults[.accountHistory(of: identifier)], let history = History(vars: vars) else {
            return nil
        }
        let today = Date()
        return (Device.inUITest ||
                history.year == Calendar.current.component(.year, from: today) &&
                history.month == Calendar.current.component(.month, from: today)) ? history : nil
    }

    public static func freeUsage(of identifier: String) -> Int64? {
        return Defaults[.accountFreeUsage(of: identifier)]
    }

    public static func maxUsage(of identifier: String) -> Int64? {
        return Defaults[.accountMaxUsage(of: identifier)]
    }

    public static var all: [Configuration: [Account]] {
        return AccountManager.shared.all
    }

    public static var main: Account? {
        return AccountManager.shared.main
    }

    public static func add(configurationIdentifier: String, username: String, password: String? = nil) {
        AccountManager.shared.add(configurationIdentifier: configurationIdentifier, username: username,
                                  password: password)
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
            Defaults[.accountLastLoginErrorNotification(of: identifier)] = nil
            log.debug("\(self): Password changed.")
        }
    }

    public fileprivate(set) var estimatedDailyUsage: Int64? {
        get {
            return Defaults[.accountEstimatedDailyUsage(of: identifier)]
        }
        set {
            Defaults[.accountEstimatedDailyUsage(of: identifier)] = newValue
            Defaults.synchronize()
            log.debug("\(self): Estimated daily usage changed to \(newValue?.description ?? "nil").")
        }
    }

    public fileprivate(set) var freeUsage: Int64? {
        get {
            return Defaults[.accountFreeUsage(of: identifier)]
        }
        set {
            Defaults[.accountFreeUsage(of: identifier)] = newValue
            Defaults.synchronize()
            log.debug("\(self): Free usage changed to \(newValue?.description ?? "nil").")
        }
    }

    public fileprivate(set) var maxUsage: Int64? {
        get {
            return Defaults[.accountMaxUsage(of: identifier)]
        }
        set {
            Defaults[.accountMaxUsage(of: identifier)] = newValue
            Defaults.synchronize()
            log.debug("\(self): Max usage changed to \(newValue?.description ?? "nil").")
        }
    }

    public fileprivate(set) var pastIps: [String] {
        get {
            return Defaults[.accountPastIps(of: identifier)]
        }
        set {
            Defaults[.accountPastIps(of: identifier)] = newValue
            Defaults.synchronize()
            log.debug("\(self): Past IPs changed to \(newValue.description).")
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
            Defaults.synchronize()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountStatusUpdated, object: self,
                                                userInfo: ["account": self, "status": newValue as Any])
            }
            log.debug("\(self): Status changed to \(newValue?.description ?? "nil").")
        }
    }

    public fileprivate(set) var profile: Profile? {
        get {
            return Account.profile(of: identifier)
        }
        set {
            // Update free usage & max usage if possible.
            var freeUsage: Int64? = nil
            var maxUsage: Int64? = nil

            if let profile = newValue, let billingGroup = configuration.billingGroups[profile.billingGroupName ?? ""] {
                freeUsage = billingGroup.freeUsage

                if let balance = profile.balance, let usage = profile.usage {
                    maxUsage = billingGroup.maxUsage(balance: balance, usage: usage)
                }
            }

            self.freeUsage = freeUsage
            self.maxUsage = maxUsage


            let oldUsage = Profile(vars: Defaults[.accountProfile(of: identifier)] ?? [:])?.usage ?? -1
            Defaults[.accountProfile(of: identifier)] = newValue?.vars
            Defaults.synchronize()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountProfileUpdated, object: self,
                                                userInfo: ["account": self, "profile": newValue as Any])
            }
            log.debug("\(self): Profile changed to \(newValue?.description ?? "nil").")

            // Send usage alert if needed.
            if let newUsage = newValue?.usage,
               let ratio = Defaults[.usageAlertRatio],
               let maxUsage = maxUsage {

                let limit = Int64(Double(maxUsage) * ratio)
                if oldUsage < limit && newUsage >= limit {
                    // Should send.
                    log.info("\(self): Reached the usage alert limit (\(oldUsage) => \(newUsage), limit: \(limit)).")

                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .accountUsageAlert, object: self,
                                                        userInfo: ["account": self, "usage": newUsage,
                                                                   "maxUsage": maxUsage])
                    }
                }
            }
        }
    }

    public fileprivate(set) var history: History? {
        get {
            return Account.history(of: identifier)
        }
        set {
            if let history = newValue {
                if !history.usageSums.isEmpty && history.usageSums.count >= Account.estimationLength + 2 {
                    let toIndex = history.usageSums.count - 2  // Avoid today.
                    let fromIndex = toIndex - Account.estimationLength
                    let usage = history.usageSums[toIndex] - history.usageSums[fromIndex]

                    estimatedDailyUsage = usage / Int64(Account.estimationLength)
                }
            }

            Defaults[.accountHistory(of: identifier)] = newValue?.vars
            Defaults.synchronize()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountHistoryUpdated, object: self,
                                                userInfo: ["account": self, "history": newValue as Any])
            }
            log.debug("\(self): History changed to \(newValue?.description ?? "nil").")
        }
    }

    public var shouldAutoUpdate: Bool {
        if let profile = profile {
            return -profile.updatedAt.timeIntervalSinceNow > Account.profileAutoUpdateInterval
        } else {
            return true
        }
    }

    init(configuration: Configuration, username: String) {
        self.configuration = configuration
        self.username = username
        self.identifier = "\(configuration.identifier).\(username)"

        Defaults[.accountDecimalUnits(of: identifier)] = configuration.decimalUnits
    }

    public func canManage(network: NEHotspotNetwork) -> Bool {
        return (configuration.ssids.contains(network.ssid) ||
                Defaults[.onCampus(id: configuration.identifier, ssid: network.ssid)]) &&
               Defaults[.autoLogin]
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

        let estimatedUsage = min(usage + estimatedDailyUsage * Int64(maxDay - Calendar.current.component(.day,
                                                                                                         from: today)),
                                 billingGroup.maxUsage(balance: balance, usage: usage))
        return billingGroup.fee(from: usage, to: estimatedUsage)
    }
}


extension Account: CustomStringConvertible {
    public var description: String {
        return identifier
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


// Network requests related functions.
extension Account {

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

        // Here send the errors in sync, so that error notifications are sent before return.
        DispatchQueue.main.sync {
            NotificationCenter.default.post(name: name, object: self, userInfo: userInfo)
        }
    }

    public func login(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .utility),
                      requestBinder: RequestBinder? = nil) -> Promise<Void> {

        return firstly { () -> Promise<[String: Any]> in
            guard let action = configuration.actions[.login] else {
                log.error("\(self) does not have a login action.")
                throw CampNetError.invalidConfiguration
            }
            log.debug("\(self): Logging in.")

            return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { _ -> Promise<Status> in
            return self.status(isSubaction: true, on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { status -> Void in
            guard case .online = status.type else {
                log.warning("\(self): Login action finished successfully, but status check failed.")
                throw CampNetError.unknown("")
            }

            Defaults[.accountLastLoginErrorNotification(of: self.identifier)] = nil
            Defaults.synchronize()
            log.info("\(self): Logged in.")
        }
        .recover(on: queue) { error -> Void in
            log.warning("\(self): Failed to login: \(error)")

            if !isSubaction {
                self.handle(error: error, name: .accountLoginError)
            }
            throw error
        }
    }

    public func status(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .utility),
                       requestBinder: RequestBinder? = nil) -> Promise<Status> {

        return firstly { () -> Promise<[String: Any]> in
            guard let action = configuration.actions[.status] else {
                log.error("\(self): No status action.")
                throw CampNetError.invalidConfiguration
            }
            log.debug("\(self): Updating status.")

            return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { vars -> Status in
            guard let status = Status(vars: vars) else {
                log.error("\(self): No status in vars (\(vars)).")
                throw CampNetError.invalidConfiguration
            }
            self.status = status
            log.info("\(self): Status updated.")
            return status
        }
        .recover(on: queue) { error -> Status in
            if let error = error as? CampNetError, case .offcampus = error {
                let status = Status(type: .offcampus)
                self.status = status
                log.info("\(self): Status updated.")
                return status
            }

            log.warning("\(self): Failed to update status: \(error)")

            if !isSubaction {
                self.handle(error: error, name: .accountStatusError)
            }
            throw error
        }
    }

    public func profile(isSubaction: Bool = false, autoLogout: Bool = true,
                        on queue: DispatchQueue = DispatchQueue.global(qos: .utility),
                        requestBinder: RequestBinder? = nil) -> Promise<Profile> {

        return firstly { () -> Promise<[String: Any]> in
            guard let action = configuration.actions[.profile] else {
                log.error("\(self): No profile action.")
                throw CampNetError.invalidConfiguration
            }
            log.debug("\(self): Updating profile.")

            return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { vars -> Profile in
            guard let profile = Profile(vars: vars) else {
                log.error("\(self): No profile in vars (\(vars)).")
                throw CampNetError.invalidConfiguration
            }

            // update past IPs, logout expired sessions if needed.
            if let sessions = profile.sessions {
                self.updatePastIps(sessions: sessions, autoLogout: autoLogout, on: queue, requestBinder: requestBinder)
            }

            self.profile = profile
            log.debug("\(self): Profile updated.")
            return profile
        }
        .recover(on: queue) { error -> Profile in
            log.warning("\(self): Failed to update profile: \(error)")

            if !isSubaction {
                self.handle(error: error, name: .accountProfileError)
            }
            throw error
        }
    }

    public func login(ip: String, isSubaction: Bool = false,
                      on queue: DispatchQueue = DispatchQueue.global(qos: .utility),
                      requestBinder: RequestBinder? = nil) -> Promise<Void> {

        return firstly { () -> Promise<[String: Any]> in
            guard let action = configuration.actions[.loginIp] else {
                log.error("\(self): No loginIp action.")
                throw CampNetError.invalidConfiguration
            }
            log.debug("\(self): Logging in \(ip).")

            return action.commit(username: username, password: password, extraVars: ["ip": ip], on: queue,
                                 requestBinder: requestBinder)
        }
        .then(on: queue) { _ in
            return self.profile(isSubaction: true, on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { profile -> Void in
            // Check sessions if possible.
            if let sessions = profile.sessions {
                guard sessions.map({ $0.ip }).contains(ip) else {
                    log.warning("\(self): Login IP action finished successfully, but profile check failed.")
                    throw CampNetError.unknown("")
                }
            }

            log.info("\(self): \(ip) logged in.")
        }
        .recover(on: queue) { error -> Void in
            log.warning("\(self): Failed to login \(ip): \(error)")

            if !isSubaction {
                self.handle(error: error, name: .accountLoginIpError, extraInfo: ["ip": ip])
            }
            throw error
        }
    }

    public func logoutSession(session: Session, isSubaction: Bool = false,
                              on queue: DispatchQueue = DispatchQueue.global(qos: .utility),
                              requestBinder: RequestBinder? = nil) -> Promise<Void> {

        return firstly { () -> Promise<[String: Any]> in
            guard let action = configuration.actions[.logoutSession] else {
                log.error("\(self): No logoutSession action.")
                throw CampNetError.invalidConfiguration
            }
            log.debug("\(self): Logging out \(session).")

            return action.commit(username: username, password: password,
                                 extraVars: ["ip": session.ip, "id": session.id ?? ""], on: queue,
                                 requestBinder: requestBinder)
        }
        .then(on: queue) { _ in
            // Do not autoLogout to avoid recursions.
            return self.profile(isSubaction: true, autoLogout: false, on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { profile -> Void in
            // Check sessions if possible.
            if let sessions = profile.sessions {
                guard !sessions.map({ $0.ip }).contains(session.ip) else {
                    log.warning("\(self): Logout session action finished successfully, but profile check failed.")
                    throw CampNetError.unknown("")
                }
            }

            log.info("\(self): \(session) logged out.")
        }
        .recover(on: queue) { error -> Void in
            log.warning("\(self): Failed to logout \(session): \(error)")

            if !isSubaction {
                self.handle(error: error, name: .accountLogoutSessionError, extraInfo: ["session": session])
            }
            throw error
        }
    }

    public func history(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .utility),
                        requestBinder: RequestBinder? = nil) -> Promise<History> {

        return firstly { () -> Promise<[String: Any]> in
            guard let action = configuration.actions[.history] else {
                log.error("\(self): No history action.")
                throw CampNetError.invalidConfiguration
            }
            log.debug("\(self): Updating history.")

            return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { vars -> History in
            guard let history = History(vars: vars) else {
                log.error("\(self): No history in vars (\(vars)).")
                throw CampNetError.invalidConfiguration
            }
            self.history = history
            log.debug("\(self): History updated.")
            return history
        }
        .recover(on: queue) { error -> History in
            log.warning("\(self): Failed to update history: \(error).")

            if !isSubaction {
                self.handle(error: error, name: .accountHistoryError)
            }
            throw error
        }
    }

    public func logout(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .utility),
                       requestBinder: RequestBinder? = nil) -> Promise<Void> {

        return firstly { () -> Promise<[String: Any]> in
            guard let action = configuration.actions[.logout] else {
                log.error("\(self): No logout action.")
                throw CampNetError.invalidConfiguration
            }
            log.debug("\(self): Logging out.")

            return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { _ in
            return self.status(isSubaction: true, on: queue, requestBinder: requestBinder)
        }
        .then(on: queue) { status -> Void in
            guard case .offline = status.type else {
                log.warning("\(self): Logout action finished successfully, but status check failed.")
                throw CampNetError.unknown("")
            }

            log.info("\(self): Logged out.")
        }
        .recover(on: queue) { error -> Void in
            log.warning("\(self): Failed to logout: \(error).")

            if !isSubaction {
                self.handle(error: error, name: .accountLogoutError)
            }
            throw error
        }
    }

    public func update(skipStatus: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .utility),
                       requestBinder: RequestBinder? = nil) -> Promise<Void> {

        var promise = Promise()

        // Here we run actions in order to make sure important actions will be executed.
        if !skipStatus {
            promise = promise.then(on: queue) { return self.status(on: queue, requestBinder: requestBinder).asVoid() }
        }

        if configuration.actions[.profile] != nil {
            promise = promise.then(on: queue) { return self.profile(on: queue, requestBinder: requestBinder).asVoid() }
        }

        if configuration.actions[.history] != nil {
            if let history = history, history.usageSums.count >= Calendar.current.component(.day, from: Date()) {
                // History still valid, do nothing.
            } else {
                promise = promise.then(on: queue) { self.history(on: queue, requestBinder: requestBinder).asVoid() }
            }
        }

        return promise
    }

    public func updateIfNeeded(on queue: DispatchQueue = DispatchQueue.global(qos: .utility),
                               requestBinder: RequestBinder? = nil) -> Promise<Void> {
        return shouldAutoUpdate ? update(skipStatus: true, on: queue, requestBinder: requestBinder)
                                : Promise()
    }

    private func updatePastIps(sessions: [Session], autoLogout: Bool, on queue: DispatchQueue,
                                   requestBinder: RequestBinder?) {
        let ips = sessions.map { $0.ip }
        let currentIp = WiFi.ip

        var ipsToLogout = pastIps.filter { ips.contains($0) && $0 != currentIp }

        if configuration.actions[.logoutSession] != nil, Defaults[.autoLogoutExpiredSessions], autoLogout {
            var promise = Promise<Void>(value: ())
            for session in sessions {
                if ipsToLogout.contains(session.ip) {
                    promise = promise.then(on: queue) {
                        return self.logoutSession(session: session, on: queue, requestBinder: requestBinder)
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
