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
import SwiftRater

import CampNetKit

class OverviewViewController: UITableViewController {
    static let autoUpdateTimeInterval: TimeInterval = 300
    
    @IBOutlet var upperView: UIView!
    
    var upperBackgroundView: UIView!

    @IBOutlet var usage: UILabel!
    @IBOutlet var balance: UILabel!
    @IBOutlet var estimatedFee: UILabel!
    @IBOutlet var networkName: UILabel!
    @IBOutlet var devices: UILabel!

    var networkDisclosure: UITableViewCell!
    var devicesDisclosure: UITableViewCell!
    
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
    
    var network: NEHotspotNetwork? = nil
    var ip: String = ""
    
    var usageSumDataset = LineChartDataSet(values: [], label: nil)
    var usageSumEndDataset = LineChartDataSet(values: [], label: nil)
    var freeLimitLine = ChartLimitLine(limit: 0.0, label: NSLocalizedString("Free", comment: "Limit line label in the history chart."))
    var maxLimitLine = ChartLimitLine(limit: 0.0, label: NSLocalizedString("Max", comment: "Limit line label in the history chart."))
    
    var refreshedAt: Date? = nil

    @IBAction func accountSwitched(segue: UIStoryboardSegue) {}
    
    @IBAction func feedbackPressed(_ sender: Any) {
        Instabug.invoke()
    }
    
    @IBAction func refreshTable(_ sender: Any) {
        reloadNetwork()
        
        guard let account = account else {
            self.refreshControl?.endRefreshing()
            return
        }
        print("Refreshing \(account.identifier) in overview.")
        
        account.update(on: DispatchQueue.global(qos: .userInitiated)).then { _ -> Void in
            SwiftRater.incrementSignificantUsageCount()
            
            self.refreshedAt = Date()
        }
        .always {
            // Don't touch refreshControl if the account has been changed.
            if self.account == account {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let account = account, let status = status else {
            return
        }
        
        switch status.type {
        case let .online(onlineUsername, _, _):
            if let network = network, account.username == onlineUsername, account.canManage(network: network) {
                // Will auto login after logging out, warn for it.
                let menu = UIAlertController(title: NSLocalizedString("Auto Login Will Be Triggered After Logging Out. Do You Want to Logout Anyway?", comment: "Title on alerts."), message: nil, preferredStyle: .actionSheet)
                menu.view.tintColor = #colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1)
                
                let logoutAction = UIAlertAction(title: NSLocalizedString("Logout", comment: "Logout button on alerts."), style: .destructive) { action in
                    self.logout()
                }
                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button on alerts."), style: .cancel, handler: nil)
                
                menu.addAction(logoutAction)
                menu.addAction(cancelAction)
                
                // Show as a popover on iPads.
                if let popoverPresentationController = menu.popoverPresentationController {
                    popoverPresentationController.sourceView = loginButton
                    popoverPresentationController.sourceRect = loginButton.bounds
                }
                
                present(menu, animated: true, completion: nil)
            } else {
                logout()
            }
            
        case .offline:
            if let network = network,
               !account.configuration.ssids.contains(network.ssid),
               !Defaults[.onCampus(id: account.configuration.identifier, ssid: network.ssid)] {
                // Manually logging into an unknown network.
                
                let menu = UIAlertController(title: String.localizedStringWithFormat(NSLocalizedString("Do You Want to Mark \"%@\" as \"On Campus\"?", comment: "Title on alerts."), network.ssid), message: NSLocalizedString("\"Auto Login\" will only be effective in networks marked as \"On Campus\".", comment: "Message on alerts."), preferredStyle: .actionSheet)
                menu.view.tintColor = #colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1)
                
                let markAction = UIAlertAction(title: NSLocalizedString("Mark As \"On Campus\"", comment: "Mark as on campus button on alerts."), style: .default) { action in
                    Defaults[.onCampus(id: account.configuration.identifier, ssid: network.ssid)] = true
                }
                let laterAction = UIAlertAction(title: NSLocalizedString("Later", comment: "Later button on alerts."), style: .cancel, handler: nil)
                
                menu.addAction(markAction)
                menu.addAction(laterAction)
                
                // Show as a popover on iPads.
                if let popoverPresentationController = menu.popoverPresentationController {
                    popoverPresentationController.sourceView = loginButton
                    popoverPresentationController.sourceRect = loginButton.bounds
                }
                
                present(menu, animated: true, completion: nil)
            }
            
            login()
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
        
        account.login(on: DispatchQueue.global(qos: .userInitiated)).then { _ -> Void in
            SwiftRater.incrementSignificantUsageCount()
            
            // Update the profile in the background if possible.
            if account.configuration.actions[.profile] != nil {
                _ = account.profile()
            }
        }
        .catch { _ in
            self.reloadStatus(autoLogin: false)  // Avoid logging in forever.
        }
    }
    
    func logout() {
        guard let account = account else {
            return
        }
        
        loginButton.isEnabled = false
        loginButton.setStyle(.horizontalMoreOptions, animated: true)
        
        loginButtonCaption.text = NSLocalizedString("Logging Out…", comment: "Login button caption.")
        
        account.logout(on: DispatchQueue.global(qos: .userInitiated)).then { _ -> Void in
            SwiftRater.incrementSignificantUsageCount()
        }
        .catch { _ in
            self.reloadStatus()
        }
    }
    
    func refreshIfNeeded() {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        
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
    
    func reloadNetwork() {
        if let wifi = NEHotspotHelper.supportedNetworkInterfaces().first as? NEHotspotNetwork, !wifi.ssid.isEmpty {
            network = wifi
            networkName.text = wifi.ssid
            networkButton.isEnabled = true
            networkDisclosure.isHidden = false
        } else {
            network = nil
            networkName.text = "-"
            networkButton.isEnabled = false
            networkDisclosure.isHidden = true
        }
        ip = wifiIp() ?? ""
    }

    func reloadStatus(autoLogin: Bool = true) {
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
                
                if let account = account, let network = network, account.canManage(network: network), autoLogin {
                    login()
                }
                
            case .offcampus:
                loginButton.isEnabled = false
                loginButton.backgroundColor = #colorLiteral(red: 0.9372541904, green: 0.9372367859, blue: 0.9563211799, alpha: 1)
                loginButton.strokeColor = .lightGray
                loginButton.setStyle(.horizontalLine, animated: true)
                
                loginButtonCaption.text = NSLocalizedString("Off-campus", comment: "Login button caption.")
            }
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = #colorLiteral(red: 0.9372541904, green: 0.9372367859, blue: 0.9563211799, alpha: 1)
            loginButton.strokeColor = .lightGray
            loginButton.setStyle(.dot, animated: true)
            
            loginButtonCaption.text = NSLocalizedString("Unknown", comment: "Login button caption.")
        }
    }

    func reloadProfile() {
        profile = account?.profile
        let decimalUnits = account?.configuration.decimalUnits ?? false
        
        let title: String
        if let account = account {
            title = "\(account.username) ▸"
        } else {
            title = "\(NSLocalizedString("No Accounts", comment: "OverviewView title when no accounts are set.")) ▸"
        }
        accountsButton.setTitle(title, for: .normal)
        
        usage.text = profile?.usage?.usageStringInGb(decimalUnits: decimalUnits) ?? "-"
        balance.text = profile?.balance?.moneyString ?? "-"
        estimatedFee.text = account?.estimatedFee(profile: profile)?.moneyString ?? "-"
        if let sessions = profile?.sessions {
            devices.text = String(sessions.count)
            devicesButton.isEnabled = true
            devicesDisclosure.isHidden = false
        } else {
            devices.text = "-"
            devicesButton.isEnabled = false
            devicesDisclosure.isHidden = true
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
        
        reloadNetwork()
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
    
    func didBecomeActive(_ notification: Notification) {
        refreshIfNeeded()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        upperBackgroundView = UIView()
        upperBackgroundView.backgroundColor = upperView.backgroundColor
        tableView.insertSubview(upperBackgroundView, at: 0)
        
        networkDisclosure = UITableViewCell()
        networkDisclosure.accessoryType = .disclosureIndicator
        networkDisclosure.isUserInteractionEnabled = false
        networkDisclosure.isHidden = true
        networkButton.addSubview(networkDisclosure)
        
        devicesDisclosure = UITableViewCell()
        devicesDisclosure.accessoryType = .disclosureIndicator
        devicesDisclosure.isUserInteractionEnabled = false
        devicesDisclosure.isHidden = true
        devicesButton.addSubview(devicesDisclosure)

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
        
        var frame = tableView.bounds
        frame.origin.y = -frame.height
        upperBackgroundView.frame = frame
        
        networkDisclosure.frame = networkButton.bounds
        devicesDisclosure.frame = devicesButton.bounds
        
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
        SwiftRater.check()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.bounds.height - tableView.contentInset.top
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "network" {
            let controller = segue.destination as! NetworkViewController
            controller.account = account
            controller.network = network!
            controller.ip = ip
        }
    }
}

