//
//  NotificationViewController.swift
//  CampNet iOS Usage Alert Content Extension
//
//  Created by Thomas Lee on 2/4/19.
//  Copyright © 2019 Sihan Li. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import CampNetKit

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var chart: UsageChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        guard let identifier = notification.request.content.userInfo["account"] as? String else {
            return
        }

        let decimalUnits = Account.decimalUnits(of: identifier)
        chart.reloadProfile(profile: Account.profile(of: identifier), decimalUnits: decimalUnits)
        chart.reloadHistory(history: Account.history(of: identifier), decimalUnits: decimalUnits)
    }

}
