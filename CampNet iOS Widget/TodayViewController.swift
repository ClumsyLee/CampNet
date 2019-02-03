//
//  TodayViewController.swift
//  CampNet iOS Widget
//
//  Created by Thomas Lee on 2017/8/27.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import UIKit
import NotificationCenter

import Charts
import CampNetKit

class TodayViewController: UIViewController, NCWidgetProviding {

    @IBOutlet var chart: UsageChartView!

    @IBOutlet var username: UILabel!
    @IBOutlet var usage: UILabel!
    @IBOutlet var balance: UILabel!

    @IBOutlet var gb: UILabel!
    @IBOutlet var rmb: UILabel!

    var identifier: String?
    var profile: Profile?
    var history: History?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.

        preferredContentSize.height = 150

        chart.usageSumDataset.lineWidth = 3
        chart.usageSumDataset.fillColor = #colorLiteral(red: 0.1921568627, green: 0.7333333333, blue: 0.9803921569, alpha: 1)
        chart.usageSumDataset.setColor(#colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1))

        chart.usageSumEndDataset.circleRadius = 6.0
        chart.usageSumEndDataset.setCircleColor(.white)
        chart.usageSumEndDataset.circleHoleRadius = 5.0
        chart.usageSumEndDataset.circleHoleColor = #colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1)

        chart.minOffset = 8
        chart.backgroundColor = .clear
        chart.heightRatio = 1.02

        chart.xAxis.drawLabelsEnabled = false
        chart.leftAxis.setLabelCount(4, force: false)
        chart.freeLimitLine.drawLabelEnabled = false
        chart.maxLimitLine.drawLabelEnabled = false

        if #available(iOS 10.0, *) {
            chart.xAxis.axisLineColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
            chart.leftAxis.labelTextColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
            chart.leftAxis.gridColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)

            username.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
            usage.textColor = .darkText
            gb.textColor = .darkText
            rmb.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
            balance.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        } else {
            chart.xAxis.axisLineColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
            chart.leftAxis.labelTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
            chart.leftAxis.gridColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.1)

            username.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
            usage.textColor = .white
            gb.textColor = .white
            rmb.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
            balance.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func reload() {
        var decimalUnits = false
        if let identifier = identifier {
            decimalUnits = Account.decimalUnits(of: identifier)
        }

        username.text = profile?.name ?? identifier?.components(separatedBy: ".").last ?? "-"
        usage.text = profile?.usage?.usageStringInGb(decimalUnits: decimalUnits) ?? "-"
        balance.text = profile?.balance?.moneyString ?? "-"

        chart.reloadProfile(profile: profile, decimalUnits: decimalUnits)
        chart.reloadHistory(history: history, decimalUnits: decimalUnits)
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        guard let identifier = Account.identifier else {
            if self.identifier == nil {
                completionHandler(.noData)
            } else {
                self.identifier = nil
                self.profile = nil
                self.history = nil
                reload()
                completionHandler(.newData)
            }
            return
        }

        self.identifier = identifier
        self.profile = Account.profile(of: identifier)
        self.history = Account.history(of: identifier)
        reload()
        completionHandler(NCUpdateResult.newData)
    }

    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 8, left: 16, bottom: 8, right: 16)
    }
}
