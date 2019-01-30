//
//  UserDefaultsExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/8/13.
//  Copyright © 2019年 Sihan Li. All rights reserved.
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
    public static let donated = DefaultsKey<Bool>("donated")
    public static let donationRequestDate = DefaultsKey<Date?>("donationRequestDate")
    public static let customConfiguration = DefaultsKey<String>("customConfiguration")
    public static let customConfigurationUrl = DefaultsKey<String>("customConfigurationUrl")

    // One-time flags.
    public static let tsinghuaAuth4Migrated = DefaultsKey<Bool>("tsinghuaAuth4Migrated")

    // Statistics.
    public static let loginCount = DefaultsKey<Int>("loginCount")
    public static let loginCountStartDate = DefaultsKey<Date?>("loginCountStartDate")

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
}

extension UserDefaults {

    public var potentialDonator: Bool {
        if Defaults[.donated] {
            return false
        }

        // Prompt once we know that we are working.
        return Defaults[.loginCount] >= 1
    }

    private static let basicProfile = Profile(
        name: "呵呵姐",
        balance: 14.98,
        usage: 18_300_000_000)

    private static let mainStatus = Status(type: .online(onlineUsername: "lisihan13"))
    private static let mainProfile = Profile(
        name: "李思涵",
        balance: 1.68,
        usage: 52_800_000_000,
        freeUsage: 20_000_000_000,
        maxUsage: 53_640_000_000,
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
        ])
    private static let mainHistory = History(year: 2017, month: 8,usageSums: [
        100_000_000, 1_000_000_000, 9_000_000_000, 11_000_000_000, 15_000_000_000,
        17_000_000_000, 18_000_000_000, 20_000_000_000, 26_000_000_000, 27_000_000_000,
        27_400_000_000, 28_000_000_000, 38_000_000_000, 40_000_000_000, 40_000_000_000,
        42_000_000_000, 43_000_000_000, 46_000_000_000, 48_000_000_000, 49_000_000_000,
        51_000_000_000, 51_000_000_000, 52_000_000_000, 52_000_000_000, 52_800_000_000])

    private static let altStatus = Status(type: .offcampus)
    private static let altProfile = Profile(
        name: "硕霸",
        balance: 6.19,
        dataBalance: 732_200_000,
        usage: 36_900_000_000,
        freeUsage: 37_632_200_000,
        maxUsage: 40_000_000_000,
        sessions: [])
    private static let altHistory = History(year: 2017, month: 8, usageSums: [
        10_080_600_000, 10_146_130_000, 10_146_130_000, 10_146_130_000, 10_146_130_000,
        10_146_130_000, 10_146_130_000, 10_146_130_000, 10_146_130_000, 10_146_130_000,
        10_758_510_000, 13_088_940_000, 14_944_190_000, 15_477_650_000, 15_650_410_000,
        15_765_220_000, 18_011_360_000, 18_387_850_000, 18_934_760_000, 19_759_700_000,
        20_000_360_000, 20_463_330_000, 21_025_160_000, 35_291_340_000, 35_888_400_000,
        35_902_350_000, 36_699_970_000, 37_160_280_000])

    public func useFakeAccounts() {
        Defaults[.accounts] = []
        addBasicAccount()
        addMainAccount()
        addAltAccount()
    }

    private func addBasicAccount() {
        let accountId = "cn.edu.tsinghua.chenxinyao13"

        Defaults[.accountProfile(of: accountId)] = UserDefaults.basicProfile.vars

        Defaults[.accounts].append(accountId)
    }

    private func addMainAccount() {
        let accountId = "cn.edu.tsinghua.lisihan13"

        Defaults[.accountStatus(of: accountId)] = UserDefaults.mainStatus.vars
        Defaults[.accountProfile(of: accountId)] = UserDefaults.mainProfile.vars
        Defaults[.accountHistory(of: accountId)] = UserDefaults.mainHistory.vars

        Defaults[.accounts].append(accountId)
    }

    private func addAltAccount() {
        let accountId =  "cn.edu.tsinghua.liws13"

        Defaults[.accountStatus(of: accountId)] = UserDefaults.altStatus.vars
        Defaults[.accountProfile(of: accountId)] = UserDefaults.altProfile.vars
        Defaults[.accountHistory(of: accountId)] = UserDefaults.altHistory.vars

        Defaults[.accounts].append(accountId)
    }
}

extension Account {
    public func removeDefaults() {
        Defaults.remove(.accountLastLoginErrorNotification(of: identifier))
        Defaults.remove(.accountPastIps(of: identifier))

        Defaults.remove(.accountDecimalUnits(of: identifier))
        Defaults.remove(.accountStatus(of: identifier))
        Defaults.remove(.accountProfile(of: identifier))
        Defaults.remove(.accountHistory(of: identifier))

        Defaults.synchronize()
    }
}
