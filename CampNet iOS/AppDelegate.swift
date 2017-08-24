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

let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    static let bannerDuration = 3.0

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        setDefaultsIfNot()
        
        setUpInstaBug()
        setUpSwiftyBeaver()
        setUpSwiftRater()
        
        requestNotificationAuthorization()
        addObservers()
        
        registerHotspotHelper(displayName: NSLocalizedString("Campus network managed by CampNet", comment: "Display name of the HotspotHelper"))

        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func setDefaultsIfNot() {
        if !Defaults[.defaultsSet] {
            Defaults[.autoLogin] = true
            Defaults[.autoLogoutExpiredSessions] = true
            Defaults[.usageAlertRatio] = 0.90
            
            Defaults[.defaultsSet] = true
        }
    }
    
    func setUpInstaBug() {
        Instabug.start(withToken: "0df1051f1ad636fc8efd87baef010aaa", invocationEvent: .none)
        Instabug.setPromptOptionsEnabledWithBug(false, feedback: true, chat: false)
        Instabug.setAttachmentTypesEnabledScreenShot(false, extraScreenShot: false, galleryImage: false, voiceNote: false, screenRecording: false)
    }
    
    func setUpSwiftyBeaver() {
        let console = ConsoleDestination()
        let file = FileDestination()
        let cloud = SBPlatformDestination(appID: "NxnNNO", appSecret: "7tqeijmBtx2ytbwuBMspzilcow0oPwr1", encryptionKey: "jJsbg9pj9j5u7hQDhwymWqcv2AaaoumP")
        cloud.serverURL = URL(string: "https://swiftybeaver.campnet.io/api/entries/")
        
        log.addDestination(console)
        log.addDestination(file)
        log.addDestination(cloud)
    }
    
    func setUpSwiftRater() {
        SwiftRater.appId = "1263284287"
        SwiftRater.daysUntilPrompt = 7
        SwiftRater.significantUsesUntilPrompt = 3
        SwiftRater.daysBeforeReminding = 1
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
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound], categories: nil))
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
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        if notification.request.identifier.hasSuffix(".accountUsageAlert") {
            completionHandler([.alert, .sound])
        } else {
            let content = notification.request.content
            showErrorBanner(title: content.title, body: content.body)
            completionHandler([])
        }
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
    
    func accountLoginError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Login \"%@\"", comment: "Alert title when failed to login."), account.username)
        sendNotification(title: title, body: error.localizedDescription, identifier: "\(account.identifier).accountLoginError")
    }
    
    func accountLogoutError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Logout \"%@\"", comment: "Alert title when failed to logout."), account.username)
        sendNotification(title: title, body: error.localizedDescription, identifier: "\(account.identifier).accountLogoutError")
    }
    
    func accountStatusError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Update Status of \"%@\"", comment: "Alert title when failed to update account status."), account.username)
        sendNotification(title: title, body: error.localizedDescription, identifier: "\(account.identifier).accountStatusError")
    }
    
    func accountProfileError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Update Profile of \"%@\"", comment: "Alert title when failed to update account profile."), account.username)
        sendNotification(title: title, body: error.localizedDescription, identifier: "\(account.identifier).accountProfileError")
    }
    
    func accountLoginIpError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let ip = notification.userInfo?["ip"] as? String,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Login %@", comment: "Alert title when failed to login IP."), ip)
        sendNotification(title: title, body: error.localizedDescription, identifier: "\(account.identifier).accountLoginIpError")
    }
    
    func accountLogoutSessionError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let session = notification.userInfo?["session"] as? Session,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Logout \"%@\"", comment: "Alert title when failed to logout a session."), session.device ?? session.ip)
        sendNotification(title: title, body: error.localizedDescription, identifier: "\(account.identifier).accountLogoutSessionError")
    }
    
    func accountHistoryError(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let error = notification.userInfo?["error"] as? CampNetError else {
            return
        }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("Unable to Update History of \"%@\"", comment: "Alert title when failed to update account history."), account.username)
        sendNotification(title: title, body: error.localizedDescription, identifier: "\(account.identifier).accountHistoryError")
    }
    
    func accountUsageAlert(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let usage = notification.userInfo?["usage"] as? Int64,
              let maxUsage = notification.userInfo?["maxUsage"] as? Int64 else {
            return
        }
        
        let percentage = Int((Double(usage) / Double(maxUsage)) * 100.0)
        let usageLeft = (maxUsage - usage).usageString(decimalUnits: account.configuration.decimalUnits)
        
        let title = String.localizedStringWithFormat(NSLocalizedString("\"%@\" has used %d%% of maximum usage", comment: "Usage alert title."), account.username, percentage)
        let body = String.localizedStringWithFormat(NSLocalizedString("Up to %@ can still be used this month.", comment: "Usage alert body."), usageLeft)
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

