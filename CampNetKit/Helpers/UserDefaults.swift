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
    public static let defaultsSet = DefaultsKey<Bool>("defaultsSet")
    
    public static let autoLogin = DefaultsKey<Bool>("autoLogin")
    public static let autoLogoutExpiredSessions = DefaultsKey<Bool>("autoLogoutExpiredSessions")
    public static let usageAlertRatio = DefaultsKey<Double?>("usageAlertRatio")
    
    static let mainAccount = DefaultsKey<String?>("mainAccount")
    static let accounts = DefaultsKey<[String]>("accounts")
    
    // Account related.
    static func accountUnauthorized(of id: String) -> DefaultsKey<Bool> { return DefaultsKey<Bool>("\(id).accountUnauthorized") }
    static func accountStatus(of id: String) -> DefaultsKey<[String: Any]?> { return DefaultsKey<[String: Any]?>("\(id).accountStatus") }
    static func accountProfile(of id: String) -> DefaultsKey<[String: Any]?> { return DefaultsKey<[String: Any]?>("\(id).accountProfile") }
    static func accountHistory(of id: String) -> DefaultsKey<[String: Any]?> { return DefaultsKey<[String: Any]?>("\(id).accountHistory") }
    static func accountEstimatedDailyUsage(of id: String) -> DefaultsKey<Int?> { return DefaultsKey<Int?>("\(id).accountEstimatedDailyUsage") }
}
