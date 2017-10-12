//
//  HotspotHelper.swift
//  CampNetKit
//
//  Created by Thomas Lee on 2017/10/12.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import NetworkExtension

extension NEHotspotHelper {
    public class func register(displayName: String) {
        let options = [kNEHotspotHelperOptionDisplayName: displayName as NSObject]
        let queue = DispatchQueue.global(qos: .utility)

        let result = NEHotspotHelper.register(options: options, queue: queue) { command in
            let queue = DispatchQueue.global(qos: .utility)
            let requestBinder: RequestBinder = { $0.bind(to: command) }

            switch command.commandType {
            case .filterScanList: filterScanList(command: command)
            case .evaluate: evaluate(command: command, on: queue, requestBinder: requestBinder)
            case .authenticate: authenticate(command: command, on: queue, requestBinder: requestBinder)
            case .maintain: maintain(command: command, on: queue, requestBinder: requestBinder)
            case .logoff: logoff(command: command, on: queue, requestBinder: requestBinder)
            default: break
            }
        }

        if result {
            log.info("HotspotHelper registered.")
        } else {
            log.error("Unable to register HotspotHelper.")
        }
    }

    private class func filterScanList(command: NEHotspotHelperCommand) {
        let main = Account.main
        let accountId = main?.description ?? "nil"
        log.info("\(accountId): Received filterScanList command.")

        guard let networkList = command.networkList, let account = main else {
            let response = command.createResponse(.success)
            response.deliver()
            return
        }

        var knownList: [NEHotspotNetwork] = []
        for network in networkList {
            if account.canManage(network: network) {
                network.setConfidence(.low)
                knownList.append(network)
            }
        }
        log.info("\(accountId): Known networks: \(knownList).")

        let response = command.createResponse(.success)
        response.setNetworkList(knownList)
        response.deliver()
    }

    private class func evaluate(command: NEHotspotHelperCommand, on queue: DispatchQueue,
                                 requestBinder: @escaping RequestBinder) {
        let main = Account.main
        let accountId = main?.description ?? "nil"
        guard let network = command.network else {
            return
        }
        log.info("\(accountId): Received evaluate command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            log.info("\(accountId): Cannot manage \(network).")

            network.setConfidence(.none)
            let response = command.createResponse(.success)
            response.setNetwork(network)
            response.deliver()
            return
        }

        account.status(on: queue, requestBinder: requestBinder).then(on: queue) { status -> Void in
            switch status.type {
            case .online, .offline:
                log.info("\(accountId): Can manage \(network).")
                network.setConfidence(.high)
            case .offcampus:
                log.info("\(accountId): Cannot manage \(network).")
                network.setConfidence(.none)
            }

            let response = command.createResponse(.success)
            response.setNetwork(network)
            response.deliver()
        }
        .catch(on: queue) { _ in
            log.info("\(accountId): Can possibly manage \(network).")
            network.setConfidence(.low)

            let response = command.createResponse(.success)
            response.setNetwork(network)
            response.deliver()
        }
    }

    private class func authenticate(command: NEHotspotHelperCommand, on queue: DispatchQueue,
                                     requestBinder: @escaping RequestBinder) {
        let main = Account.main
        let accountId = main?.description ?? "nil"
        guard let network = command.network else {
            return
        }
        log.info("\(accountId): Received authenticate command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            log.warning("\(accountId): Cannot manage \(network).")
            command.createResponse(.unsupportedNetwork).deliver()
            return
        }

        account.login(on: queue, requestBinder: requestBinder).then(on: queue) { () -> Void in
            log.info("\(accountId): Logged in on \(network).")
            command.createResponse(.success).deliver()
        }
        .catch(on: queue) { error in
            log.warning("\(accountId): Failed to login on \(network): \(error)")
            command.createResponse(.temporaryFailure).deliver()
        }

    }

    private class func maintain(command: NEHotspotHelperCommand, on queue: DispatchQueue,
                                 requestBinder: @escaping RequestBinder) {
        let main = Account.main
        let accountId = main?.description ?? "nil"
        guard let network = command.network else {
            return
        }
        log.info("\(accountId): Received maintain command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            log.warning("\(accountId): Cannot manage \(network).")
            command.createResponse(.failure).deliver()
            return
        }

        account.status(on: queue, requestBinder: requestBinder).then(on: queue) { status -> Void in
            let result: NEHotspotHelperResult

            switch status.type {
            case .online:
                log.info("\(accountId): Still online on \(network).")
                result = .success
            case .offline:
                log.info("\(accountId): Offline on \(network).")
                result = .authenticationRequired
            case .offcampus:
                log.warning("\(accountId): Cannot manage \(network).")
                result = .failure
            }

            if result == .success, account.shouldAutoUpdateProfile {
                account.update(skipStatus: true, on: queue, requestBinder: requestBinder).always(on: queue) {
                    command.createResponse(result).deliver()
                }
            } else {
                command.createResponse(result).deliver()
            }
        }
        .catch(on: queue) { error in
            log.warning("\(accountId): Failed to maintain on \(network): \(error)")
            command.createResponse(.failure).deliver()
        }
    }

    private class func logoff(command: NEHotspotHelperCommand, on queue: DispatchQueue,
                               requestBinder: @escaping RequestBinder) {
        let main = Account.main
        let accountId = main?.description ?? "nil"
        guard let network = command.network else {
            return
        }
        log.info("\(accountId): Received logoff command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            log.warning("\(accountId): Cannot manage \(network).")
            command.createResponse(.failure).deliver()
            return
        }

        account.logout(on: queue, requestBinder: requestBinder).then(on: queue) { _ -> Void in
            log.info("\(accountId): Logged out on \(network).")
            command.createResponse(.success).deliver()
        }
        .catch(on: queue) { error in
            log.warning("\(accountId): Failed to logout on \(network): \(error)")
            command.createResponse(.failure).deliver()
        }
    }
}
