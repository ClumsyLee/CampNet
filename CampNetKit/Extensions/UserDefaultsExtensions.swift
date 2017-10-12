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

    public static func onCampus(id: String, ssid: String) -> DefaultsKey<Bool> {
        return DefaultsKey<Bool>("\(id).\(ssid).onCampus")
    }

    // Sync with the widget.
    static let mainAccount = DefaultsKey<String?>("mainAccount")
    static let accounts = DefaultsKey<[String]>("accounts")

    // Account related.
    public static func accountLastLoginErrorNotification(of id: String) -> DefaultsKey<Date?> {
        return DefaultsKey<Date?>("\(id).accountLastLoginErrorNotification")
    }
    static func accountPastIps(of id: String) -> DefaultsKey<[String]> {
        return DefaultsKey<[String]>("\(id).accountPastIps")
    }
    // Sync with the widget.
    static func accountDecimalUnits(of id: String) -> DefaultsKey<Bool> {
        return DefaultsKey<Bool>("\(id).accountDecimalUnits")
    }
    static func accountStatus(of id: String) -> DefaultsKey<[String: Any]?> {
        return DefaultsKey<[String: Any]?>("\(id).accountStatus")
    }
    static func accountProfile(of id: String) -> DefaultsKey<[String: Any]?> {
        return DefaultsKey<[String: Any]?>("\(id).accountProfile")
    }
    static func accountHistory(of id: String) -> DefaultsKey<[String: Any]?> {
        return DefaultsKey<[String: Any]?>("\(id).accountHistory")
    }
    static func accountEstimatedDailyUsage(of id: String) -> DefaultsKey<Int64?> {
        return DefaultsKey<Int64?>("\(id).accountEstimatedDailyUsage")
    }
    static func accountFreeUsage(of id: String) -> DefaultsKey<Int64?> {
        return DefaultsKey<Int64?>("\(id).accountFreeUsage")
    }
    static func accountMaxUsage(of id: String) -> DefaultsKey<Int64?> {
        return DefaultsKey<Int64?>("\(id).accountMaxUsage")
    }
}

extension UserDefaults {
    public static func useFakeAccounts() {
        Defaults[.accounts] = []
        addBasicAccount()
        addMainAccount()
        addAltAccount()
    }

    private static func addBasicAccount() {
        let accountId = "cn.edu.tsinghua.chenxinyao13"

        Defaults[.accountProfile(of: accountId)] = Profile(
            name: "呵呵姐",
            balance: 14.98,
            usage: 18_300_000_000).vars

        Defaults[.accounts].append(accountId)
    }

    private static func addMainAccount() {
        let accountId = "cn.edu.tsinghua.lisihan13"

        Defaults[.accountStatus(of: accountId)] = Status(type: .online(onlineUsername: "lisihan13", startTime: nil,
                                                                 usage: nil)).vars
        Defaults[.accountProfile(of: accountId)] = Profile(
            name: "李思涵",
            billingGroupName: "student",
            balance: 1.68,
            usage: 52_800_000_000,
            sessions: [
                Session(ip: "59.66.141.91",
                        startTime: Date(timeIntervalSinceNow: -70000),
                        usage: 548_000_000,
                        device: "iPhone"),
                Session(ip: "59.66.141.92",
                        startTime: Date(timeIntervalSinceNow: -160000),
                        usage: 1_385_000_000,
                        device: "Mac OS"),
                Session(ip: "59.66.141.93",
                        startTime: Date(timeIntervalSinceNow: -700),
                        usage: 26_000_000,
                        device: "Windows NT"),
                ]).vars
        Defaults[.accountHistory(of: accountId)] = History(year: 2017, month: 8,usageSums: [
            100_000_000, 1_000_000_000, 9_000_000_000, 11_000_000_000, 15_000_000_000,
            17_000_000_000, 18_000_000_000, 20_000_000_000, 26_000_000_000, 27_000_000_000,
            27_400_000_000, 28_000_000_000, 38_000_000_000, 40_000_000_000, 40_000_000_000,
            42_000_000_000, 43_000_000_000, 46_000_000_000, 48_000_000_000, 49_000_000_000,
            51_000_000_000, 51_000_000_000, 52_000_000_000, 52_000_000_000, 52_800_000_000]).vars
        Defaults[.accountEstimatedDailyUsage(of: accountId)] = 1_000_000_000
        Defaults[.accountFreeUsage(of: accountId)] = 20_000_000_000
        Defaults[.accountMaxUsage(of: accountId)] = 53_640_000_000

        Defaults[.accounts].append(accountId)
    }

    private static func addAltAccount() {
        let accountId =  "cn.edu.tsinghua.liws13"

        Defaults[.accountStatus(of: accountId)] = Status(type: .offcampus).vars
        Defaults[.accountProfile(of: accountId)] = Profile(
            name: "硕霸",
            billingGroupName: "student",
            balance: 6.19,
            usage: 36_900_000_000,
            sessions: []).vars
        Defaults[.accountHistory(of: accountId)] = History(year: 2017, month: 8, usageSums: [
            10_080_600_000, 10_146_130_000, 10_146_130_000, 10_146_130_000, 10_146_130_000,
            10_146_130_000, 10_146_130_000, 10_146_130_000, 10_146_130_000, 10_146_130_000,
            10_758_510_000, 13_088_940_000, 14_944_190_000, 15_477_650_000, 15_650_410_000,
            15_765_220_000, 18_011_360_000, 18_387_850_000, 18_934_760_000, 19_759_700_000,
            20_000_360_000, 20_463_330_000, 21_025_160_000, 35_291_340_000, 35_888_400_000,
            35_902_350_000, 36_699_970_000, 37_160_280_000]).vars
        Defaults[.accountEstimatedDailyUsage(of: accountId)] = 2_451_417_142
        Defaults[.accountFreeUsage(of: accountId)] = 20_000_000_000
        Defaults[.accountMaxUsage(of: accountId)] = 40_000_000_000

        Defaults[.accounts].append(accountId)
    }
}

extension Account {
    public func removeDefaults() {
        Defaults.remove(.accountLastLoginErrorNotification(of: identifier))

        Defaults.remove(.accountStatus(of: identifier))
        Defaults.remove(.accountProfile(of: identifier))
        Defaults.remove(.accountHistory(of: identifier))
        Defaults.remove(.accountEstimatedDailyUsage(of: identifier))
        Defaults.remove(.accountPastIps(of: identifier))

        Defaults.synchronize()
    }
}
