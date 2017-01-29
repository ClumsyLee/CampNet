//
//  Account.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/29.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import KeychainAccess
import NetworkExtension

extension String  {
    var md5: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        
        if let d = self.data(using: String.Encoding.utf8) {
            _ = d.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
                CC_MD5(body, CC_LONG(d.count), &digest)
            }
        }

        return (0..<length).reduce("") {
            $0 + String(format: "%02x", digest[$1])
        }
    }
}

class Account: CustomStringConvertible {
    static let keychain = Keychain(service: Bundle.main.bundleIdentifier!)

    let configurationIdentifier: String
    let configuration: Configuration
    let username: String
    var password: String {
        get { return Account.keychain[identifier] ?? "" }
        set { Account.keychain[identifier] = newValue }
    }
    var identifier: String { return "\(configurationIdentifier).\(username)" }
    var description: String { return "Account(\(identifier))" }

    init(configuration: Configuration, username: String) {
        self.configurationIdentifier = configuration.identifier
        self.configuration = configuration
        self.username = username
    }

    convenience init?(configurationIdentifier: String, username: String) {
        guard let configuration = Configuration(identifier: configurationIdentifier) else {
            return nil
        }
        self.init(configuration: configuration, username: username)
    }
    
    convenience init?(identifier: String) {
        guard let range = identifier.range(of: ".", options: .backwards) else {
            print("Invalid account identifier: ", identifier)
            return nil
        }

        let configId = identifier.substring(to: range.lowerBound)
        let username = identifier.substring(from: range.upperBound)
        self.init(configurationIdentifier: configId, username: username)
    }
    
    func canManage(ssid: String, isSecure: Bool) -> Bool {
        return configuration.ssids.contains(ssid) && !isSecure
    }
    
    func canManage(_ network: NEHotspotNetwork) -> Bool {
        return canManage(ssid: network.ssid, isSecure: network.isSecure)
    }
    
    func login(requestBinder: ((NSMutableURLRequest) -> Void)? = nil, session: URLSession, completionHandler: @escaping (NetworkAction.Result) -> Void) {
        print("Login for \(self).")
        let placeholders = [
            "username": username,
            "password": password,
            "password.md5": password.md5
        ]
        configuration.loginAction.commit(placeholders: placeholders, requestBinder: requestBinder, session: session, completionHandler: completionHandler)
    }
    
    func status(requestBinder: ((NSMutableURLRequest) -> Void)? = nil, session: URLSession, completionHandler: @escaping (NetworkAction.Result) -> Void) {
        print("Check status for \(self).")
        configuration.statusAction.commit(requestBinder: requestBinder, session: session, completionHandler: completionHandler)
    }
    
    func logout(requestBinder: ((NSMutableURLRequest) -> Void)? = nil, session: URLSession, completionHandler: @escaping (NetworkAction.Result) -> Void) {
        print("Logout for \(self).")
        configuration.logoutAction.commit(requestBinder: requestBinder, session: session, completionHandler: completionHandler)
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
