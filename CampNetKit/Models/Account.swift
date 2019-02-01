//
//  Account.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/10.
//  Copyright © 2019年 Sihan Li. All rights reserved.
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
    public static let autoLoginInterval: TimeInterval = 10
    public static let profileAutoUpdateInterval: TimeInterval = 600
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

    public static var all: [Configuration: [Account]] {
        return AccountManager.shared.all
    }

    public static var main: Account? {
        return AccountManager.shared.main
    }

    public static func delegate(for network: NEHotspotNetwork) -> Account? {
        var delegate: Account? = nil

        for (configuration, accounts) in Account.all {
            guard !accounts.isEmpty && configuration.canManage(network) else {
                continue
            }
            // Make sure the custom configuration can override the presets.
            if configuration.identifier == Configuration.customIdentifier {
                return accounts[0]
            } else {
                delegate = accounts[0]
            }
        }

        return delegate
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
            if let profile = newValue {
                fakeHistoryIfNeeded(profile: profile)
            }

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
               let maxUsage = newValue?.maxUsage {

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

    fileprivate func fakeHistoryIfNeeded(profile: Profile) {
        guard let usage = profile.usage, self.configuration.actions[.history] == nil else {
            return
        }
        let year = Calendar.current.component(.year, from: profile.updatedAt)
        let month = Calendar.current.component(.month, from: profile.updatedAt)
        let day = Calendar.current.component(.day, from: profile.updatedAt)
        var history = self.history ?? History(year: year, month: month, usageSums: [])

        // Invalidate data points if needed.
        if year != history.year || month != history.month {
            history.usageSums = []
        }
        if history.usageSums.count >= day {
            history.usageSums.removeSubrange((day - 1)...)
        }

        // Interpolate.
        let usage_begin = history.usageSums.last ?? 0
        let usage_delta = usage - usage_begin
        let day_delta = Int64(day - history.usageSums.count)
        for i in 1...day_delta {
            history.usageSums.append(usage_begin + usage_delta * i / day_delta)
        }

        self.history = history
        log.debug("\(self): History interpolated.")
    }

    public fileprivate(set) var history: History? {
        get {
            return Account.history(of: identifier)
        }
        set {
            Defaults[.accountHistory(of: identifier)] = newValue?.vars
            Defaults.synchronize()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountHistoryUpdated, object: self,
                                                userInfo: ["account": self, "history": newValue as Any])
            }
            log.debug("\(self): History changed to \(newValue?.description ?? "nil").")
        }
    }

    public fileprivate(set) var loginAttemptAt: Date? {
        get {
            return Defaults[.accountLoginAttemptAt(of: identifier)]
        }
        set {
            Defaults[.accountLoginAttemptAt(of: identifier)] = newValue
            Defaults.synchronize()
        }
    }

    public var shouldAutoLogin: Bool {
        if let loginAttemptAt = loginAttemptAt {
            return -loginAttemptAt.timeIntervalSinceNow > Account.autoLoginInterval
        } else {
            return true
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

    public func canManage(_ network: NEHotspotNetwork) -> Bool {
        return configuration.canManage(network)
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
            case .offline: self.status = Status(type: .offline)
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

    public func login(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
                      requestBinder: RequestBinder? = nil) -> Promise<Void> {
        loginAttemptAt = Date()

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
        .done(on: queue) { status in
            guard case .online = status.type else {
                log.warning("\(self): Login action finished successfully, but status check failed.")
                throw CampNetError.networkError
            }

            Defaults[.accountLastLoginErrorNotification(of: self.identifier)] = nil
            Defaults.synchronize()
            log.info("\(self): Logged in.")
        }
        .recover(on: queue) { error in
            log.warning("\(self): Failed to login: \(error)")

            if !isSubaction {
                self.handle(error: error, name: .accountLoginError)
            }
            throw error
        }
    }

    public func status(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
                       requestBinder: RequestBinder? = nil) -> Promise<Status> {

        return firstly { () -> Promise<[String: Any]> in
            guard let action = self.configuration.actions[.status] else {
                log.error("\(self): No status action.")
                throw CampNetError.invalidConfiguration
            }
            log.debug("\(self): Updating status.")

            return action.commit(username: self.username, password: self.password, on: queue, requestBinder: requestBinder)
        }
        .map(on: queue) { vars -> Status in
            guard let status = Status(vars: vars) else {
                log.error("\(self): No status in vars (\(vars.keys)).")
                throw CampNetError.invalidConfiguration
            }
            self.status = status
            log.info("\(self): Status updated.")
            return status
        }
        .recover(on: queue) { error -> Promise<Status> in
            if let error = error as? CampNetError, case .offcampus = error {
                let status = Status(type: .offcampus)
                self.status = status
                log.info("\(self): Status updated.")
                return .value(status)
            }

            log.warning("\(self): Failed to update status: \(error)")

            if !isSubaction {
                self.handle(error: error, name: .accountStatusError)
            }
            throw error
        }
    }

    public func profile(isSubaction: Bool = false, autoLogout: Bool = true,
                        on queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
                        requestBinder: RequestBinder? = nil) -> Promise<Profile> {

        return firstly { () -> Promise<[String: Any]> in
            guard let action = configuration.actions[.profile] else {
                log.error("\(self): No profile action.")
                throw CampNetError.invalidConfiguration
            }
            log.debug("\(self): Updating profile.")

            return action.commit(username: username, password: password, on: queue, requestBinder: requestBinder)
        }
        .map(on: queue) { vars -> Profile in
            guard let profile = Profile(vars: vars) else {
                log.error("\(self): No profile in vars (\(vars.keys)).")
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
        .recover(on: queue) { error -> Promise<Profile> in
            log.warning("\(self): Failed to update profile: \(error)")

            if !isSubaction {
                self.handle(error: error, name: .accountProfileError)
            }
            throw error
        }
    }

    public func login(ip: String, isSubaction: Bool = false,
                      on queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
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
        .done(on: queue) { profile in
            // Check sessions if possible.
            if let sessions = profile.sessions {
                guard sessions.map({ $0.ip }).contains(ip) else {
                    log.warning("\(self): Login IP action finished successfully, but profile check failed.")
                    throw CampNetError.networkError
                }
            }

            // Trigger a status check if the IP belongs to this device.
            if WiFi.ip == ip {
                _ = self.status(isSubaction: true, on: queue, requestBinder: requestBinder)
            }

            log.info("\(self): \(ip) logged in.")
        }
        .recover(on: queue) { error in
            log.warning("\(self): Failed to login \(ip): \(error)")

            if !isSubaction {
                self.handle(error: error, name: .accountLoginIpError, extraInfo: ["ip": ip])
            }
            throw error
        }
    }

    public func logoutSession(session: Session, isSubaction: Bool = false,
                              on queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
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
        .map(on: queue) { profile -> Void in
            // Check sessions if possible.
            if let sessions = profile.sessions {
                guard !sessions.map({ $0.ip }).contains(session.ip) else {
                    log.warning("\(self): Logout session action finished successfully, but profile check failed.")
                    throw CampNetError.networkError
                }
            }

            // Trigger a status check if the IP belongs to this device.
            if WiFi.ip == session.ip {
                _ = self.status(isSubaction: true, on: queue, requestBinder: requestBinder)
            }

            log.info("\(self): \(session) logged out.")
        }
        .recover(on: queue) { error in
            log.warning("\(self): Failed to logout \(session): \(error)")

            if !isSubaction {
                self.handle(error: error, name: .accountLogoutSessionError, extraInfo: ["session": session])
            }
            throw error
        }
    }

    public func history(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
                        requestBinder: RequestBinder? = nil) -> Promise<History> {

        return firstly { () -> Promise<[String: Any]> in
            guard let action = configuration.actions[.history] else {
                log.error("\(self): No history action.")
                throw CampNetError.invalidConfiguration
            }
            log.debug("\(self): Updating history.")

            let today = Date()
            return action.commit(username: username, password: password,
                                 extraVars: ["year": Calendar.current.component(.year, from: today),
                                             "month": Calendar.current.component(.month, from: today),
                                             "day": Calendar.current.component(.day, from: today)],
                                 on: queue, requestBinder: requestBinder)
        }
        .map(on: queue) { vars -> History in
            guard let history = History(vars: vars) else {
                log.error("\(self): No history in vars (\(vars.keys)).")
                throw CampNetError.invalidConfiguration
            }
            self.history = history
            log.debug("\(self): History updated.")
            return history
        }
        .recover(on: queue) { error -> Promise<History> in
            log.warning("\(self): Failed to update history: \(error).")

            if !isSubaction {
                self.handle(error: error, name: .accountHistoryError)
            }
            throw error
        }
    }

    public func logout(isSubaction: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
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
        .done(on: queue) { status in
            guard case .offline = status.type else {
                log.warning("\(self): Logout action finished successfully, but status check failed.")
                throw CampNetError.networkError
            }

            log.info("\(self): Logged out.")
        }
        .recover(on: queue) { error in
            log.warning("\(self): Failed to logout: \(error).")

            if !isSubaction {
                self.handle(error: error, name: .accountLogoutError)
            }
            throw error
        }
    }

    public func update(skipStatus: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
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

    public func updateIfNeeded(skipStatus: Bool = false, on queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
                               requestBinder: RequestBinder? = nil) -> Promise<Void> {
        return shouldAutoUpdate ? update(skipStatus: skipStatus, on: queue, requestBinder: requestBinder)
                                : Promise()
    }

    private func updatePastIps(sessions: [Session], autoLogout: Bool, on queue: DispatchQueue,
                                   requestBinder: RequestBinder?) {
        let ips = sessions.map { $0.ip }
        let currentIp = WiFi.ip

        var ipsToLogout = pastIps.filter { ips.contains($0) && $0 != currentIp }

        if configuration.actions[.logoutSession] != nil, Defaults[.autoLogoutExpiredSessions], autoLogout {
            var promise = Promise<Void>()
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
