//
//  NotificationNameExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/13.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import Foundation

extension Notification.Name {
    public static let accountAdded = Notification.Name("accountAdded")
    public static let accountRemoved = Notification.Name("accountRemoved")
    public static let mainAccountChanged = Notification.Name("mainAccountChanged")
    public static let delegateAccountChanged = Notification.Name("delegateAccountChanged")

    public static let accountAuthorizationChanged = Notification.Name("accountAuthorizationChanged")
    public static let accountStatusUpdated = Notification.Name("accountStatusUpdated")
    public static let accountProfileUpdated = Notification.Name("accountProfileUpdated")
    public static let accountHistoryUpdated = Notification.Name("accountHistoryUpdated")

    public static let accountLoginError = Notification.Name("accountLoginError")
    public static let accountLogoutError = Notification.Name("accountLogoutError")
    public static let accountStatusError = Notification.Name("accountStatusError")
    public static let accountProfileError = Notification.Name("accountProfileError")
    public static let accountLoginIpError = Notification.Name("accountLoginIpError")
    public static let accountLogoutSessionError = Notification.Name("accountLogoutSessionError")
    public static let accountHistoryError = Notification.Name("accountHistoryError")

    public static let accountUsageAlert = Notification.Name("accountUsageAlert")
}
