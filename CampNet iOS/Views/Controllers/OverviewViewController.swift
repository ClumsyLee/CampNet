//
//  OverviewViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/17.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import NetworkExtension

import Charts
import DynamicButton
import Instabug
import PromiseKit
import CampNetKit

class OverviewViewController: UITableViewController {
    static let autoUpdateTimeInterval: TimeInterval = 300
    @IBOutlet var upperView: UIView!

    @IBOutlet var usage: UILabel!
    @IBOutlet var balance: UILabel!
    @IBOutlet var estimatedFee: UILabel!
    @IBOutlet var network: UILabel!
    @IBOutlet var devices: UILabel!

    @IBOutlet var accountsButton: UIButton!
    @IBOutlet var networkButton: UIButton!
    @IBOutlet var devicesButton: UIButton!
    @IBOutlet var loginButton: DynamicButton!
    @IBOutlet var loginButtonCaption: UILabel!

    @IBOutlet var chart: LineChartView!
    
    var account: Account? = nil
    var status: Status? = nil
    var profile: Profile? = nil
    var history: History? = nil
    
    var usageSumDataset = LineChartDataSet(values: [], label: nil)
    var usageSumEndDataset = LineChartDataSet(values: [], label: nil)
    var freeLimitLine = ChartLimitLine(limit: 0.0, label: NSLocalizedString("Free", comment: "Limit line label in the history chart."))
    var maxLimitLine = ChartLimitLine(limit: 0.0, label: NSLocalizedString("Max", comment: "Limit line label in the history chart."))
    
    var refreshedAt: Date? = nil

    @IBAction func cancelSwitchingAccount(segue: UIStoryboardSegue) {}
    @IBAction func accountSwitched(segue: UIStoryboardSegue) {}
    
    @IBAction func feedbackPressed(_ sender: Any) {
        Instabug.invoke()
    }
    
    @IBAction func refreshTable(_ sender: Any) {
        guard let account = account else {
            return
        }
        print("Refreshing \(account.identifier) in overview.")
        refreshedAt = Date()
        
        account.update(on: DispatchQueue.global(qos: .userInitiated)).always {
            // Don't touch refreshControl if the account has been changed.
            if self.account == account {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let status = status else {
            return
        }
        
        switch status.type {
        case .online: logout()
        case .offline: login()
        default: return
        }
    }
    
    func login() {
        guard let account = account else {
            return
        }
        
        loginButton.isEnabled = false
        loginButton.setStyle(.horizontalMoreOptions, animated: true)
        
        loginButtonCaption.text = NSLocalizedString("Logging In…", comment: "Login button caption.")
        
        _ = account.login(on: DispatchQueue.global(qos: .userInitiated))
    }
    
    func logout() {
        guard let account = account else {
            return
        }
        
        loginButton.isEnabled = false
        loginButton.setStyle(.horizontalMoreOptions, animated: true)
        
        loginButtonCaption.text = NSLocalizedString("Logging Out…", comment: "Login button caption.")
        
        _ = account.logout(on: DispatchQueue.global(qos: .userInitiated))
    }
    
    func refreshIfNeeded() {
        if let refreshedAt = refreshedAt, -refreshedAt.timeIntervalSinceNow <= OverviewViewController.autoUpdateTimeInterval, account != nil {
            return // Infos still valid, do not refresh.
        }
        if account == nil || refreshControl!.isRefreshing {
            return
        }
        
        refreshControl!.beginRefreshing()
        
        let offset = CGPoint(x: 0, y: -tableView.contentInset.top)
        tableView.setContentOffset(offset, animated: true)
        
        refreshTable(self)
    }

    func reloadStatus() {
        status = account?.status

        if let type = status?.type {
            switch type {
            case let .online(onlineUsername: onlineUsername, _, _):
                if let username = account?.username, let onlineUsername = onlineUsername, username != onlineUsername {
                    loginButton.isEnabled = true
                    loginButton.backgroundColor = #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
                    loginButton.strokeColor = .white
                    loginButton.setStyle(.stop, animated: true)
                    
                    loginButtonCaption.text = String.localizedStringWithFormat(NSLocalizedString("Logout \"%@\"", comment: "Login button caption."), onlineUsername)
                } else {
                    loginButton.isEnabled = true
                    loginButton.backgroundColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
                    loginButton.strokeColor = .white
                    loginButton.setStyle(.stop, animated: true)
                    
                    loginButtonCaption.text = NSLocalizedString("Logout", comment: "Login button caption.")
                }
                
            case .offline:
                loginButton.isEnabled = true
                loginButton.backgroundColor = .white
                loginButton.strokeColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
                loginButton.setStyle(.play, animated: true)
                
                loginButtonCaption.text = NSLocalizedString("Login", comment: "Login button caption.")
                
                if Defaults[.autoLogin] {
                    login()
                }
                
            case .offcampus:
                loginButton.isEnabled = false
                loginButton.backgroundColor = #colorLiteral(red: 0.9372541904, green: 0.9372367859, blue: 0.9563211799, alpha: 1)
                loginButton.strokeColor = .lightGray
                loginButton.setStyle(.horizontalLine, animated: true)
                
                loginButtonCaption.text = NSLocalizedString("Offcampus", comment: "Login button caption.")
            }
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = #colorLiteral(red: 0.9372541904, green: 0.9372367859, blue: 0.9563211799, alpha: 1)
            loginButton.strokeColor = .lightGray
            loginButton.setStyle(.dot, animated: true)
            
            loginButtonCaption.text = NSLocalizedString("Unknown", comment: "Login button caption.")
        }

        let ssid = (NEHotspotHelper.supportedNetworkInterfaces().first as? NEHotspotNetwork)?.ssid ?? ""
        network.text = ssid.isEmpty ? "-": ssid
    }

    func reloadProfile() {
        profile = account?.profile
        let decimalUnits = account?.configuration.decimalUnits ?? false
        
        let title: String
        if let account = account {
            title = "\(account.username) ▾"
        } else {
            title = NSLocalizedString("No Accounts ▾", comment: "OverviewView title when no accounts are set.")
        }
        accountsButton.setTitle(title, for: .normal)
        
        usage.text = profile?.usage?.usageStringInGb(decimalUnits: decimalUnits) ?? "-"
        balance.text = profile?.balance?.moneyString ?? "-"
        estimatedFee.text = account?.estimatedFee(profile: profile)?.moneyString ?? "-"
        if let sessions = profile?.sessions {
            devices.text = String(sessions.count)
            devicesButton.isEnabled = true
        } else {
            devices.text = "-"
            devicesButton.isEnabled = false
        }
        
        // Chart end point.
        var usageY: Double? = nil
        
        usageSumEndDataset.values = []
        if let profile = profile, let usage = profile.usage {
            if Calendar.current.dateComponents([.year, .month], from: Date()) == Calendar.current.dateComponents([.year, .month], from: profile.updatedAt) {
                let day = Calendar.current.component(.day, from: profile.updatedAt)
                let entry = ChartDataEntry(x: Double(day), y: usage.usageInGb(decimalUnits: decimalUnits))
                usageSumEndDataset.values.append(entry)
                
                usageY = entry.y
            }
        }
        
        // Limit lines.
        chart.leftAxis.removeAllLimitLines()

        var freeY: Double? = nil
        var maxY: Double? = nil
        
        if let freeUsage = account?.freeUsage(profile: profile) {
            freeLimitLine.limit = freeUsage.usageInGb(decimalUnits: decimalUnits)
            chart.leftAxis.addLimitLine(freeLimitLine)
            
            freeY = freeLimitLine.limit
        }
        if let maxUsage = account?.maxUsage(profile: profile) {
            maxLimitLine.limit = maxUsage.usageInGb(decimalUnits: decimalUnits)
            chart.leftAxis.addLimitLine(maxLimitLine)
            
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
        chart.leftAxis.axisMaximum = y * 1.1

        chart.data?.notifyDataChanged()
        chart.notifyDataSetChanged()
    }

    func reloadHistory() {
        history = account?.history
        let decimalUnits = account?.configuration.decimalUnits ?? false
        
        let today = Date()
        let year = Calendar.current.component(.year, from:
            today)
        let month = Calendar.current.component(.month, from: today)

        estimatedFee.text = account?.estimatedFee(profile: profile)?.moneyString ?? "-"

        usageSumDataset.values = []
        if let history = history,
           history.year == year, history.month == month,
           !history.usageSums.isEmpty {

            for (index, usageSum) in history.usageSums.enumerated() {
                let entry = ChartDataEntry(x: Double(index + 1), y: usageSum.usageInGb(decimalUnits: decimalUnits))
                usageSumDataset.values.append(entry)
            }
        }

        chart.data?.notifyDataChanged()
        chart.notifyDataSetChanged()
    }

    func reload() {
        account = Account.main
        refreshedAt = nil
        refreshControl!.endRefreshing()
        
        reloadStatus()
        reloadProfile()
        reloadHistory()
    }

    func mainChanged(_ notification: Notification) {
        reload()
    }

    func statusUpdated(_ notification: Notification) {
        reloadStatus()
    }

    func profileUpdated(_ notification: Notification) {
        reloadProfile()
    }

    func historyUpdated(_ notification: Notification) {
        reloadHistory()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var frame = tableView.bounds
        frame.origin.y = -frame.height
        let upperBackgroundView = UIView(frame: frame)
        upperBackgroundView.backgroundColor = upperView.backgroundColor
        tableView.insertSubview(upperBackgroundView, at: 0)

        loginButton.lineWidth = 4
        loginButton.contentEdgeInsets.left = 20.0
        loginButton.contentEdgeInsets.right = 20.0
        loginButton.contentEdgeInsets.top = 20.0
        loginButton.contentEdgeInsets.bottom = 20.0

        usageSumDataset.drawCirclesEnabled = false
        usageSumDataset.lineWidth = 4
        usageSumDataset.drawFilledEnabled = true
        usageSumDataset.drawValuesEnabled = false

        usageSumEndDataset.drawValuesEnabled = false

        chart.data = LineChartData(dataSets: [usageSumDataset, usageSumEndDataset])

        chart.isUserInteractionEnabled = false
        chart.legend.enabled = false
        chart.chartDescription?.enabled = false

        chart.xAxis.labelTextColor = .lightGray
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.axisMinimum = 1.0
        chart.xAxis.axisMaximum = Double(Calendar.current.range(of: .day, in: .month, for: Date())?.upperBound ?? 31)

        chart.leftAxis.labelTextColor = .lightGray
        chart.leftAxis.gridColor = #colorLiteral(red: 0.9372541904, green: 0.9372367859, blue: 0.9563211799, alpha: 1)
        chart.leftAxis.axisLineColor = .white
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.drawLimitLinesBehindDataEnabled = true
        chart.rightAxis.enabled = false

        freeLimitLine.lineWidth = 1
        freeLimitLine.xOffset = 1
        freeLimitLine.yOffset = 1
        freeLimitLine.lineColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
        freeLimitLine.valueTextColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
        freeLimitLine.labelPosition = .leftTop

        maxLimitLine.lineWidth = 1
        maxLimitLine.xOffset = 1
        maxLimitLine.yOffset = 1
        maxLimitLine.lineColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        maxLimitLine.valueTextColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        maxLimitLine.labelPosition = .rightTop

        self.reload()

        NotificationCenter.default.addObserver(self, selector: #selector(mainChanged(_:)), name: .mainAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(statusUpdated(_:)), name: .accountStatusUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(profileUpdated(_:)), name: .accountProfileUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(historyUpdated(_:)), name: .accountHistoryUpdated, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        loginButton.layer.shadowColor = UIColor.lightGray.cgColor
        loginButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        loginButton.layer.shadowOpacity = 0.5
        loginButton.layer.shadowRadius = 2
        loginButton.layer.cornerRadius = loginButton.bounds.width / 2
        loginButton.layer.masksToBounds = false

        upperView.layer.shadowColor = UIColor.lightGray.cgColor
        upperView.layer.shadowOffset = CGSize(width: 0, height: 2)
        upperView.layer.shadowRadius = 2
        upperView.layer.shadowOpacity = 0.5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if refreshControl!.isRefreshing {
            // See https://stackoverflow.com/questions/21758892/uirefreshcontrol-stops-spinning-after-making-application-inactive
            let offset = tableView.contentOffset
            refreshControl?.endRefreshing()
            refreshControl?.beginRefreshing()
            tableView.contentOffset = offset
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        refreshIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.bounds.height - tableView.contentInset.top
    }
}

