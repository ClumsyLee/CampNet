//
//  TodayViewController.swift
//  CampNet iOS Widget
//
//  Created by Thomas Lee on 2017/8/27.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import NotificationCenter

import Charts
import CampNetKit

class TodayViewController: UIViewController, NCWidgetProviding {

    @IBOutlet var chart: LineChartView!

    @IBOutlet var username: UILabel!
    @IBOutlet var usage: UILabel!
    @IBOutlet var balance: UILabel!

    @IBOutlet var gb: UILabel!
    @IBOutlet var rmb: UILabel!

    var usageSumDataset = LineChartDataSet(values: [], label: nil)
    var usageSumEndDataset = LineChartDataSet(values: [], label: nil)
    var freeLimitLine = ChartLimitLine(limit: 0.0)
    var maxLimitLine = ChartLimitLine(limit: 0.0)

    var identifier: String?
    var profile: Profile?
    var history: History?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.

        preferredContentSize.height = 150

        usageSumDataset.drawCirclesEnabled = false
        usageSumDataset.lineWidth = 3

        usageSumDataset.drawFilledEnabled = true
        usageSumDataset.fillColor = #colorLiteral(red: 0.1921568627, green: 0.7333333333, blue: 0.9803921569, alpha: 1)
        usageSumDataset.drawValuesEnabled = false
        usageSumDataset.setColor(#colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1))

        usageSumEndDataset.drawValuesEnabled = false
        usageSumEndDataset.circleRadius = 6.0
        usageSumEndDataset.setCircleColor(.white)
        usageSumEndDataset.circleHoleRadius = 5.0
        usageSumEndDataset.circleHoleColor = #colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1)

        chart.data = LineChartData(dataSets: [usageSumDataset, usageSumEndDataset])

        chart.isUserInteractionEnabled = false
        chart.legend.enabled = false
        chart.chartDescription?.enabled = false
        chart.minOffset = 8
        chart.backgroundColor = .clear

        chart.xAxis.drawLabelsEnabled = false
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.axisMinimum = 1.0
        chart.xAxis.axisMaximum = 31

        chart.leftAxis.drawAxisLineEnabled = false
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.drawLimitLinesBehindDataEnabled = true
        chart.leftAxis.setLabelCount(4, force: false)
        chart.rightAxis.enabled = false

        freeLimitLine.lineWidth = 1
        freeLimitLine.xOffset = 1
        freeLimitLine.yOffset = 1
        freeLimitLine.lineColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
        freeLimitLine.valueTextColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)

        maxLimitLine.lineWidth = 1
        maxLimitLine.xOffset = 1
        maxLimitLine.yOffset = 1
        maxLimitLine.lineColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        maxLimitLine.valueTextColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)

        if #available(iOS 10.0, *) {
            chart.xAxis.axisLineColor = .darkGray
            chart.leftAxis.labelTextColor = .darkGray
            chart.leftAxis.gridColor = .lightGray

            username.textColor = .darkGray
            usage.textColor = .darkText
            gb.textColor = .darkText
            rmb.textColor = .darkGray
            balance.textColor = .darkGray
        } else {
            chart.xAxis.axisLineColor = .lightGray
            chart.leftAxis.labelTextColor = .lightGray
            chart.leftAxis.gridColor = .darkGray

            username.textColor = .lightGray
            usage.textColor = .white
            gb.textColor = .white
            rmb.textColor = .lightGray
            balance.textColor = .lightGray
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

        username.text = identifier?.components(separatedBy: ".").last ?? "-"
        usage.text = profile?.usage?.usageStringInGb(decimalUnits: decimalUnits) ?? "-"
        balance.text = profile?.balance?.moneyString ?? "-"

        usageSumDataset.values = []
        if let history = history {
            for (index, usageSum) in history.usageSums.enumerated() {
                let entry = ChartDataEntry(x: Double(index + 1), y: usageSum.usageInGb(decimalUnits: decimalUnits))
                usageSumDataset.values.append(entry)
            }
        }

        // Chart end point.
        var usageY: Double? = nil

        usageSumEndDataset.values = []
        if let profile = profile, let usage = profile.usage {
            let day = Calendar.current.component(.day, from: profile.updatedAt)
            let entry = ChartDataEntry(x: Double(day), y: usage.usageInGb(decimalUnits: decimalUnits))
            usageSumEndDataset.values.append(entry)

            usageY = entry.y
        }

        // Limit lines.
        chart.leftAxis.removeAllLimitLines()

        var freeY: Double? = nil
        var maxY: Double? = nil

        if let identifier = identifier {
            if let freeUsage = Account.freeUsage(of: identifier) {
                freeLimitLine.limit = freeUsage.usageInGb(decimalUnits: decimalUnits)
                chart.leftAxis.addLimitLine(freeLimitLine)

                freeY = freeLimitLine.limit
            }
            if let maxUsage = Account.maxUsage(of: identifier) {
                maxLimitLine.limit = maxUsage.usageInGb(decimalUnits: decimalUnits)
                chart.leftAxis.addLimitLine(maxLimitLine)

                maxY = maxLimitLine.limit
            }
        }

        // Calculate chart.leftAxis.axisMaximum.
        let y: Double
        if let usageY = usageY {
            if let maxY = maxY {
                y = maxY
            } else if let freeY = freeY {
                y = max(usageY, freeY)
            } else {
                y = usageY
            }
        } else {
            y = maxY ?? freeY ?? 10.0
        }
        chart.leftAxis.axisMaximum = y * 1.02

        chart.data?.notifyDataChanged()
        chart.notifyDataSetChanged()
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
