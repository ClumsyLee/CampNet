//
//  SwiftRater.swift
//  SwiftRater
//
//  Created by Fujiki Takeshi on 2017/03/28.
//  Copyright © 2017年 com.takecian. All rights reserved.
//

import UIKit
import StoreKit

@objc public class SwiftRater: NSObject {

    enum ButtonIndex: Int {
        case cancel = 0
        case rate = 1
        case later = 2
    }

    public let SwiftRaterErrorDomain = "Siren Error Domain"

    public static var daysUntilPrompt: Int {
        get {
            return UsageDataManager.shared.daysUntilPrompt
        }
        set {
            UsageDataManager.shared.daysUntilPrompt = newValue
        }
    }
    public static var usesUntilPrompt: Int {
        get {
            return UsageDataManager.shared.usesUntilPrompt
        }
        set {
            UsageDataManager.shared.usesUntilPrompt = newValue
        }
    }
    public static var significantUsesUntilPrompt: Int {
        get {
            return UsageDataManager.shared.significantUsesUntilPrompt
        }
        set {
            UsageDataManager.shared.significantUsesUntilPrompt = newValue
        }
    }

    public static var daysBeforeReminding: Int {
        get {
            return UsageDataManager.shared.daysBeforeReminding
        }
        set {
            UsageDataManager.shared.daysBeforeReminding = newValue
        }
    }
    public static var debugMode: Bool {
        get {
            return UsageDataManager.shared.debugMode
        }
        set {
            UsageDataManager.shared.debugMode = newValue
        }
    }

    public static var useStoreKitIfAvailable: Bool = true

    public static var showLaterButton: Bool = true

    public static var alertTitle: String?
    public static var alertMessage: String?
    public static var alertCancelTitle: String?
    public static var alertRateTitle: String?
    public static var alertRateLaterTitle: String?
    public static var appName: String?

    public static var showLog: Bool = false
    public static var resetWhenAppUpdated: Bool = true

    public static var shared = SwiftRater()

    public static var appId: String?

    private static var appVersion: String {
        get {
            return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "0.0.0"
        }
    }

    private var titleText: String {
        return SwiftRater.alertTitle ?? String.init(format: localize("Rate %@"), mainAppName)
    }

    private var messageText: String {
        return SwiftRater.alertMessage ?? String.init(format: localize("Rater.title"), mainAppName)
    }

    private var rateText: String {
        return SwiftRater.alertRateTitle ?? String.init(format: localize("Rate %@"), mainAppName)
    }

    private var cancelText: String {
        return SwiftRater.alertCancelTitle ?? String.init(format: localize("No, Thanks"), mainAppName)
    }

    private var laterText: String {
        return SwiftRater.alertRateLaterTitle ?? String.init(format: localize("Remind me later"), mainAppName)
    }

    private func localize(_ key: String) -> String {
        return NSLocalizedString(key, tableName: "SwiftRaterLocalization", bundle: Bundle(for: SwiftRater.self), comment: "")
    }

    private var mainAppName: String {
        if let name = SwiftRater.appName {
            return name
        }
        if let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return name
        } else if let name = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            return name
        } else {
            return "App"
        }
    }

    private override init() {
        super.init()
        
        if SwiftRater.resetWhenAppUpdated && SwiftRater.appVersion != UsageDataManager.shared.trackingVersion {
            UsageDataManager.shared.reset()
            UsageDataManager.shared.trackingVersion = SwiftRater.appVersion
        }
        incrementUsageCount()
    }

    public static func incrementSignificantUsageCount() {
        UsageDataManager.shared.incrementSignificantUseCount()
    }

    public static func check() {
        if UsageDataManager.shared.ratingConditionsHaveBeenMet {
            SwiftRater.shared.showRatingAlert()
        }
    }
    
    public static func rateApp() {
        SwiftRater.shared.rateAppWithAppStore()
        UsageDataManager.shared.isRateDone = true
    }

    public static func reset() {
        UsageDataManager.shared.reset()
    }

    private func incrementUsageCount() {
        UsageDataManager.shared.incrementUseCount()
    }

    private func incrementSignificantUseCount() {
        UsageDataManager.shared.incrementSignificantUseCount()
    }

    private func showRatingAlert() {
        NSLog("[SwiftRater] Trying to show review request dialog.")
        if #available(iOS 10.3, *), SwiftRater.useStoreKitIfAvailable {
            SKStoreReviewController.requestReview()
            UsageDataManager.shared.isRateDone = true
        } else {
            let alertController = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert)
            
            let rateAction = UIAlertAction(title: rateText, style: .default, handler: {
                [unowned self] action -> Void in
                self.rateAppWithAppStore()
                UsageDataManager.shared.isRateDone = true
            })
            alertController.addAction(rateAction)
            
            if SwiftRater.showLaterButton {
                alertController.addAction(UIAlertAction(title: laterText, style: .default, handler: {
                    action -> Void in
                    UsageDataManager.shared.saveReminderRequestDate()
                }))
            }
            
            alertController.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: {
                action -> Void in
                UsageDataManager.shared.isRateDone = true
            }))
            
            if #available(iOS 9.0, *) {
                alertController.preferredAction = rateAction
            }
            
            UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func rateAppWithAppStore() {
        #if arch(i386) || arch(x86_64)
            print("APPIRATER NOTE: iTunes App Store is not supported on the iOS simulator. Unable to open App Store page.");
        #else
            guard let appId = SwiftRater.appId,
                  let url = URL(string: "https://itunes.apple.com/app/id\(appId)?action=write-review") else {
                    return
            }
            
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        #endif
    }
}
