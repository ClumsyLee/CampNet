//
//  AppDelegate.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/17.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import NetworkExtension
import UIKit
import UserNotifications

import BRYXBanner
import Instabug
import SwiftyBeaver
import SwiftRater

import CampNetKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    static let bannerDuration = 3.0
    static let loginErrorNotificationInterval: TimeInterval = 86400

    var window: UIWindow?
    var logFileURL: URL? = nil

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        setDefaultsIfNot()  // Do it first to ensure that the defaults can be read in the following setups.
        
        setUpInstaBug()
        setUpSwiftyBeaver()
        setUpSwiftRater()
        setUpCampNet()

        // Do not request notification authorization when UI testing to prevent that system dialog from appearing.
        #if DEBUG
        #else
            requestNotificationAuthorization()
        #endif

        addObservers()
        registerHotspotHelper(displayName: L10n.HotspotHelper.displayName)

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
    }
    
    func setUpInstaBug() {
        Instabug.start(withToken: "0df1051f1ad636fc8efd87baef010aaa", invocationEvent: .none)
        Instabug.setPromptOptionsEnabledWithBug(false, feedback: true, chat: false)
        Instabug.setAttachmentTypesEnabledScreenShot(false, extraScreenShot: false, galleryImage: false,
                                                     voiceNote: false, screenRecording: false)
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
        
        if Defaults[.sendLogs] {
            let cloud = SBPlatformDestination(appID: "NxnNNO", appSecret: "7tqeijmBtx2ytbwuBMspzilcow0oPwr1",
                                              encryptionKey: "jJsbg9pj9j5u7hQDhwymWqcv2AaaoumP")
            cloud.serverURL = URL(string: "https://swiftybeaver.campnet.io/api/entries/")
            cloud.minLevel = .info
            log.addDestination(cloud)
        }
    }
    
    func setUpSwiftRater() {
        SwiftRater.appId = "1263284287"
        SwiftRater.daysUntilPrompt = 7
        SwiftRater.significantUsesUntilPrompt = 3
        SwiftRater.daysBeforeReminding = 1
    }
    
    func setUpCampNet() {
        Action.networkActivityIndicatorHandler = {
            value in UIApplication.shared.isNetworkActivityIndicatorVisible = value
        }
    }
    
    func requestNotificationAuthorization() {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                if granted {
                    log.info("User notifications are allowed.")
                } else {
                    log.warning("User notifications are not allowed: \(error.debugDescription).")
                }
            }
        } else {
            // Fallback on earlier versions
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound],
                                                                                             categories: nil))
        }

    }

    func registerHotspotHelper(displayName: String) {
        let options = [kNEHotspotHelperOptionDisplayName: displayName as NSObject]
        let queue = DispatchQueue.global(qos: .utility)

        let result = NEHotspotHelper.register(options: options, queue: queue, handler: Account.handler)
        
        if result {
            log.info("HotspotHelper registered.")
        } else {
            log.error("Unable to register HotspotHelper.")
        }
    }
    
    func showErrorBanner(title: String?, body: String?, duration: Double = AppDelegate.bannerDuration) {
        let banner = Banner(title: title, subtitle: body, backgroundColor: #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1))
        banner.show(duration: duration)
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        showErrorBanner(title: notification.alertTitle, body: notification.alertBody)
    }
    
    func sendNotification(title: String, body: String, identifier: String) {
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = UNNotificationSound.default()
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else {
            // Fallback on earlier versions
            let notification = UILocalNotification()
            notification.alertTitle = title
            notification.alertBody = body
            notification.soundName = UILocalNotificationDefaultSoundName
            
            UIApplication.shared.presentLocalNotificationNow(notification)
        }
    }
    
    @objc func accountLoginError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = L10n.Notifications.LoginError.title(account.username)
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
                                     identifier: "\(account.identifier).accountLoginError")
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
        
        let title = L10n.Notifications.LogoutError.title(account.username)
        showErrorBanner(title: title, body: error.localizedDescription)
    }
    
    @objc func accountStatusError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = L10n.Notifications.StatusError.title(account.username)
        showErrorBanner(title: title, body: error.localizedDescription)
    }
    
    @objc func accountProfileError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = L10n.Notifications.ProfileError.title(account.username)
        showErrorBanner(title: title, body: error.localizedDescription)
    }
    
    @objc func accountLoginIpError(_ notification: Notification) {
        guard let ip = notification.userInfo?["ip"] as? String,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = L10n.Notifications.LoginIpError.title(ip)
        showErrorBanner(title: title, body: error.localizedDescription)
    }
    
    @objc func accountLogoutSessionError(_ notification: Notification) {
        guard let session = notification.userInfo?["session"] as? Session,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = L10n.Notifications.LogoutSessionError.title(session.device?.nonEmpty ?? session.ip)
        showErrorBanner(title: title, body: error.localizedDescription)
    }
    
    @objc func accountHistoryError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = L10n.Notifications.HistoryError.title(account.username)
        showErrorBanner(title: title, body: error.localizedDescription)
    }
    
    @objc func accountUsageAlert(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let usage = notification.userInfo?["usage"] as? Int64,
              let maxUsage = notification.userInfo?["maxUsage"] as? Int64 else {
            return
        }
        
        let percentage = Int((Double(usage) / Double(maxUsage)) * 100.0)
        let usageLeft = (maxUsage - usage).usageString(decimalUnits: account.configuration.decimalUnits)
        
        let title = L10n.Notifications.UsageAlert.title(account.username, percentage)
        let body = L10n.Notifications.UsageAlert.body(usageLeft)
        sendNotification(title: title, body: body, identifier: "\(account.identifier).accountUsageAlert")
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
