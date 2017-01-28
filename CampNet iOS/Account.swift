//
//  Account.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/29.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import KeychainAccess

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
    var placeholders: [String: String] {
        return [
            "username": username,
            "password": password,
            "password.md5": password.md5
        ]
    }
    var description: String { return "Account(\(identifier))" }
    
    init?(configurationIdentifier: String, username: String) {
        self.configurationIdentifier = configurationIdentifier
        guard let configuration = Configuration(identifier: self.configurationIdentifier) else {
            return nil
        }
        self.configuration = configuration
        self.username = username
    }
    
    func login(requestBinder: ((NSMutableURLRequest) -> Void)? = nil, session: URLSession, completionHandler: @escaping (NetworkAction.Result) -> Void) {
        print("Login for \(self).")
        configuration.loginAction.commit(placeholders: placeholders, requestBinder: requestBinder, session: session, completionHandler: completionHandler)
    }
    
    func status(requestBinder: ((NSMutableURLRequest) -> Void)? = nil, session: URLSession, completionHandler: @escaping (NetworkAction.Result) -> Void) {
        print("Check status for \(self).")
        configuration.statusAction.commit(placeholders: placeholders, requestBinder: requestBinder, session: session, completionHandler: completionHandler)
    }
    
    func logout(requestBinder: ((NSMutableURLRequest) -> Void)? = nil, session: URLSession, completionHandler: @escaping (NetworkAction.Result) -> Void) {
        print("Logout for \(self).")
        configuration.logoutAction.commit(placeholders: placeholders, requestBinder: requestBinder, session: session, completionHandler: completionHandler)
    }
}
