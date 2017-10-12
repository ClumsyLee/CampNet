//
//  NEHotspotHelperCommandExtensions.swift
//  CampNetKit
//
//  Created by Thomas Lee on 2017/10/12.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import NetworkExtension

extension NEHotspotHelperCommand {

    public func filterScanList() {
        let main = Account.main
        let accountId = main?.description ?? "nil"
        log.info("\(accountId): Received filterScanList ")

        guard let networkList = networkList, let account = main else {
            let response = createResponse(.success)
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

        let response = createResponse(.success)
        response.setNetworkList(knownList)
        response.deliver()
    }

    public func evaluate(on queue: DispatchQueue, requestBinder: @escaping RequestBinder) {
        let main = Account.main
        let accountId = main?.description ?? "nil"
        guard let network = network else {
            return
        }
        log.info("\(accountId): Received evaluate command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            log.info("\(accountId): Cannot manage \(network).")

            network.setConfidence(.none)
            let response = createResponse(.success)
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

            let response = self.createResponse(.success)
            response.setNetwork(network)
            response.deliver()
        }
        .catch(on: queue) { _ in
            log.info("\(accountId): Can possibly manage \(network).")
            network.setConfidence(.low)

            let response = self.createResponse(.success)
            response.setNetwork(network)
            response.deliver()
        }
    }

    public func authenticate(on queue: DispatchQueue, requestBinder: @escaping RequestBinder) {
        let main = Account.main
        let accountId = main?.description ?? "nil"
        guard let network = network else {
            return
        }
        log.info("\(accountId): Received authenticate command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            log.warning("\(accountId): Cannot manage \(network).")
            createResponse(.unsupportedNetwork).deliver()
            return
        }

        account.login(on: queue, requestBinder: requestBinder).then(on: queue) { () -> Void in
            log.info("\(accountId): Logged in on \(network).")
            self.createResponse(.success).deliver()
        }
        .catch(on: queue) { error in
            log.warning("\(accountId): Failed to login on \(network): \(error)")
            self.createResponse(.temporaryFailure).deliver()
        }

    }

    public func maintain(on queue: DispatchQueue, requestBinder: @escaping RequestBinder) {
        let main = Account.main
        let accountId = main?.description ?? "nil"
        guard let network = network else {
            return
        }
        log.info("\(accountId): Received maintain command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            log.warning("\(accountId): Cannot manage \(network).")
            createResponse(.failure).deliver()
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
                    self.createResponse(result).deliver()
                }
            } else {
                self.createResponse(result).deliver()
            }
        }
        .catch(on: queue) { error in
            log.warning("\(accountId): Failed to maintain on \(network): \(error)")
            self.createResponse(.failure).deliver()
        }
    }

    public func logoff(on queue: DispatchQueue, requestBinder: @escaping RequestBinder) {
        let main = Account.main
        let accountId = main?.description ?? "nil"
        guard let network = network else {
            return
        }
        log.info("\(accountId): Received logoff command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            log.warning("\(accountId): Cannot manage \(network).")
            createResponse(.failure).deliver()
            return
        }

        account.logout(on: queue, requestBinder: requestBinder).then(on: queue) { _ -> Void in
            log.info("\(accountId): Logged out on \(network).")
            self.createResponse(.success).deliver()
        }
        .catch(on: queue) { error in
            log.warning("\(accountId): Failed to logout on \(network): \(error)")
            self.createResponse(.failure).deliver()
        }
    }
}

