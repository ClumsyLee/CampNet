//
//  UserDefaultsExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/8/13.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

public let Defaults = UserDefaults(suiteName: Configuration.appGroup)!

extension UserDefaults {
    subscript(key: DefaultsKey<Int64?>) -> Int64? {
        get { return object(forKey: key._key) as? Int64 }
        set { set(key, newValue) }
    }
}

extension DefaultsKeys {
    public static let autoLogin = DefaultsKey<Bool>("autoLogin")
    public static let autoLogoutExpiredSessions = DefaultsKey<Bool>("autoLogoutExpiredSessions")
    public static let usageAlertRatio = DefaultsKey<Double?>("usageAlertRatio")
    public static let sendLogs = DefaultsKey<Bool>("sendLogs")
    
    public static func onCampus(id: String, ssid: String) -> DefaultsKey<Bool> { return DefaultsKey<Bool>("\(id).\(ssid).onCampus") }
    
    static let mainAccount = DefaultsKey<String?>("mainAccount")
    static let accounts = DefaultsKey<[String]>("accounts")
    
    // Account related.
    public static func accountLastLoginErrorNotification(of id: String) -> DefaultsKey<Date?> { return DefaultsKey<Date?>("\(id).accountLastLoginErrorNotification") }
    
    static func accountStatus(of id: String) -> DefaultsKey<[String: Any]?> { return DefaultsKey<[String: Any]?>("\(id).accountStatus") }
    static func accountProfile(of id: String) -> DefaultsKey<[String: Any]?> { return DefaultsKey<[String: Any]?>("\(id).accountProfile") }
    static func accountHistory(of id: String) -> DefaultsKey<[String: Any]?> { return DefaultsKey<[String: Any]?>("\(id).accountHistory") }
    static func accountEstimatedDailyUsage(of id: String) -> DefaultsKey<Int64?> { return DefaultsKey<Int64?>("\(id).accountEstimatedDailyUsage") }
    static func accountPastIps(of id: String) -> DefaultsKey<[String]> { return DefaultsKey<[String]>("\(id).accountPastIps") }
}

extension Account {
    public func removeDefaults() {
        Defaults.remove(.accountLastLoginErrorNotification(of: identifier))
        
        Defaults.remove(.accountStatus(of: identifier))
        Defaults.remove(.accountProfile(of: identifier))
        Defaults.remove(.accountHistory(of: identifier))
        Defaults.remove(.accountEstimatedDailyUsage(of: identifier))
        Defaults.remove(.accountPastIps(of: identifier))
    }
}
