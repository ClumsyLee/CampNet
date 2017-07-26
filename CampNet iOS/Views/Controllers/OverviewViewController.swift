//
//  FirstViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/17.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import NetworkExtension

import Charts
import DynamicButton
import PromiseKit
import CampNetKit

class OverviewViewController: UITableViewController {
    
    @IBOutlet var upperView: UIView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

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

    @IBAction func cancelSwitchingAccount(segue: UIStoryboardSegue) {}
    @IBAction func accountSwitched(segue: UIStoryboardSegue) {
        refresh()
    }
    
    @IBAction func tableRefreshed(_ sender: Any) {
        refresh()
        refreshControl!.endRefreshing()
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let account = account,
              let status = account.status else {
            return
        }
        
        switch status.type {
        case .online:
            loginButton.isEnabled = false
            loginButton.setStyle(.horizontalMoreOptions, animated: true)
            
            loginButtonCaption.text = NSLocalizedString("Logging Out…", comment: "Login button caption.")
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.setNetworkActivityIndicatorVisible(true)

            account.logout(on: DispatchQueue.global(qos: .userInitiated)).always {
                delegate.setNetworkActivityIndicatorVisible(false)
            }
            .catch { error in
                if let error = error as? CampNetError {
                    self.presentAlert(title: String.localizedStringWithFormat(NSLocalizedString("Unable to Login \"%@\"", comment: "Alert title when failed to login."), account.username), message: error.localizedDescription)
                }
            }
        case .offline:
            loginButton.isEnabled = false
            loginButton.setStyle(.horizontalMoreOptions, animated: true)
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.setNetworkActivityIndicatorVisible(true)
            
            loginButtonCaption.text = NSLocalizedString("Logging In…", comment: "Login button caption.")
            
            account.login(on: DispatchQueue.global(qos: .userInitiated)).always {
                delegate.setNetworkActivityIndicatorVisible(false)
            }
            .catch { error in
                if let error = error as? CampNetError {
                    self.presentAlert(title: String.localizedStringWithFormat(NSLocalizedString("Unable to Logout \"%@\"", comment: "Alert title when failed to logout."), account.username), message: error.localizedDescription)
                }
            }
        default: return
        }
    }

    var account: Account? = nil
    var usageSumDataset = LineChartDataSet(values: [], label: nil)
    var usageSumEndDataset = LineChartDataSet(values: [], label: nil)
    var freeLimitLine = ChartLimitLine(limit: 0.0, label: NSLocalizedString("Free", comment: "Limit line label in the history chart."))
    var maxLimitLine = ChartLimitLine(limit: 0.0, label: NSLocalizedString("Max", comment: "Limit line label in the history chart."))

    func refresh() {
        guard let account = account, !activityIndicator.isAnimating else {
            return
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.setNetworkActivityIndicatorVisible(true)
        activityIndicator.startAnimating()

        var promises: [Promise<Void>] = []

        promises.append(account.status().catch { error in
            if let error = error as? CampNetError {
                self.presentAlert(title: String.localizedStringWithFormat(NSLocalizedString("Unable to Update Status of \"%@\"", comment: "Alert title when failed to update account status."), account.username), message: error.localizedDescription)
            }
        }.asVoid())

        if account.configuration.actions[.profile] != nil {
            promises.append(account.profile().catch { error in
                if let error = error as? CampNetError {
                    self.presentAlert(title: String.localizedStringWithFormat(NSLocalizedString("Unable to Update Profile of \"%@\"", comment: "Alert title when failed to update account profile."), account.username), message: error.localizedDescription)
                }
            }.asVoid())
        }

        if account.configuration.actions[.history] != nil {
            promises.append(account.history().catch { error in
                if let error = error as? CampNetError {
                    self.presentAlert(title: String.localizedStringWithFormat(NSLocalizedString("Unable to Update History of \"%@\"", comment: "Alert title when failed to update account history."), account.username), message: error.localizedDescription)
                }
            }.asVoid())
        }

        when(resolved: promises).always {
            delegate.setNetworkActivityIndicatorVisible(false)
            // Don't touch the activity indicator if the account has been changed.
            if self.account == account {
                self.activityIndicator.stopAnimating()
            }
        }
    }

    func reloadStatus() {
        let status = account?.status

        if let type = status?.type {
            switch type {
            case .online:
                loginButton.isEnabled = true
                loginButton.backgroundColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
                loginButton.strokeColor = .white
                loginButton.setStyle(.stop, animated: true)
                
                loginButtonCaption.text = NSLocalizedString("Logout", comment: "Login button caption.")
            case .offline:
                loginButton.isEnabled = true
                loginButton.backgroundColor = .white
                loginButton.strokeColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
                loginButton.setStyle(.play, animated: true)
                
                loginButtonCaption.text = NSLocalizedString("Login", comment: "Login button caption.")
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

        network.text = (NEHotspotHelper.supportedNetworkInterfaces().first as? NEHotspotNetwork)?.ssid ?? "-"
    }

    func reloadProfile() {
        let title: String
        if let account = account {
            title = "\(account.profile?.name ?? account.username) ▾"
        } else {
            title = NSLocalizedString("Click to Setup Account", comment: "OverviewView title when no accounts are set.")
        }
        accountsButton.setTitle(title, for: .normal)

        let profile = account?.profile
        let decimalUnits = account?.configuration.decimalUnits ?? false
        
        usage.text = profile?.usage?.usageStringInGb(decimalUnits: decimalUnits) ?? "-"
        balance.text = profile?.balance?.moneyString ?? "-"
        estimatedFee.text = account?.estimatedFee?.moneyString ?? "-"
        devices.text = profile != nil ? String(profile!.sessions.count) : "-"

        // Limit lines.
        chart.leftAxis.removeAllLimitLines()

        if let freeUsage = account?.freeUsage {
            freeLimitLine.limit = freeUsage.usageInGb(decimalUnits: decimalUnits)
            chart.leftAxis.addLimitLine(freeLimitLine)
        }
        if let maxUsage = account?.maxUsage {
            maxLimitLine.limit = maxUsage.usageInGb(decimalUnits: decimalUnits)
            chart.leftAxis.addLimitLine(maxLimitLine)
        }

        chart.data?.notifyDataChanged()
        chart.notifyDataSetChanged()
    }

    func reloadHistory() {
        let today = Date()
        let year = Calendar.current.component(.year, from:
            today)
        let month = Calendar.current.component(.month, from: today)
        let decimalUnits = account?.configuration.decimalUnits ?? false

        estimatedFee.text = account?.estimatedFee?.moneyString ?? "-"

        usageSumDataset.values = []
        usageSumEndDataset.values = []

        if let history = account?.history,
           history.year == year, history.month == month,
           !history.usageSums.isEmpty {

            var lastEntry: ChartDataEntry!
            for (index, usageSum) in history.usageSums.enumerated() {
                lastEntry = ChartDataEntry(x: Double(index + 1), y: usageSum.usageInGb(decimalUnits: decimalUnits))
                usageSumDataset.values.append(lastEntry)
            }
            usageSumEndDataset.values.append(lastEntry)
        }

        chart.data?.notifyDataChanged()
        chart.notifyDataSetChanged()
    }

    func reload() {
        activityIndicator.stopAnimating()
        reloadStatus()
        reloadProfile()
        reloadHistory()
    }

    func mainChanged(_ notification: Notification) {
        let newMain = Account.main
        if account != newMain {
            account = newMain
            reload()
            refresh()
        }
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
        freeLimitLine.yOffset = 1
        freeLimitLine.lineColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
        freeLimitLine.valueTextColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
        freeLimitLine.labelPosition = .leftBottom

        maxLimitLine.lineWidth = 1
        maxLimitLine.yOffset = 1
        maxLimitLine.lineColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        maxLimitLine.valueTextColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        maxLimitLine.labelPosition = .rightBottom

        self.account = Account.main
        reload()

        NotificationCenter.default.addObserver(self, selector: #selector(mainChanged(_:)), name: .mainAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(statusUpdated(_:)), name: .accountStatusUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(profileUpdated(_:)), name: .accountProfileUpdated, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(authorizationChanged(_:)), name: .accountAuthorizationChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(historyUpdated(_:)), name: .accountHistoryUpdated, object: nil)

        refresh()
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

