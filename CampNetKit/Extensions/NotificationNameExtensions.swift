//
//  NotificationNameExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/13.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

extension Notification.Name {
    public static let accountAdded = Notification.Name("accountAdded")
    public static let accountRemoved = Notification.Name("accountRemoved")
    public static let mainAccountChanged = Notification.Name("mainAccountChanged")
}
