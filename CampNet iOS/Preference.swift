//
//  Configuration.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/18.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import KeychainAccess

class Preference {
    static let configIdentifierUserDefaultsKey = "configIdentifier"
    static let usernameUserDefaultsKey = "username"
    static let keychain = Keychain(service: Bundle.main.bundleIdentifier!)

    static var configIdentifier: String? {
        get {
            return UserDefaults.standard.string(forKey: configIdentifierUserDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: configIdentifierUserDefaultsKey)
        }
    }
    
    static var username: String? {
        get {
            return UserDefaults.standard.string(forKey: usernameUserDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: usernameUserDefaultsKey)
        }
    }
    
    static var password: String? {
        get {
            if let configIdentifier = configIdentifier, let username = username {
                return keychain["\(configIdentifier).\(username)"]
            } else {
                return nil
            }
        }
        set {
            if let configIdentifier = configIdentifier, let username = username {
                keychain["\(configIdentifier).\(username)"] = newValue
            }
        }
    }
}
