//
//  AccountManager.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/13.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

class AccountManager {
    
    static let shared = AccountManager()
    
    fileprivate let accountsQueue = DispatchQueue(label: "\(Configuration.bundleIdentifier).accountsQueue", qos: .userInitiated, attributes: .concurrent)
    
    fileprivate var mainAccount: Account? = nil {
        willSet {
            Defaults[.mainAccount] = newValue?.identifier
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
        var loadedIdentifiers: [String] = []
        let mainAccountIdentifier = Defaults[.mainAccount]
        
        for accountIdentifier in Defaults[.accounts] {
            let (configurationIdentifier, username) = splitAccountIdentifier(accountIdentifier)
            
            guard let account = addAccount(configurationIdentifier: configurationIdentifier, username: username) else {
                print("Failed to load account \(accountIdentifier) from UserDefault.")
                continue
            }
            
            loadedIdentifiers.append(account.identifier)
            if account.identifier == mainAccountIdentifier {
                mainAccount = account
            }
            print("Account \(accountIdentifier) loaded.")
        }
        
        // Remove invalid defaults.
        Defaults[.accounts] = loadedIdentifiers
        Defaults[.mainAccount] = mainAccount?.identifier
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
            
            var mainChanged = false
            if self.mainAccount == nil {
                self.mainAccount = account
                mainChanged = true
            }
            
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
                }
                
                if account == self.mainAccount {
                    self.mainAccount = self.firstAccount
                    mainChanged = true
                }
            }
            
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
            
            // Post notification
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .mainAccountChanged, object: self, userInfo: ["fromAccount": oldMain as Any, "toAccount": account])
            }
        }
    }
}
