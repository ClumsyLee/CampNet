//
//  OverviewViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/17.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import UIKit
import NetworkExtension

import Charts
import DynamicButton
import Firebase
import Instabug
import PromiseKit
import SwiftRater

import CampNetKit

class OverviewViewController: UITableViewController {

    enum ForegroundStatus {
        case loggingIn
        case loggingOut
        case loggingOutOthers
    }

    static let networkUpdateInterval: TimeInterval = 10

    @IBOutlet var upperView: UIView!

    var upperBackgroundView: UIView!

    @IBOutlet var usageTitle: UILabel!
    @IBOutlet var usage: UILabel!
    @IBOutlet var usageUnit: UILabel!
    @IBOutlet var balance: UILabel!
    @IBOutlet var dataBalance: UILabel!
    @IBOutlet var networkName: UILabel!
    @IBOutlet var devices: UILabel!

    var networkDisclosure: UITableViewCell!
    var devicesDisclosure: UITableViewCell!

    @IBOutlet var accountsButton: UIButton!
    var settingsBadge: UILabel!
    @IBOutlet var networkButton: UIButton!
    @IBOutlet var devicesButton: UIButton!
    @IBOutlet var loginButton: DynamicButton!
    @IBOutlet var loginButtonCaption: UILabel!

    @IBOutlet var chart: UsageChartView!

    var account: Account?
    var status: Status?
    var profile: Profile?
    var history: History?

    var network: NEHotspotNetwork?
    var ip: String = ""

    var foregroundStatuses: [String: ForegroundStatus] = [:]
    var backgroundRefreshings: [String: Bool] = [:]
    var networkTimer = Timer()


    @IBAction func accountSwitched(segue: UIStoryboardSegue) {}

    @IBAction func feedbackPressed(_ sender: Any) {
        BugReporting.invoke()
    }

    @IBAction func settingsPressed(_ sender: Any) {
        performSegue(withIdentifier: "settingsPressed", sender: sender)
    }

    @IBAction func refreshTable(_ sender: Any) {
        reloadNetwork()

        guard let account = account else {
            self.refreshControl?.endRefreshing()
            return
        }

        _ = account.update().done {
            SwiftRater.incrementSignificantUsageCount()
        }.ensure {
            // Don't touch refreshControl if the account has been changed.
            if self.account == account {
                self.refreshControl?.endRefreshing()
            }
        }

        Analytics.logEvent("overview_refresh", parameters: nil)
    }

    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let account = account, let status = status else {
            return
        }

        switch status.type {
        case let .online(onlineUsername):
            if let network = network, onlineUsername == nil || account.username == onlineUsername!,
                account.canManage(network), account.shouldAutoLogin {
                // Will auto login after logging out, warn for it.
                let menu = UIAlertController(title: L10n.Overview.LogoutWhenAutoLoginAlert.title, message: nil,
                                             preferredStyle: .actionSheet)
                menu.view.tintColor = #colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1)

                let logoutAction = UIAlertAction(title: L10n.Overview.LogoutWhenAutoLoginAlert.Actions.logout,
                                                 style: .destructive) { action in
                    self.logout()
                }
                let cancelAction = UIAlertAction(title: L10n.Overview.LogoutWhenAutoLoginAlert.Actions.cancel,
                                                 style: .cancel, handler: nil)

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

                let menu = UIAlertController(title: L10n.Overview.LoginUnknownNetworkAlert.title(network.ssid),
                                             message: L10n.Overview.LoginUnknownNetworkAlert.message,
                                             preferredStyle: .actionSheet)
                menu.view.tintColor = #colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1)

                let markAction = UIAlertAction(title: L10n.Overview.LoginUnknownNetworkAlert.Actions.markAsOnCampus,
                                               style: .default) { action in
                    Defaults[.onCampus(id: account.configuration.identifier, ssid: network.ssid)] = true
                    Analytics.logEvent("remember_network", parameters: ["network": network.ssid])
                }
                let laterAction = UIAlertAction(title: L10n.Overview.LoginUnknownNetworkAlert.Actions.later,
                                                style: .cancel, handler: nil)

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

        // Lock the button.
        foregroundStatuses[account.identifier] = .loggingIn
        reloadStatus(autoLogin: false)

        _ = account.login().done {
            SwiftRater.incrementSignificantUsageCount()

            // Update the profile in the background if possible.
            if account.configuration.actions[.profile] != nil {
                _ = account.profile()
            }
        }.ensure {
            // Unlock the button.
            self.foregroundStatuses[account.identifier] = nil
            if account == self.account {
                self.reloadStatus(autoLogin: false)
            }
        }

        Analytics.logEvent("foreground_login", parameters: nil)
    }

    func logout() {
        guard let account = account else {
            return
        }

        // Lock the button.
        if case let .online(onlineUsername)? = status?.type, onlineUsername != account.username {
            foregroundStatuses[account.identifier] = .loggingOutOthers
        } else {
            foregroundStatuses[account.identifier] = .loggingOut
        }
        reloadStatus(autoLogin: false)

        _ = account.logout().done {
            SwiftRater.incrementSignificantUsageCount()
        }.ensure {
            // Unlock the button.
            self.foregroundStatuses[account.identifier] = nil
            if account == self.account {
                self.reloadStatus(autoLogin: false)
            }
        }

        Analytics.logEvent("foreground_logout", parameters: nil)
    }

    func refreshIfNeeded() {
        guard UIApplication.shared.applicationState == .active, !Device.inUITest else {
            return
        }

        // Refresh the network.
        reloadNetwork()

        // Refresh the account.
        guard let account = account, account.shouldAutoUpdate, !refreshControl!.isRefreshing,
              !(backgroundRefreshings[account.identifier] ?? false) else {
            return
        }
        backgroundRefreshings[account.identifier] = true

        _ = account.update().ensure {
            // Don't touch backgroundRefreshings if the account has been changed.
            if self.account == account {
                self.backgroundRefreshings[account.identifier] = nil
            }
        }
    }

    func reloadNetworkColor() {
        if let account = account, let network = network, account.canManage(network) {
            networkName.textColor = .darkText
        } else {
            networkName.textColor = .lightGray

            if Device.inUITest {
                networkName.textColor = .darkText
            }
        }
    }

    @objc func reloadNetwork() {
        if let wifi = NEHotspotHelper.supportedNetworkInterfaces()?.first as? NEHotspotNetwork, !wifi.ssid.isEmpty {
            network = wifi
            networkName.text = wifi.ssid
            networkButton.isEnabled = true
            networkDisclosure.isHidden = false
        } else {
            network = nil
            networkName.text = "-"
            networkButton.isEnabled = false
            networkDisclosure.isHidden = true

            if Device.inUITest {
                networkName.text = "Tsinghua-IPv4"
                networkDisclosure.isHidden = false
            }
        }
        reloadNetworkColor()

        ip = WiFi.ip ?? ""
    }

    func reloadStatus(autoLogin: Bool = true) {
        status = account?.status

        if let foregroundStatus = foregroundStatuses[account?.identifier ?? ""] {
            loginButton.isEnabled = false
            loginButton.setStyle(.horizontalMoreOptions, animated: true)

            switch foregroundStatus {
            case .loggingIn:
                loginButton.backgroundColor = .white
                loginButton.strokeColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
                loginButtonCaption.text = L10n.Overview.LoginButton.Captions.loggingIn
            case .loggingOut:
                loginButton.backgroundColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
                loginButton.strokeColor = .white
                loginButtonCaption.text = L10n.Overview.LoginButton.Captions.loggingOut
            case .loggingOutOthers:
                loginButton.backgroundColor = #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
                loginButton.strokeColor = .white
                loginButtonCaption.text = L10n.Overview.LoginButton.Captions.loggingOut
            }
        } else if let type = status?.type {
            switch type {
            case let .online(onlineUsername):
                if let username = account?.username, let onlineUsername = onlineUsername, username != onlineUsername {
                    loginButton.isEnabled = true
                    loginButton.backgroundColor = #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
                    loginButton.strokeColor = .white
                    loginButton.setStyle(.stop, animated: true)

                    loginButtonCaption.text = L10n.Overview.LoginButton.Captions.logoutOthers(onlineUsername)
                } else {
                    loginButton.isEnabled = true
                    loginButton.backgroundColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
                    loginButton.strokeColor = .white
                    loginButton.setStyle(.stop, animated: true)

                    loginButtonCaption.text = L10n.Overview.LoginButton.Captions.logout
                }

            case .offline:
                loginButton.isEnabled = true
                loginButton.backgroundColor = .white
                loginButton.strokeColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
                loginButton.setStyle(.play, animated: true)

                loginButtonCaption.text = L10n.Overview.LoginButton.Captions.login

                if let account = account, let network = network, account.canManage(network), account.shouldAutoLogin,
                   UIApplication.shared.applicationState == .active, autoLogin {
                    login()
                }

            case .offcampus:
                loginButton.isEnabled = false
                loginButton.backgroundColor = #colorLiteral(red: 0.9372541904, green: 0.9372367859, blue: 0.9563211799, alpha: 1)
                loginButton.strokeColor = .lightGray
                loginButton.setStyle(.horizontalLine, animated: true)

                loginButtonCaption.text = L10n.Overview.LoginButton.Captions.offcampus
            }
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = #colorLiteral(red: 0.9372541904, green: 0.9372367859, blue: 0.9563211799, alpha: 1)
            loginButton.strokeColor = .lightGray
            loginButton.setStyle(.dot, animated: true)

            loginButtonCaption.text = L10n.Overview.LoginButton.Captions.unknown
        }
    }

    func reloadProfile() {
        profile = account?.profile
        let decimalUnits = account?.configuration.decimalUnits ?? false

        let title: String
        if let account = account {
            title = "\(profile?.name ?? account.username) ▸"
        } else {
            title = "\(L10n.Overview.Titles.noAccounts) ▸"
        }
        accountsButton.setTitle(title, for: .normal)

        if let usageStr = profile?.usage?.usageStringInGb(decimalUnits: decimalUnits) {
            usage.text = usageStr
            usage.textColor = .white
        } else {
            usage.text = "-"
            usage.textColor = .lightText
        }

        if let moneyString = profile?.balance?.moneyString {
            balance.text = moneyString
            balance.textColor = .white
        } else {
            balance.text = "-"
            balance.textColor = .lightText
        }

        if let dataBalanceStr = profile?.dataBalance?.usageStringInGb(decimalUnits: decimalUnits) {
            dataBalance.text = dataBalanceStr
            dataBalance.textColor = .white
        } else {
            dataBalance.text = "-"
            dataBalance.textColor = .lightText
        }

        if let sessions = profile?.sessions {
            devices.text = String(sessions.count)
            devices.textColor = .darkText
            devicesButton.isEnabled = true
            devicesDisclosure.isHidden = false
        } else {
            devices.text = "-"
            devices.textColor = .lightGray
            devicesButton.isEnabled = false
            devicesDisclosure.isHidden = true
        }

        chart.reloadProfile(profile: profile, decimalUnits: decimalUnits)
    }

    func reloadHistory() {
        history = account?.history
        let decimalUnits = account?.configuration.decimalUnits ?? false

        chart.reloadHistory(history: history ,decimalUnits: decimalUnits)
    }

    func reload(_ account: Account?) {
        self.account = account

        if refreshControl!.isRefreshing {
            refreshControl!.endRefreshing()  // Doing it alone will cause a bug on iOS 9.
        }

        reloadNetwork()
        reloadStatus()
        reloadProfile()
        reloadHistory()

        refreshIfNeeded()
    }

    @objc func accountAdded(_ notification: Notification) {
        guard account != nil else {
            // This account will actually trigger mainChanged, update will be performed so we do not need to validdate
            //   it now.
            return
        }

        if let account = notification.userInfo?["account"] as? Account {
            // Validate & initial update.
            _ = account.update()
        }
    }

    @objc func mainChanged(_ notification: Notification) {
        let main = notification.userInfo?["toAccount"] as? Account

        if let account = account {
            if let main = main, account == main {
                // Nothing happened actually.
            } else {
                reload(main)
            }
        } else {
            if main != nil {
                reload(main)
            }
        }
    }

    @objc func statusUpdated(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account, account == self.account else {
            return
        }
        reloadStatus()
    }

    @objc func profileUpdated(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account, account == self.account else {
            return
        }
        reloadProfile()
    }

    @objc func historyUpdated(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account, account == self.account else {
            return
        }
        reloadHistory()
    }

    @objc func didBecomeActive(_ notification: Notification) {
        refreshIfNeeded()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Remove the 1 pixel line under the navbar.
        let bar = navigationController!.navigationBar
        bar.setBackgroundImage(UIImage(), for: .default)
        bar.shadowImage = UIImage()

        setupBarButtons()
        setupDashboard()

        self.reload(Account.main)

        NotificationCenter.default.addObserver(self, selector: #selector(accountAdded(_:)),
                                               name: .accountAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(mainChanged(_:)),
                                               name: .mainAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(statusUpdated(_:)),
                                               name: .accountStatusUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(profileUpdated(_:)),
                                               name: .accountProfileUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(historyUpdated(_:)),
                                               name: .accountHistoryUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    fileprivate func setupBarButtons() {
        // Setup the right bar button item with a red dot.
        // https://stackoverflow.com/a/41250928/4154977
        settingsBadge = UILabel(frame: CGRect(x: 16, y: 1, width: 8, height: 8))
        settingsBadge.layer.borderColor = UIColor.clear.cgColor
        settingsBadge.layer.borderWidth = 2
        settingsBadge.layer.cornerRadius = settingsBadge.bounds.size.height / 2
        settingsBadge.layer.masksToBounds = true
        settingsBadge.backgroundColor = .clear

        let rightButton = UIButton(type: .system)
        rightButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        rightButton.setBackgroundImage(UIImage(named: "settings")?.withRenderingMode(.alwaysTemplate), for: .normal)
        rightButton.addTarget(self, action: #selector(settingsPressed), for: .touchUpInside)
        rightButton.addSubview(settingsBadge)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
    }

    fileprivate func setupDashboard() {
        // Setup the upper view.
        upperBackgroundView = UIView()
        upperBackgroundView.backgroundColor = upperView.backgroundColor
        tableView.insertSubview(upperBackgroundView, at: 0)

        // Shrink the headline for small screens.
        if tableView.bounds.height < 500 {
            usageTitle.font = UIFont.systemFont(ofSize: 15)
            usage.font = UIFont.systemFont(ofSize: 54, weight: .thin)
            usageUnit.font = UIFont.systemFont(ofSize: 27, weight: .light)
        }

        // Setup the buttons.
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

        settingsBadge.backgroundColor = Defaults.potentialDonator ? .red : .clear

        if refreshControl!.isRefreshing {
            // See https://stackoverflow.com/questions/21758892/uirefreshcontrol-stops-spinning-after-making-application-inactive
            let offset = tableView.contentOffset
            refreshControl?.endRefreshing()
            refreshControl?.beginRefreshing()
            tableView.contentOffset = offset
        }

        reloadNetwork()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        networkTimer = Timer.scheduledTimer(timeInterval: OverviewViewController.networkUpdateInterval, target: self,
                                            selector: #selector(reloadNetwork), userInfo: nil, repeats: true)

        // We don't have many changes, so make sure we are in the foreground when rating.
        if UIApplication.shared.applicationState == .active {
            SwiftRater.check()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        networkTimer.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if #available(iOS 11.0, *) {
            return tableView.bounds.height - tableView.safeAreaInsets.top - tableView.safeAreaInsets.bottom
        } else {
            return tableView.bounds.height
        }
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

