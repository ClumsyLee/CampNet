//
//  Manager.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/29.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import NetworkExtension

extension Configuration: Hashable, Comparable {
    var hashValue: Int { return identifier.hashValue }

    static func ==(lhs: Configuration, rhs: Configuration) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    static func <(lhs: Configuration, rhs: Configuration) -> Bool {
        return lhs.identifier < rhs.identifier
    }
}

extension Account: Hashable, Comparable {
    var hashValue: Int { return identifier.hashValue }

    static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    static func <(lhs: Account, rhs: Account) -> Bool {
        return lhs.identifier < rhs.identifier
    }
}

class Manager {
    enum Status {
        case online(Account)
        case squatting(Account)
        case offline
    }
    
    static let shared = Manager()
    
    var session: URLSession
    var timeoutIntervalForRequest = 30.0
    var accounts: [Configuration: [Account]] = [:]
    var userDefaultKeyAccounts = "accounts"
    
    func selectedAccount(ssid: String) -> Account? {
        for (configuration, accounts) in self.accounts {
            if configuration.ssids.contains(ssid) && !accounts.isEmpty {
                return accounts.first
            }
        }
        return nil
    }
    
    func register() -> Bool {
        print("Registering manager.")

        let options = [kNEHotspotHelperOptionDisplayName: "Campus network handled by CampNet" as NSObject]
        let queue = DispatchQueue(label: Bundle.main.bundleIdentifier!, attributes: .concurrent)

        let result = NEHotspotHelper.register(options: options, queue: queue) { (command) in
            let requestBinder = { (request: NSMutableURLRequest) -> Void in request.bind(to: command) }

            switch command.commandType {
            case .filterScanList:
                guard let networkList = command.networkList else {
                    return
                }

                var knownList: [NEHotspotNetwork] = []
                for network in networkList {
                    if let _ = self.selectedAccount(ssid: network.ssid) {
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
                
                if let account = self.selectedAccount(ssid: network.ssid) {
                    account.status(requestBinder: requestBinder, session: self.session) { result in
                        switch result {
                        case .online, .offline:
                            network.setConfidence(.high)
                        default:
                            network.setConfidence(.low)
                        }

                        let response = command.createResponse(.success)
                        response.setNetwork(network)
                        response.deliver()
                    }
                } else {
                    network.setConfidence(.none)
                    let response = command.createResponse(.success)
                    response.setNetwork(network)
                    response.deliver()
                }
                
            case .authenticate:
                guard let network = command.network else {
                    return
                }
                
                if let account = self.selectedAccount(ssid: network.ssid) {
                    account.login(requestBinder: requestBinder, session: self.session) { result in
                        let response: NEHotspotHelperResponse
                        switch result {
                        case .online:
                            response = command.createResponse(.success)
                        case .unauthorized:
                            response = command.createResponse(.temporaryFailure)
                        case .arrears:
                            response = command.createResponse(.failure)
                        default:
                            response = command.createResponse(.temporaryFailure)
                        }
                        response.deliver()
                    }
                } else {
                    let response = command.createResponse(.unsupportedNetwork)
                    response.deliver()
                }
                
            case .maintain:
                guard let network = command.network else {
                    return
                }
                
                if let account = self.selectedAccount(ssid: network.ssid) {
                    account.status(requestBinder: requestBinder, session: self.session) { result in
                        let response: NEHotspotHelperResponse
                        switch result {
                        case .online:
                            response = command.createResponse(.success)
                        case .offline:
                            response = command.createResponse(.authenticationRequired)
                        default:
                            response = command.createResponse(.failure)
                        }
                        response.deliver()
                    }
                } else {
                    let response = command.createResponse(.failure)
                    response.deliver()
                }
                
            case .logoff:
                guard let network = command.network else {
                    return
                }
                
                if let account = self.selectedAccount(ssid: network.ssid) {
                    account.logout(requestBinder: requestBinder, session: self.session) { result in
                        let response: NEHotspotHelperResponse
                        switch result {
                        case .offline:
                            response = command.createResponse(.success)
                        default:
                            response = command.createResponse(.failure)
                        }
                        response.deliver()
                    }
                } else {
                    let response = command.createResponse(.failure)
                    response.deliver()
                }

            default:
                print("Command \(command.commandType) is unsupported.")
            }
        }
        
        print("Manager registration result: \(result)")
        return result
    }

    init() {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = false
        config.timeoutIntervalForRequest = timeoutIntervalForRequest
        session = URLSession(configuration: config)

        // Load accounts.
        let accountIds = UserDefaults.standard.stringArray(forKey: userDefaultKeyAccounts) ?? []
        for accountId in accountIds  {
            if let account = Account(identifier: accountId) {
                add(account: account)
            }
        }
        print("Accounts loaded:", accounts)
    }
    
    func save() {
        var idArray: [String] = []
        for (_, accounts) in self.accounts {
            for account in accounts {
                idArray.append(account.identifier)
            }
        }
        UserDefaults.standard.set(idArray, forKey: userDefaultKeyAccounts)
        print("Accounts saved:", accounts)
    }
    
    func add(account: Account) {
        print("Adding \(account).")

        if accounts[account.configuration] != nil {
            accounts[account.configuration]?.append(account)
            accounts[account.configuration]?.sort()
        } else {
            accounts[account.configuration] = [account]
        }
    }
    
    func remove(account: Account) {
        print("Removing \(account).")

        if let index = accounts[account.configuration]?.index(of: account) {
            accounts[account.configuration]?.remove(at: index)
            
            // Remove the configuration from accounts if needed.
            if let accounts = self.accounts[account.configuration], accounts.isEmpty {
                self.accounts[account.configuration] = nil
            }
        }
    }
}
