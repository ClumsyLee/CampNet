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
    
    fileprivate let accountsQueue = DispatchQueue(label: "\(Configuration.bundleIdentifier).accountsQueue", attributes: .concurrent)
    
    fileprivate var accounts: [Account] = {
        var array: [Account] = []
        for accountIdentifier in Defaults[.accountIdentifiers] {
            guard let account = Account(accountIdentifier) else {
                print("Failed to load account \(accountIdentifier) from UserDefault, continue anyway.")
                continue
            }
            array.append(account)
        }
        return array
    }()
    
    public var all: [Account] {
        var accountsCopy: [Account]!
        accountsQueue.sync {
            accountsCopy = accounts
        }
        return accountsCopy
    }
    
    public var main: Account? {
        var accountCopy: Account?
        accountsQueue.sync {
            accountCopy = accounts.first
        }
        return accountCopy
    }
    
    fileprivate init() {}
    
    public func add(_ account: Account) {
        accountsQueue.async(flags: .barrier) {
            guard !Defaults[.accountIdentifiers].contains(account.identifier) else {
                return
            }
            
            Defaults[.accountIdentifiers].append(account.identifier)
            self.accounts.append(account)
            
            // Post notification
            let mainChanged = self.accounts.count == 1
            
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
            guard let index = Defaults[.accountIdentifiers].index(of: account.identifier) else {
                return
            }
            
            Defaults[.accountIdentifiers].remove(at: index)
            self.accounts.remove(at: index)
            
            // Post notification
            let mainChanged = self.accounts.count == 0
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .accountRemoved, object: self, userInfo: ["account": account])
                if mainChanged {
                    NotificationCenter.default.post(name: .mainAccountChanged, object: self, userInfo: ["fromAccount": account])
                }
            }
        }
    }

    public func makeMain(_ account: Account) {
        accountsQueue.async(flags: .barrier) {
            guard let index = Defaults[.accountIdentifiers].index(of: account.identifier), index > 0 else {
                return
            }
            
            Defaults[.accountIdentifiers].pushToFirst(from: index)
            self.accounts.pushToFirst(from: index)
            
            // Post notification
            let oldMain = self.accounts[1]
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .mainAccountChanged, object: self, userInfo: ["fromAccount": oldMain, "toAccount": account])
            }
        }
    }
}
