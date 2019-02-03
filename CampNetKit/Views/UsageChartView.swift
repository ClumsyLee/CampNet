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

    var usageSumDataset = LineChartDataSet(values: [], label: nil)
    var usageSumEndDataset = LineChartDataSet(values: [], label: nil)
//    var freeLimitLine = ChartLimitLine(limit: 0.0, label: L10n.Overview.Chart.LimitLines.free)
//    var maxLimitLine = ChartLimitLine(limit: 0.0, label: L10n.Overview.Chart.LimitLines.max)

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
