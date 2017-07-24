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

import CampNetKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    fileprivate let networkActivityQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).networkActivityQueue", qos: .userInitiated)
    fileprivate var networkActivityCounter: Int = 0
    
    func setNetworkActivityIndicatorVisible(_ value: Bool) {
        networkActivityQueue.async {
            self.networkActivityCounter += value ? 1 : -1
            UIApplication.shared.isNetworkActivityIndicatorVisible = self.networkActivityCounter > 0
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        requestNotificationAuthorization(options: [.alert, .sound])
        registerHotspotHelper(displayName: NSLocalizedString("Campus network managed by CampNet", comment: "Display name of the HotspotHelper"))

        return true
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
    
    func requestNotificationAuthorization(options: UNAuthorizationOptions) {
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
            if granted {
                print("User notifications are allowed.")
            } else {
                print("User notifications are not allowed. Error: \(error.debugDescription)")
            }
        }
    }

    func registerHotspotHelper(displayName: String) {
        let options = [kNEHotspotHelperOptionDisplayName: displayName as NSObject]
        let queue = DispatchQueue.global(qos: .utility)

        let result = NEHotspotHelper.register(options: options, queue: queue) { command in
            print("NEHotspotHelperCommand \(command.commandType) received.")
            
            let requestBinder: RequestBinder = { $0.bind(to: command) }
            
            switch command.commandType {
                
            case .filterScanList:
                guard let networkList = command.networkList,
                      let account = Account.main else {
                    let response = command.createResponse(.success)
                    response.deliver()
                    return
                }
                
                var knownList: [NEHotspotNetwork] = []
                for network in networkList {
                    if account.canManage(network) {
                        network.setConfidence(.low)
                        knownList.append(network)
                    }
                }
                print("Known networks: \(knownList).")
                
                let response = command.createResponse(.success)
                response.setNetworkList(knownList)
                response.deliver()
                
            case .evaluate:
                guard let network = command.network else {
                    return
                }
                guard let account = Account.main, account.canManage(network) else {
                    network.setConfidence(.none)
                    let response = command.createResponse(.success)
                    response.setNetwork(network)
                    response.deliver()
                    return
                }
                
                account.status(requestBinder: requestBinder).then { status -> Void in
                    switch status.type {
                    case .online, .offline:
                        network.setConfidence(.high)
                    case .offcampus:
                        network.setConfidence(.none)
                    }
                    
                    let response = command.createResponse(.success)
                    response.setNetwork(network)
                    response.deliver()
                }
                .catch { _ in
                    network.setConfidence(.low)
                    
                    let response = command.createResponse(.success)
                    response.setNetwork(network)
                    response.deliver()
                }
                
            case .authenticate:
                guard let network = command.network else {
                    return
                }
                guard let account = Account.main, account.canManage(network) else {
                    command.createResponse(.unsupportedNetwork).deliver()
                    return
                }
                
                account.login(requestBinder: requestBinder).then {
                    command.createResponse(.success).deliver()
                }
                .catch { _ in
                    command.createResponse(.temporaryFailure).deliver()
                }
                
            case .maintain:
                guard let network = command.network else {
                    return
                }
                guard let account = Account.main, account.canManage(network) else {
                    command.createResponse(.failure).deliver()
                    return
                }
                
                account.status(requestBinder: requestBinder).then { status -> Void in
                    let result: NEHotspotHelperResult
                    
                    switch status.type {
                    case .online: result = .success
                    case .offline: result = .authenticationRequired
                    case .offcampus: result = .failure
                    }
                    
                    command.createResponse(result).deliver()
                }
                .catch { _ in
                    command.createResponse(.failure).deliver()
                }
                
            case .logoff:
                guard let network = command.network else {
                    return
                }
                guard let account = Account.main, account.canManage(network) else {
                    command.createResponse(.failure).deliver()
                    return
                }
                
                account.logout(requestBinder: requestBinder).then {
                    command.createResponse(.success).deliver()
                }
                .catch { _ in
                    command.createResponse(.failure).deliver()
                }
                
            default: break
            }
        }
        
        if result {
            print("HotspotHelper registered.")
        } else {
            print("Unable to HotspotHelper registered.")
        }
    }
}

