//
//  AccountManager.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/13.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

public class AccountManager {

    public static var inUITest: Bool {
        #if DEBUG
            return ProcessInfo.processInfo.environment["UITest"] != nil
        #else
            return false
        #endif
    }

    static let shared = AccountManager()

    fileprivate let accountsQueue = DispatchQueue(label: "\(Configuration.bundleIdentifier).accountsQueue", qos: .userInitiated, attributes: .concurrent)

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
        #if DEBUG
            if AccountManager.inUITest {
                // Use fake data in UITests.
                let cxy = "cn.edu.tsinghua.chenxinyao13"
                let lsh = "cn.edu.tsinghua.lisihan13"
                let lws = "cn.edu.tsinghua.liws13"

                Defaults[.mainAccount] = lsh
                Defaults[.accounts] = [cxy, lsh, lws]

                Defaults[.accountProfile(of: cxy)] = Profile(
                    name: "呵呵姐",
                    balance: 14.98,
                    usage: 18_300_000_000).vars

                Defaults[.accountStatus(of: lsh)] = Status(type: .online(onlineUsername: "lisihan13", startTime: nil, usage: nil)).vars
                Defaults[.accountProfile(of: lsh)] = Profile(
                    name: "李思涵",
                    billingGroupName: "student",
                    balance: 16.86,
                    usage: 52_800_000_000,
                    sessions: [
                        Session(ip: "59.66.141.91",
                                startTime: Date(timeIntervalSinceNow: -70000),
                                usage: 548_000_000,
                                device: "iOS-Client"),
                        Session(ip: "59.66.141.92",
                                startTime: Date(timeIntervalSinceNow: -160000),
                                usage: 1_385_000_000,
                                device: "Mac OS"),
                        Session(ip: "59.66.141.93",
                                startTime: Date(timeIntervalSinceNow: -700),
                                usage: 26_000_000,
                                device: "Windows NT"),
                    ]).vars
                Defaults[.accountHistory(of: lsh)] = History(year: 2017, month: 8, usageSums: [100_000_000, 1_000_000_000, 9_000_000_000, 11_000_000_000, 15_000_000_000, 17_000_000_000, 18_000_000_000, 20_000_000_000, 26_000_000_000, 27_000_000_000, 27_400_000_000, 28_000_000_000, 38_000_000_000, 40_000_000_000, 40_000_000_000, 42_000_000_000, 43_000_000_000, 46_000_000_000, 48_000_000_000, 49_000_000_000, 51_000_000_000, 51_000_000_000, 52_000_000_000, 52_000_000_000, 52_800_000_000]).vars
                Defaults[.accountEstimatedDailyUsage(of: lsh)] = 0

                Defaults[.accountStatus(of: lws)] = Status(type: .offcampus).vars
                Defaults[.accountProfile(of: lws)] = Profile(
                    name: "硕霸",
                    billingGroupName: "student",
                    balance: 6.19,
                    usage: 36_900_000_000,
                    sessions: []).vars
                Defaults[.accountHistory(of: lws)] = History(year: 2017, month: 8, usageSums: [10_080_600_000, 10_146_130_000, 10_146_130_000, 10_146_130_000, 10_146_130_000, 10_146_130_000, 10_146_130_000, 10_146_130_000, 10_146_130_000, 10_146_130_000, 10_758_510_000, 13_088_940_000, 14_944_190_000, 15_477_650_000, 15_650_410_000, 15_765_220_000, 18_011_360_000, 18_387_850_000, 18_934_760_000, 19_759_700_000, 20_000_360_000, 20_463_330_000, 21_025_160_000, 35_291_340_000, 35_888_400_000, 35_902_350_000, 36_699_970_000, 37_160_280_000]).vars
                Defaults[.accountEstimatedDailyUsage(of: lws)] = 2_451_417_142
            }
        #endif

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
            guard let account = self.addAccount(configurationIdentifier: configurationIdentifier, username: username) else {
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
                    NotificationCenter.default.post(name: .mainAccountChanged, object: self, userInfo: ["toAccount": account])
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
                    NotificationCenter.default.post(name: .mainAccountChanged, object: self, userInfo: ["fromAccount": account, "toAccount": self.mainAccount as Any])
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
                NotificationCenter.default.post(name: .mainAccountChanged, object: self, userInfo: ["fromAccount": oldMain as Any, "toAccount": account])
            }
        }
    }
}
