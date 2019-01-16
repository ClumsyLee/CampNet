//
//  NEHotspotHelperCommandExtensions.swift
//  CampNetKit
//
//  Created by Thomas Lee on 2017/10/12.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import NetworkExtension

import PromiseKit

import CampNetKit

extension NEHotspotHelperCommand {

    public func filterScanList() {
        let main = Account.main
        log.info("\(main?.description ?? "nil"): Received filterScanList ")

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

        replyFilterScanList(knownList: knownList)
    }

    public func evaluate(on queue: DispatchQueue, requestBinder: @escaping RequestBinder) {
        let main = Account.main
        guard let network = network else {
            return
        }
        log.info("\(main?.description ?? "nil"): Received evaluate command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            replyEvaluate(confidence: .none)
            return
        }

        account.status(on: queue, requestBinder: requestBinder).done(on: queue) { status in
            switch status.type {
            case .online, .offline: self.replyEvaluate(confidence: .high)
            case .offcampus: self.replyEvaluate(confidence: .none)
            }
        }
        .catch(on: queue) { _ in
            self.replyEvaluate(confidence: .low)
        }
    }

    public func authenticate(on queue: DispatchQueue, requestBinder: @escaping RequestBinder) {
        let main = Account.main
        guard let network = network else {
            return
        }
        log.info("\(main?.description ?? "nil"): Received authenticate command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            reply(result: .unsupportedNetwork)
            return
        }

        account.login(on: queue, requestBinder: requestBinder).done(on: queue) {
            self.reply(result: .success)
        }
        .catch(on: queue) { error in
            self.reply(result: .temporaryFailure)
        }
    }

    public func maintain(on queue: DispatchQueue, requestBinder: @escaping RequestBinder) {
        let main = Account.main
        guard let network = network else {
            return
        }
        log.info("\(main?.description ?? "nil"): Received maintain command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            reply(result: .failure)
            return
        }

        account.status(on: queue, requestBinder: requestBinder).done(on: queue) { status in
            switch status.type {
            case .online: self.reply(result: .success)
            case .offline: self.reply(result: .authenticationRequired)
            case .offcampus: self.reply(result: .failure)
            }
        }
        .catch(on: queue) { error in
            self.reply(result: .failure)
        }
    }

    public func logoff(on queue: DispatchQueue, requestBinder: @escaping RequestBinder) {
        let main = Account.main
        guard let network = network else {
            return
        }
        log.info("\(main?.description ?? "nil"): Received logoff command for \(network).")

        guard let account = main, account.canManage(network: network) else {
            reply(result: .failure)
            return
        }

        account.logout(on: queue, requestBinder: requestBinder).done(on: queue) {
            self.reply(result: .success)
        }
        .catch(on: queue) { error in
            self.reply(result: .failure)
        }
    }

    private func replyFilterScanList(knownList: [NEHotspotNetwork]) {
        log.info("Replying known networks: \(knownList).")

        let response = createResponse(.success)
        response.setNetworkList(knownList)
        response.deliver()
    }

    private func replyEvaluate(confidence: NEHotspotHelperConfidence) {
        guard let network = network else {
            return
        }
        log.info("Replying confidence: \(confidence).")

        network.setConfidence(confidence)
        let response = createResponse(.success)
        response.setNetwork(network)
        response.deliver()
    }

    private func reply(result: NEHotspotHelperResult) {
        log.info("Replying result: \(result).")
        createResponse(result).deliver()
    }
}
