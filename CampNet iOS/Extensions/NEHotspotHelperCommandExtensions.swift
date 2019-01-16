//
//  NEHotspotHelperCommandExtensions.swift
//  CampNetKit
//
//  Created by Thomas Lee on 2017/10/12.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import NetworkExtension

import Firebase
import PromiseKit

import CampNetKit

extension NEHotspotHelperCommand {

    public func filterScanList() {
        guard let networkList = networkList else {
            let response = createResponse(.success)
            response.deliver()
            return
        }
        log.info("NEHotspotHelper: Received filterScanList command: \(networkList).")

        var knownList: [NEHotspotNetwork] = []
        for network in networkList {
            if let account = Account.delegate(for: network) {
                log.info("NEHotspotHelper: \(account) can handle \(network).")
                network.setConfidence(.low)
                knownList.append(network)
            }
        }

        replyFilterScanList(knownList: knownList)
    }

    public func evaluate(on queue: DispatchQueue, requestBinder: @escaping RequestBinder) {
        guard let network = network else {
            return
        }
        log.info("NEHotspotHelper: Received evaluate command: \(network).")

        guard let account = Account.delegate(for: network) else {
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
        guard let network = network else {
            return
        }
        log.info("NEHotspotHelper: Received authenticate command: \(network).")

        guard let account = Account.delegate(for: network) else {
            reply(result: .unsupportedNetwork)
            return
        }

        account.login(on: queue, requestBinder: requestBinder).done(on: queue) {
            self.reply(result: .success)
            Analytics.logEvent("background_login", parameters: ["account": account.identifier, "result": "success"])

            // Request for a donation if suitable.
            Defaults[.loginCount] += 1
            Analytics.setUserProperty(Defaults[.loginCount].description, forName: "login_count")
            if Defaults.potentialDonator && Defaults[.loginCount] % AppDelegate.donateRequestInterval == 0 {
                sendNotification(title: L10n.Notifications.DonationRequest.title,
                                 body: L10n.Notifications.DonationRequest.body(Defaults[.loginCount]),
                                 identifier: AppDelegate.donationRequestIdentifier,
                                 badge: 1)
                Analytics.logEvent("donation_request", parameters: ["login_count": Defaults[.loginCount]])
            }
        }
        .catch(on: queue) { error in
            self.reply(result: .temporaryFailure)
            Analytics.logEvent("background_login", parameters: ["account": account.identifier, "result": "temporary_failure"])
        }
    }

    public func maintain(on queue: DispatchQueue, requestBinder: @escaping RequestBinder) {
        guard let network = network else {
            return
        }
        log.info("NEHotspotHelper: Received maintain command: \(network).")

        guard let account = Account.delegate(for: network) else {
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
        guard let network = network else {
            return
        }
        log.info("NEHotspotHelper: Received logoff command: \(network).")

        guard let account = Account.delegate(for: network) else {
            reply(result: .failure)
            return
        }

        account.logout(on: queue, requestBinder: requestBinder).done(on: queue) {
            self.reply(result: .success)
            Analytics.logEvent("background_logout", parameters: ["account": account.identifier, "result": "success"])
        }
        .catch(on: queue) { error in
            self.reply(result: .failure)
            Analytics.logEvent("background_logout", parameters: ["account": account.identifier, "result": "failure"])
        }
    }

    private func replyFilterScanList(knownList: [NEHotspotNetwork]) {
        log.info("NEHotspotHelper: Replying known networks: \(knownList).")

        let response = createResponse(.success)
        response.setNetworkList(knownList)
        response.deliver()
    }

    private func replyEvaluate(confidence: NEHotspotHelperConfidence) {
        guard let network = network else {
            return
        }
        log.info("NEHotspotHelper: Replying confidence: \(confidence).")

        network.setConfidence(confidence)
        let response = createResponse(.success)
        response.setNetwork(network)
        response.deliver()
    }

    private func reply(result: NEHotspotHelperResult) {
        log.info("NEHotspotHelper: Replying result: \(result).")
        createResponse(result).deliver()
    }
}
