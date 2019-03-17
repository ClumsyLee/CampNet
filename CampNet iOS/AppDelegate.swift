//
//  AppDelegate.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/17.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import NetworkExtension
import UIKit
import UserNotifications

import BRYXBanner
import Firebase
import Instabug
import PromiseKit
import SwiftyBeaver
import SwiftRater
import SwiftyStoreKit

import CampNetKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    static let bannerDuration = 3.0
    static let loginErrorNotificationInterval: TimeInterval = 86400
    public static let donateRequestInterval = 30  // In terms of auto-login count.
    public static let donateRequestMinInterval: TimeInterval = 7 * 86400
    public static let donationRequestIdentifier = "donationRequest"

    var window: UIWindow?
    var logFileURL: URL?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        setDefaultsIfNot()  // Do it first to ensure that the defaults can be read in the following setups.

        setUpInstaBug()
        setUpSwiftRater()
        setUpSwiftyBeaver()

        // Make sure Firebase is initialized after IAP so that the IAP observer can receive
        // all purchase notifications.
        setUpIAP()
        setUpFirebase()

        setUpCampNet(application)
        NEHotspotHelper.register(displayName: L10n.HotspotHelper.displayName)

        return true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types
        //   of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the
        //   application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games
        //   should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application
        //   state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of
        //   applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the
        //   changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the
        //   application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also
        //   applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let accounts = Account.all
        guard !accounts.isEmpty else {
            completionHandler(.noData)
            Analytics.logEvent("background_fetch", parameters: ["result": "no_data"])
            return
        }

        var promises: [Promise<Void>] = []
        for accountArray in accounts.values {
            for account in accountArray {
                promises.append(account.updateIfNeeded(on: DispatchQueue.global(qos: .utility)))
            }
        }

        // Wait at most 25 seconds to avoid being killed before replying.
        let timeout = after(seconds: 25).map{ _ in [Result<Void>]() }
        race(when(resolved: promises), timeout).done { results in
            if results.contains(where: { $0.isFulfilled }) {
                completionHandler(.newData)
                Analytics.logEvent("background_fetch", parameters: ["result": "new_data"])
            } else {
                completionHandler(.failed)
                Analytics.logEvent("background_fetch", parameters: ["result": "failed"])
            }
        }
    }

    // Notification handler for iOS 9.
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        userNotificationsAllowed(notificationSettings.types.contains(.alert))
    }

    func userNotificationsAllowed(_ allowed: Bool) {
        if allowed {
            log.info("User notifications are allowed.")
        } else {
            log.warning("User notifications are not allowed.")
        }
        Analytics.setUserProperty(allowed.description, forName: "user_notifications_allowed")
    }

    func setDefaultsIfNot() {
        if !Defaults.hasKey(.autoLogin) {
            Defaults[.autoLogin] = true
        }
        if !Defaults.hasKey(.autoLogoutExpiredSessions) {
            Defaults[.autoLogoutExpiredSessions] = true
        }
        if !Defaults.hasKey(.usageAlertRatio) {
            Defaults[.usageAlertRatio] = 0.90
        }
        if !Defaults.hasKey(.sendLogs) {
            Defaults[.sendLogs] = true
        }
        if !Defaults.hasKey(.donated) {
            Defaults[.donated] = false
        }
        if !Defaults.hasKey(.customConfiguration) {
            Defaults[.customConfiguration] = ""
        }
        if !Defaults.hasKey(.customConfigurationUrl) {
            Defaults[.customConfigurationUrl] = ""
        }
        if !Defaults.hasKey(.loginCount) {
            Defaults[.loginCount] = 0
        }
        if !Defaults.hasKey(.loginCountStartDate) {
            Defaults[.loginCountStartDate] = Date()
        }

        // One-time flags.
        if !Defaults.hasKey(.tsinghuaAuth4Migrated) && !Device.inUITest {
            migrateTsinghuaAuth4()
            Defaults[.tsinghuaAuth4Migrated] = true
        }
    }

    func migrateTsinghuaAuth4() {
        let oldIdentifier = "cn.edu.tsinghua"
        let newIdentifier = "cn.edu.tsinghua.auth4"

        // Copy the existing Tsinghua accounts to the new configuration.
        for (configuration, accounts) in Account.all {
            guard configuration.identifier == oldIdentifier else {
                continue
            }

            for account in accounts {
                Account.add(configurationIdentifier: newIdentifier, username: account.username, password: account.password)
            }
            break
        }

        // Transfer the main account.
        for (configuration, accounts) in Account.all {
            guard configuration.identifier == newIdentifier else {
                continue
            }

            if let account = accounts.first {
                Account.makeMain(account)
            }
            break
        }
    }

    func setUpInstaBug() {
        Instabug.start(withToken: "0df1051f1ad636fc8efd87baef010aaa", invocationEvents: [.shake])
        if Device.inUITest {
            Instabug.welcomeMessageMode = .disabled
        }
        BugReporting.promptOptions = [.feedback]
        BugReporting.enabledAttachmentTypes = []
    }

    func setUpSwiftRater() {
        SwiftRater.appId = "1263284287"
        SwiftRater.daysUntilPrompt = 7
        SwiftRater.significantUsesUntilPrompt = 3
        SwiftRater.daysBeforeReminding = 1
        SwiftRater.appLaunched()
    }

    func setUpSwiftyBeaver() {
        let console = ConsoleDestination()
        log.addDestination(console)

        let file = FileDestination()
        _ = file.deleteLogFile()
        self.logFileURL = file.logFileURL
        // Remove colors.
        file.format = file.format.replacingOccurrences(of: "$C", with: "")
        file.format = file.format.replacingOccurrences(of: "$c", with: "")
        log.addDestination(file)
    }

    func setUpIAP() {
        SwiftyStoreKit.shouldAddStorePaymentHandler = { payment, product in
            // The content can be delivered by the app itself.
            return true;
        }

        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // We don't have contents to deliver.
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    // Unlock content.

                case .failed, .purchasing, .deferred:
                    break  // Do nothing.
                }
            }
        }
    }

    func setUpFirebase() {
        if !Defaults[.sendLogs] {
            return
        }
        FirebaseApp.configure()

        Analytics.setUserProperty(Defaults[.autoLogin].description, forName: "auto_login")
        Analytics.setUserProperty(Defaults[.autoLogoutExpiredSessions].description, forName: "auto_logout_expired_sess")
        Analytics.setUserProperty(Defaults[.usageAlertRatio]?.description ?? "off", forName: "usage_alert_ratio")
        Analytics.setUserProperty(Defaults[.donated].description, forName: "donated")
        Analytics.setUserProperty(Defaults[.loginCount].description, forName: "login_count")
    }

    func setUpCampNet(_ application: UIApplication) {
        Action.networkActivityIndicatorHandler = { value in
            application.isNetworkActivityIndicatorVisible = value
        }

        // Do not request notification authorization when UI testing to prevent that system dialog from appearing.
        if !Device.inUITest {
            requestNotificationAuthorization()
        }

        // Setup notification categories.
        if #available(iOS 10.0, *) {
            var usageAlert: UNNotificationCategory
            let identifier = "usageAlert"
            let hidden = NSString.localizedUserNotificationString(forKey: "notifications.usage_alert.hidden", arguments: nil)
            let summary = NSString.localizedUserNotificationString(forKey: "notifications.usage_alert.summary", arguments: nil)

            if #available(iOS 12.0, *) {
                usageAlert = UNNotificationCategory(identifier: identifier, actions: [], intentIdentifiers: [],
                                                    hiddenPreviewsBodyPlaceholder: hidden,
                                                    categorySummaryFormat: summary)
            } else if #available(iOS 11.0, *) {
                usageAlert = UNNotificationCategory(identifier: identifier, actions: [], intentIdentifiers: [],
                                                    hiddenPreviewsBodyPlaceholder: hidden)
            } else {
                usageAlert = UNNotificationCategory(identifier: identifier, actions: [], intentIdentifiers: [])
            }

            UNUserNotificationCenter.current().setNotificationCategories([usageAlert])
        }

        // Update the profile in the background every now and then.
        application.setMinimumBackgroundFetchInterval(Account.profileAutoUpdateInterval)

        // Add observers for notifications.
        addObservers()
    }

    func requestNotificationAuthorization() {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                self.userNotificationsAllowed(granted)
            }
        } else {
            // Fallback on earlier versions
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound, .badge],
                                                                                             categories: nil))
        }

    }

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }

    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if UIApplication.shared.applicationState == .active {
            showErrorBanner(title: notification.alertTitle, body: notification.alertBody)
        } else if notification.userInfo?["identifier"] as? String == AppDelegate.donationRequestIdentifier {
            navigateToSupportUs()
        }

    }

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == AppDelegate.donationRequestIdentifier {
            navigateToSupportUs()
        }

        completionHandler()
    }

    func navigateToSupportUs() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "supportUsViewController")
        let navController = window?.rootViewController as! UINavigationController

        navController.pushViewController(controller, animated: true)
    }

    @objc func accountLoginError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }

        let title = L10n.Notifications.LoginError.title(account.displayName)
        if UIApplication.shared.applicationState == .active {
            showErrorBanner(title: title, body: error.localizedDescription)
        } else {
            if let date = Defaults[.accountLastLoginErrorNotification(of: account.identifier)],
               -date.timeIntervalSinceNow <= AppDelegate.loginErrorNotificationInterval {
                // Should not send a notification.
            } else {
                switch error {
                case .arrears, .unauthorized:
                    sendNotification(title: title, body: error.localizedDescription,
                                     identifier: "\(account.identifier).accountLoginError",
                                     userInfo: ["account": account.identifier])
                    Defaults[.accountLastLoginErrorNotification(of: account.identifier)] = Date()
                default:
                    break  // Do not send notifications for other types because the user cannot fix them.
                }
            }
        }
    }

    @objc func accountLogoutError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }

        let title = L10n.Notifications.LogoutError.title(account.displayName)
        if UIApplication.shared.applicationState == .active {
            showErrorBanner(title: title, body: error.localizedDescription)
        }
    }

    @objc func accountStatusError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }

        let title = L10n.Notifications.StatusError.title(account.displayName)
        if UIApplication.shared.applicationState == .active {
            showErrorBanner(title: title, body: error.localizedDescription)
        }
    }

    @objc func accountProfileError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }

        let title = L10n.Notifications.ProfileError.title(account.displayName)
        if UIApplication.shared.applicationState == .active {
            showErrorBanner(title: title, body: error.localizedDescription)
        }
    }

    @objc func accountLoginIpError(_ notification: Notification) {
        guard let ip = notification.userInfo?["ip"] as? String,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }

        let title = L10n.Notifications.LoginIpError.title(ip)
        if UIApplication.shared.applicationState == .active {
            showErrorBanner(title: title, body: error.localizedDescription)
        }
    }

    @objc func accountLogoutSessionError(_ notification: Notification) {
        guard let session = notification.userInfo?["session"] as? Session,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }

        let title = L10n.Notifications.LogoutSessionError.title(session.device?.nonEmpty ?? session.ip)
        if UIApplication.shared.applicationState == .active {
            showErrorBanner(title: title, body: error.localizedDescription)
        }
    }

    @objc func accountHistoryError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }

        let title = L10n.Notifications.HistoryError.title(account.displayName)
        if UIApplication.shared.applicationState == .active {
            showErrorBanner(title: title, body: error.localizedDescription)
        }
    }

    @objc func accountUsageAlert(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let usage = notification.userInfo?["usage"] as? Int64,
              let maxUsage = notification.userInfo?["maxUsage"] as? Int64 else {
            return
        }

        let percentage = Int((Double(usage) / Double(maxUsage)) * 100.0)
        let usageLeft = (maxUsage - usage).usageString(decimalUnits: account.configuration.decimalUnits)
        let name = account.displayName

        let title = L10n.Notifications.UsageAlert.title(name, percentage)
        let body = L10n.Notifications.UsageAlert.body(usageLeft)
        sendNotification(title: title, body: body, identifier: "\(account.identifier).accountUsageAlert",
                         categoryIdentifier: "usageAlert", userInfo: ["account": account.identifier],
                         summaryArgument: L10n.quoted(name))

        Analytics.logEvent("usage_alert", parameters: [
            "usage": usage,
            "max_usage": maxUsage])
    }

    func addObservers() {
        let selectors: [(Notification.Name, Selector)] = [
            (.accountLoginError, #selector(accountLoginError(_:))),
            (.accountLogoutError, #selector(accountLogoutError(_:))),
            (.accountStatusError, #selector(accountStatusError(_:))),
            (.accountProfileError, #selector(accountProfileError(_:))),
            (.accountLoginIpError, #selector(accountLoginIpError(_:))),
            (.accountLogoutSessionError, #selector(accountLogoutSessionError(_:))),
            (.accountHistoryError, #selector(accountHistoryError(_:))),
            (.accountUsageAlert, #selector(accountUsageAlert(_:)))
        ]

        for (name, selector) in selectors {
            NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
        }
    }
}


func showSuccessBanner(title: String?, body: String? = nil, duration: Double = AppDelegate.bannerDuration) {
    let banner = Banner(title: title, subtitle: body, backgroundColor: #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1))
    banner.show(duration: duration)
}

func showErrorBanner(title: String?, body: String? = nil, duration: Double = AppDelegate.bannerDuration) {
    let banner = Banner(title: title, subtitle: body, backgroundColor: #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1))
    banner.show(duration: duration)
}

func sendNotification(title: String, body: String, identifier: String, badge: Int? = nil,
                      categoryIdentifier: String? = nil, userInfo: [AnyHashable: Any]? = nil,
                      summaryArgument: String? = nil) {
    var userInfo = userInfo ?? [:]
    userInfo["identifier"] = identifier

    if #available(iOS 10.0, *) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = badge as NSNumber?
        if let categoryIdentifier = categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }
        content.userInfo = userInfo
        if #available(iOS 12.0, *) {
            if let summaryArgument = summaryArgument {
                content.summaryArgument = summaryArgument
            }
        }

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    } else {
        // Fallback on earlier versions
        let notification = UILocalNotification()
        notification.alertTitle = title
        notification.alertBody = body
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.applicationIconBadgeNumber = badge ?? 0
        notification.userInfo = userInfo

        UIApplication.shared.presentLocalNotificationNow(notification)
    }
}
