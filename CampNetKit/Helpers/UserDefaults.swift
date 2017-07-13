//
//  UserDefaults.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/11.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

public let Defaults = UserDefaults(suiteName: Configuration.appGroup)!

extension DefaultsKeys {
    static let configurationIdentifier = DefaultsKey<String>("configurationIdentifier")
    static func hehe(value: String) -> DefaultsKey<String> { return DefaultsKey<String>("aaa.\(value)") }
    static let username = DefaultsKey<String>("username")
    
    public static let accountIdentifiers = DefaultsKey<[String]>("accountIdentifiers")
    
    // Status.
    public static func accountStatus(of id: String) -> DefaultsKey<[String: Any]?> { return DefaultsKey<[String: Any]?>("\(id).accountStatus") }
    
    // Profile.
    public static func accountProfile(of id: String) -> DefaultsKey<[String: Any]?> { return DefaultsKey<[String: Any]?>("\(id).accountProfile") }
}
