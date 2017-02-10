//
//  Configuration.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/18.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

import KeychainAccess
import SwiftyUserDefaults

class SecureDefaultsKeys {
    static let keychain = Keychain(service: Bundle.main.bundleIdentifier!)
    init() {}
}

class SecureDefaultsKey<T>: SecureDefaultsKeys {
    public let key: String
    
    public init(_ key: String) {
        self.key = key
        super.init()
    }
}

extension UserDefaults {
    subscript(key: SecureDefaultsKey<String>) -> String {
        get { return SecureDefaultsKeys.keychain[key.key] ?? "" }
        set { SecureDefaultsKeys.keychain[key.key] = newValue }
    }
}

extension DefaultsKeys {
    static let configurationIdentifier = DefaultsKey<String>("configurationIdentifier")
    static let username = DefaultsKey<String>("username")
}

extension SecureDefaultsKeys {
    static let password = SecureDefaultsKey<String>("password")
}
