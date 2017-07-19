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
    public static let mainAccount = DefaultsKey<String?>("mainAccount")
    public static let accounts = DefaultsKey<[String]>("accounts")
    
    // Account related.
    public static func accountUnauthorized(of id: String) -> DefaultsKey<Bool> { return DefaultsKey<Bool>("\(id).accountUnauthorized") }
    public static func accountStatus(of id: String) -> DefaultsKey<[String: Any]?> { return DefaultsKey<[String: Any]?>("\(id).accountStatus") }
    public static func accountProfile(of id: String) -> DefaultsKey<[String: Any]?> { return DefaultsKey<[String: Any]?>("\(id).accountProfile") }
    public static func accountHistory(of id: String) -> DefaultsKey<[String: Any]?> { return DefaultsKey<[String: Any]?>("\(id).accountHistory") }
}
