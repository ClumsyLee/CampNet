//
//  AccountManager.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/13.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

public class AccountManager {

    static let shared = AccountManager()

    fileprivate let accountsQueue = DispatchQueue(label: "\(Configuration.bundleIdentifier).accountsQueue",
                                                  qos: .userInitiated, attributes: .concurrent)

    fileprivate var mainAccount: Account? = nil {
        willSet {
            Defaults[.mainAccount] = newValue?.identifier
            Defaults.synchronize()
        }
    }
    fileprivate var firstAccount: Account? {
        for accountArray in accounts.values {
            for account in accountArray {
                return account
            }
        }
        return nil
    }
    fileprivate var accounts: [Configuration: [Account]] = [:]

    public var all: [Configuration: [Account]] {
        var accountsCopy: [Configuration: [Account]]!
        accountsQueue.sync {
            accountsCopy = accounts
        }
        return accountsCopy
    }

    public var main: Account? {
        var accountCopy: Account?
        accountsQueue.sync {
            accountCopy = mainAccount
        }
        return accountCopy
    }

    fileprivate init() {
        if Device.inUITest {
            UserDefaults.useFakeAccounts()
        }

        var loadedIdentifiers: [String] = []
        let mainAccountIdentifier = Defaults[.mainAccount]

        for accountIdentifier in Defaults[.accounts] {
            let (configurationIdentifier, username) = splitAccountIdentifier(accountIdentifier)

            guard let account = addAccount(configurationIdentifier: configurationIdentifier, username: username) else {
                log.error("\(accountIdentifier): Failed to load.")
                continue
            }

            loadedIdentifiers.append(account.identifier)
            if account.identifier == mainAccountIdentifier {
                log.debug("\(accountIdentifier): Is main.")
                mainAccount = account
            }
            log.debug("\(accountIdentifier): Loaded.")
        }

        // Remove invalid defaults.
        Defaults[.accounts] = loadedIdentifiers
        Defaults[.mainAccount] = mainAccount?.identifier
        Defaults.synchronize()
    }

    fileprivate func splitAccountIdentifier(_ accountIdentifier: String) -> (String, String) {
        var parts = accountIdentifier.components(separatedBy: ".")
        let username = parts.removeLast()
        let configurationIdentifier = parts.joined(separator: ".")

        return (configurationIdentifier, username)
    }

    fileprivate func addAccount(configurationIdentifier: String, username: String) -> Account? {

        for (configuration, accountArray) in accounts {
            if configuration.identifier == configurationIdentifier {
                guard !accountArray.map({ $0.username }).contains(username) else {
                    return nil
                }

                let account = Account(configuration: configuration, username: username)
                accounts[configuration]!.append(account)
                return account
            }
        }

        guard let configuration = Configuration(configurationIdentifier) else {
            return nil
        }
        let account = Account(configuration: configuration, username: username)
        accounts[configuration] = [account]
        return account
    }

    fileprivate func removeAccount(_ account: Account) -> Bool {

        guard let accountArray = accounts[account.configuration],
              let index = accountArray.index(of: account) else {
            return false
        }

        account.removeDefaults()

        if accountArray.count == 1 {
            accounts[account.configuration] = nil
        } else {
            accounts[account.configuration]!.remove(at: index)
        }
        return true
    }

    fileprivate func containsAccount(_ account: Account) -> Bool {
        if let accountArray = accounts[account.configuration] {
            return accountArray.contains(account)
        } else {
            return false
        }
    }

    public func add(configurationIdentifier: String, username: String, password: String? = nil) {

        accountsQueue.async(flags: .barrier) {
            guard let account = self.addAccount(configurationIdentifier: configurationIdentifier,
                                                username: username) else {
                return
            }
            if let password = password {
                account.password = password
            }
            Defaults[.accounts].append(account.identifier)
            Defaults.synchronize()

            var mainChanged = false
            if self.mainAccount == nil {
                self.mainAccount = account
                mainChanged = true
            }

            log.debug("\(account): Added.")

            // Post notification
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountAdded, object: self, userInfo: ["account": account])
                if mainChanged {
                    NotificationCenter.default.post(name: .mainAccountChanged, object: self,
                                                    userInfo: ["toAccount": account])
                }
            }
        }
    }

    public func remove(_ account: Account) {

        accountsQueue.async(flags: .barrier) {
            var mainChanged = false
            if self.removeAccount(account) {
                if let index = Defaults[.accounts].index(of: account.identifier) {
                    Defaults[.accounts].remove(at: index)
                    Defaults.synchronize()
                }

                if account == self.mainAccount {
                    self.mainAccount = self.firstAccount
                    mainChanged = true
                }
            }

            log.debug("\(account): Removed.")

            // Post notification
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountRemoved, object: self, userInfo: ["account": account])
                if mainChanged {
                    NotificationCenter.default.post(name: .mainAccountChanged, object: self,
                                                    userInfo: ["fromAccount": account,
                                                               "toAccount": self.mainAccount as Any])
                }
            }
        }
    }

    public func makeMain(_ account: Account) {

        accountsQueue.async(flags: .barrier) {
            guard self.containsAccount(account) else {
                return
            }

            let oldMain = self.mainAccount
            self.mainAccount = account

            log.debug("\(account): Became main.")

            // Post notification
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .mainAccountChanged, object: self,
                                                userInfo: ["fromAccount": oldMain as Any, "toAccount": account])
            }
        }
    }
}


// Add support for HotspotHelper.
extension AccountManager {

    public func registerHotspotHelper(displayName: String) {
        let options = [kNEHotspotHelperOptionDisplayName: displayName as NSObject]
        let queue = DispatchQueue.global(qos: .utility)

        let result = NEHotspotHelper.register(options: options, queue: queue) { command in
            let queue = DispatchQueue.global(qos: .utility)
            let requestBinder: RequestBinder = { $0.bind(to: command) }

            switch command.commandType {
            case .filterScanList: filterScanList(command: command)
            case .evaluate: evaluate(command: command, on: queue, requestBinder: requestBinder)
            case .authenticate: authenticate(command: command, on: queue, requestBinder: requestBinder)
            case .maintain: maintain(command: command, on: queue, requestBinder: requestBinder)
            case .logoff: logoff(command: command, on: queue, requestBinder: requestBinder)
            default: break
            }
        }

        if result {
            log.info("HotspotHelper registered.")
        } else {
            log.error("Unable to register HotspotHelper.")
        }
    }

    private static func filterScanList(command: NEHotspotHelperCommand) {
        let main = self.main
        let accountId = main?.description ?? "nil"
        log.info("\(accountId): Received filterScanList command.")

        guard let networkList = command.networkList, let account = main else {
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
        log.info("\(accountId): Known networks: \(knownList).")

        let response = command.createResponse(.success)
        response.setNetworkList(knownList)
        response.deliver()
    }

    private static func evaluate(command: NEHotspotHelperCommand, on queue: DispatchQueue,
                                 requestBinder: @escaping RequestBinder) {
        let main = self.main
        let accountId = main?.description ?? "nil"
        guard let network = command.network else {
            return
        }
        log.info("\(accountId): Received evaluate command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            log.info("\(accountId): Cannot manage \(network).")

            network.setConfidence(.none)
            let response = command.createResponse(.success)
            response.setNetwork(network)
            response.deliver()
            return
        }

        account.status(on: queue, requestBinder: requestBinder).then(on: queue) { status -> Void in
            switch status.type {
            case .online, .offline:
                log.info("\(accountId): Can manage \(network).")
                network.setConfidence(.high)
            case .offcampus:
                log.info("\(accountId): Cannot manage \(network).")
                network.setConfidence(.none)
            }

            let response = command.createResponse(.success)
            response.setNetwork(network)
            response.deliver()
        }
        .catch(on: queue) { _ in
            log.info("\(accountId): Can possibly manage \(network).")
            network.setConfidence(.low)

            let response = command.createResponse(.success)
            response.setNetwork(network)
            response.deliver()
        }
    }

    private static func authenticate(command: NEHotspotHelperCommand, on queue: DispatchQueue,
                                     requestBinder: @escaping RequestBinder) {
        let main = self.main
        let accountId = main?.description ?? "nil"
        guard let network = command.network else {
            return
        }
        log.info("\(accountId): Received authenticate command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            log.warning("\(accountId): Cannot manage \(network).")
            command.createResponse(.unsupportedNetwork).deliver()
            return
        }

        account.login(on: queue, requestBinder: requestBinder).then(on: queue) { () -> Void in
            log.info("\(accountId): Logged in on \(network).")
            command.createResponse(.success).deliver()
        }
        .catch(on: queue) { error in
            log.warning("\(accountId): Failed to login on \(network): \(error)")
            command.createResponse(.temporaryFailure).deliver()
        }

    }

    private static func maintain(command: NEHotspotHelperCommand, on queue: DispatchQueue,
                                 requestBinder: @escaping RequestBinder) {
        let main = self.main
        let accountId = main?.description ?? "nil"
        guard let network = command.network else {
            return
        }
        log.info("\(accountId): Received maintain command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            log.warning("\(accountId): Cannot manage \(network).")
            command.createResponse(.failure).deliver()
            return
        }

        account.status(on: queue, requestBinder: requestBinder).then(on: queue) { status -> Void in
            let result: NEHotspotHelperResult

            switch status.type {
            case .online:
                log.info("\(accountId): Still online on \(network).")
                result = .success
            case .offline:
                log.info("\(accountId): Offline on \(network).")
                result = .authenticationRequired
            case .offcampus:
                log.warning("\(accountId): Cannot manage \(network).")
                result = .failure
            }

            if result == .success, account.shouldAutoUpdateProfile {
                account.update(skipStatus: true, on: queue, requestBinder: requestBinder).always(on: queue) {
                    command.createResponse(result).deliver()
                }
            } else {
                command.createResponse(result).deliver()
            }
        }
        .catch(on: queue) { error in
            log.warning("\(accountId): Failed to maintain on \(network): \(error)")
            command.createResponse(.failure).deliver()
        }
    }

    private static func logoff(command: NEHotspotHelperCommand, on queue: DispatchQueue,
                               requestBinder: @escaping RequestBinder) {
        let main = self.main
        let accountId = main?.description ?? "nil"
        guard let network = command.network else {
            return
        }
        log.info("\(accountId): Received logoff command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            log.warning("\(accountId): Cannot manage \(network).")
            command.createResponse(.failure).deliver()
            return
        }

        account.logout(on: queue, requestBinder: requestBinder).then(on: queue) { _ -> Void in
            log.info("\(accountId): Logged out on \(network).")
            command.createResponse(.success).deliver()
        }
        .catch(on: queue) { error in
            log.warning("\(accountId): Failed to logout on \(network): \(error)")
            command.createResponse(.failure).deliver()
        }
    }
}
