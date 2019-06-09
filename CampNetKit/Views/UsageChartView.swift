//
//  UsageChartView.swift
//  CampNetKit
//
//  Created by Thomas Lee on 2/3/19.
//  Copyright © 2019 Sihan Li. All rights reserved.
//

import UIKit
import Charts

public class UsageChartView: LineChartView {

    public var heightRatio = 1.1

    public var usageSumDataset = LineChartDataSet(entries: [], label: nil)
    public var usageSumEndDataset = LineChartDataSet(entries: [], label: nil)
    public var freeLimitLine = ChartLimitLine(limit: 0.0, label: L10n.Chart.LimitLines.free)
    public var maxLimitLine = ChartLimitLine(limit: 0.0, label: L10n.Chart.LimitLines.max)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    fileprivate func initialize() {
        usageSumDataset.drawCirclesEnabled = false
        usageSumDataset.lineWidth = 4
        usageSumDataset.drawFilledEnabled = true
        usageSumDataset.drawValuesEnabled = false

        usageSumEndDataset.drawValuesEnabled = false

        data = LineChartData(dataSets: [usageSumDataset, usageSumEndDataset])

        isUserInteractionEnabled = false
        legend.enabled = false
        chartDescription?.enabled = false

        xAxis.labelTextColor = .lightGray
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.axisMinimum = 1.0
        xAxis.axisMaximum = 31.0

        leftAxis.labelTextColor = .lightGray
        leftAxis.gridColor = #colorLiteral(red: 0.9372541904, green: 0.9372367859, blue: 0.9563211799, alpha: 1)
        leftAxis.drawAxisLineEnabled = false
        leftAxis.axisMinimum = 0
        leftAxis.drawLimitLinesBehindDataEnabled = true
        rightAxis.enabled = false

        freeLimitLine.lineWidth = 1
        freeLimitLine.xOffset = 1
        freeLimitLine.yOffset = 1
        freeLimitLine.lineColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
        freeLimitLine.valueTextColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
        freeLimitLine.labelPosition = .topLeft

        maxLimitLine.lineWidth = 1
        maxLimitLine.xOffset = 1
        maxLimitLine.yOffset = 1
        maxLimitLine.lineColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        maxLimitLine.valueTextColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        maxLimitLine.labelPosition = .topRight
    }

    public func reloadProfile(profile: Profile?, decimalUnits: Bool) {
        var usageY: Double? = nil

        var entries: [ChartDataEntry] = []
        if let profile = profile, let usage = profile.usage {
            let day = Device.inUITest ? 25 : Calendar.current.component(.day, from: profile.updatedAt)
            let entry = ChartDataEntry(x: Double(day), y: usage.usageInGb(decimalUnits: decimalUnits))
            entries.append(entry)

            usageY = entry.y
        }
        usageSumEndDataset.replaceEntries(entries)

        // Limit lines.
        leftAxis.removeAllLimitLines()

        var freeY: Double? = nil
        var maxY: Double? = nil

        if let freeUsage = profile?.freeUsage {
            freeLimitLine.limit = freeUsage.usageInGb(decimalUnits: decimalUnits)
            leftAxis.addLimitLine(freeLimitLine)

            freeY = freeLimitLine.limit
        }
        if let maxUsage = profile?.maxUsage {
            maxLimitLine.limit = maxUsage.usageInGb(decimalUnits: decimalUnits)
            leftAxis.addLimitLine(maxLimitLine)

            maxY = maxLimitLine.limit
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
        leftAxis.axisMaximum = y * heightRatio

        data?.notifyDataChanged()
        notifyDataSetChanged()
    }

    public func reloadHistory(history: History?, decimalUnits: Bool) {
        var entries: [ChartDataEntry] = []
        if let history = history {
            for (index, usageSum) in history.usageSums.enumerated() {
                let entry = ChartDataEntry(x: Double(index + 1), y: usageSum.usageInGb(decimalUnits: decimalUnits))
                entries.append(entry)
            }
        }
        usageSumDataset.replaceEntries(entries)

        data?.notifyDataChanged()
        notifyDataSetChanged()
    }

}
