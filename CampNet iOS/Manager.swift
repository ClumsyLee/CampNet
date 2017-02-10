//
//  Manager.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/29.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import NetworkExtension
//
//class Manager {
//    static let shared = Manager()
//    
//    var configuration: Configuration
//}

//
//    static let shared = Manager()
//    
//    var account: Account?
//
//    var session: URLSession
//    var timeoutIntervalForRequest = 30.0
//    var userDefaultKeyAccount = "account"
//    
//    var webView: UIWebView? = nil
//
//    func register() -> Bool {
//        print("Registering manager.")
//
//        let options = [kNEHotspotHelperOptionDisplayName: "Campus network handled by CampNet" as NSObject]
//        let queue = DispatchQueue(label: Bundle.main.bundleIdentifier!, attributes: .concurrent)
//
//        let result = NEHotspotHelper.register(options: options, queue: queue) { (command) in
//            let requestBinder = { (request: NSMutableURLRequest) -> Void in request.bind(to: command) }
//
//            switch command.commandType {
//            case .filterScanList:
//                guard let networkList = command.networkList else {
//                    return
//                }
//                guard let account = self.account else {
//                    let response = command.createResponse(.success)
//                    response.setNetworkList([])
//                    response.deliver()
//                    return
//                }
//
//                var knownList: [NEHotspotNetwork] = []
//                for network in networkList {
//                    if account.canManage(network) {
//                        network.setConfidence(.low)
//                        network.setPassword("1L2S3H@wifi.com")
//                        knownList.append(network)
//                    }
//                }
//                print("Known networks: \(knownList).")
//                
//                let response = command.createResponse(.success)
//                response.setNetworkList(knownList)
//                response.deliver()
//
//            case .evaluate:
//                guard let network = command.network else {
//                    return
//                }
//                guard let account = self.account, account.canManage(network) else {
//                    network.setConfidence(.none)
//                    let response = command.createResponse(.success)
//                    response.setNetwork(network)
//                    response.deliver()
//                    return
//                }
//                
//                account.status(requestBinder: requestBinder, session: self.session) { result in
//                    switch result {
////                    case .online, .offline:
////                        network.setConfidence(.high)
//                    default:
//                        network.setConfidence(.high)
//                    }
//
//                    let response = command.createResponse(.success)
//                    response.setNetwork(network)
//                    response.deliver()
//                }
//                
//            case .authenticate:
//                guard let network = command.network else {
//                    return
//                }
//                guard let account = self.account, account.canManage(network) else {
//                    let response = command.createResponse(.unsupportedNetwork)
//                    response.deliver()
//                    return
//                }
//                
//                if let webView = self.webView {
//                    let url = URL(string: "http://www.ip138.com")!
//                    let request = NSMutableURLRequest(url: url)
//                    request.bind(to: command)
//                    //                    webView.load(request as URLRequest)
//                    webView.loadRequest(request as URLRequest)
//                }
//
//                account.login(requestBinder: requestBinder, session: self.session) { result in
//                    let response: NEHotspotHelperResponse
//                    switch result {
//                    case .online:
//                        response = command.createResponse(.success)
//                    case .unauthorized:
//                        response = command.createResponse(.temporaryFailure)
//                    case .arrears:
//                        response = command.createResponse(.failure)
//                    default:
//                        response = command.createResponse(.temporaryFailure)
//                    }
////                    response.deliver()
//
//                }
//                
//            case .maintain:
//                guard let network = command.network else {
//                    return
//                }
//                guard let account = self.account, account.canManage(network) else {
//                    let response = command.createResponse(.failure)
//                    response.deliver()
//                    return
//                }
//                
//                account.status(requestBinder: requestBinder, session: self.session) { result in
//                    let response: NEHotspotHelperResponse
//                    switch result {
//                    case .online:
//                        response = command.createResponse(.success)
//                    case .offline:
//                        response = command.createResponse(.authenticationRequired)
//                    default:
//                        response = command.createResponse(.failure)
//                    }
//                    response.deliver()
//                }
//
//            case .logoff:
//                guard let network = command.network else {
//                    return
//                }
//                guard let account = self.account, account.canManage(network) else {
//                    let response = command.createResponse(.failure)
//                    response.deliver()
//                    return
//                }
//                
//                account.logout(requestBinder: requestBinder, session: self.session) { result in
//                    let response: NEHotspotHelperResponse
//                    switch result {
//                    case .offline:
//                        response = command.createResponse(.success)
//                    default:
//                        response = command.createResponse(.failure)
//                    }
//                    response.deliver()
//                }
//
//            default:
//                print("Command \(command.commandType) is unsupported.")
//            }
//        }
//        
//        print("Manager registration result: \(result)")
//        return result
//    }
//
//    init() {
//        if let accountId = UserDefaults.standard.string(forKey: userDefaultKeyAccount) {
//            account = Account(identifier: accountId)
//        } else {
//            account = nil
//        }
//
//        let config = URLSessionConfiguration.default
//        config.allowsCellularAccess = false
//        config.timeoutIntervalForRequest = timeoutIntervalForRequest
//        session = URLSession(configuration: config)
//    }
//    
//    func save() {
//        UserDefaults.standard.set(account?.identifier, forKey: userDefaultKeyAccount)
//        print("\(account) saved.")
//    }
//}
