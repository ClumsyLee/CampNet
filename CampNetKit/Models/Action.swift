//
//  Action.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/10.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import Foundation
import JavaScriptCore

import Alamofire
import CryptoSwift
import Kanna
import PromiseKit
import Yaml

public typealias RequestBinder = (NSMutableURLRequest) -> Void

public struct ActionEntry {
    static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_0 like Mac OS X) AppleWebKit/602.1.38 (KHTML, " +
                           "like Gecko) Version/10.0 Mobile/14A300 Safari/602.1"
    static let timeout = 30.0
    static let varsName = "vars"
    static let newVarsName = "newVars"
    static let respName = "resp"

    public var actionIdentifier: String
    public var index: Int
    public var identifier: String

    public var method: String
    public var url: String
    public var params: [String: String]
    public var headers: [String: String]
    public var body: String?

    public var vars: [String: String]
    public var offcampusIfFailed: Bool
    public var script: String

    init?(actionIdentifier: String, index: Int, yaml: Yaml) {
        let identifier = "\(actionIdentifier)[\(index)]"
        self.actionIdentifier = actionIdentifier
        self.index = index
        self.identifier = identifier

        self.method = yaml["method"].string ?? "GET"
        self.url = yaml["url"].string ?? ""
        self.params = yaml["params"].stringDictionary ?? [:]
        self.headers = yaml["headers"].stringDictionary ?? [:]
        self.body = yaml["body"].string

        self.vars = yaml["vars"].stringDictionary ?? [:]
        self.offcampusIfFailed = yaml["offcampus_if_failed"].bool ?? false
        self.script = yaml["script"].string ?? ""
    }

    func commit(currentVars: [String: Any] = [:],
                context: JSContext,
                session: URLSession,
                on queue: DispatchQueue,
                requestBinder: RequestBinder? = nil) -> Promise<[String: Any]> {
        log.verbose("\(self): Commiting.")

        // Load placeholders from vars.
        var placeholders: [String: String] = [:]
        for (key, value) in currentVars {
            if let value = value as? String {
                placeholders[key] = value
            } else if let value = value as? Int {
                placeholders[key] = String(value)
            }
        }

        // Handle script-only actions.
        if url.isEmpty {
            return Promise().map(on: queue) { _ -> [String: Any] in
                try self.runScript(context: context)
                return try self.getResults(context: context)
            }
        }

        // Build request.
        guard let request = buildRequest(placeholders: placeholders, requestBinder: requestBinder) else {
            return Promise(error: CampNetError.invalidConfiguration)
        }

        return session.dataTask(.promise, with: request).compactMap(String.init).recover(on: queue) { error -> Promise<String> in
            throw self.offcampusIfFailed ? CampNetError.offcampus : CampNetError.networkError
        }
        .map(on: queue) { resp in
            log.verbose("\(self): Processing response.")

            let newVars = try self.captureNewVars(resp: resp)                   // Capture new vars from HTML if needed.
            try self.runScript(context: context, resp: resp ,newVars: newVars)  // Invoke script.
            let results = try self.getResults(context: context)                 // Get results.

            return results
        }
    }

    func buildRequest(placeholders: [String: String] = [:], requestBinder: RequestBinder?) -> URLRequest? {
        // Prepare arguments.
        let urlString = url.replace(with: placeholders)
        guard let url = URL(string: urlString) else {
            log.error("\(self): Failed to convert \(urlString.debugDescription) to URL.")
            return nil
        }

        var params: [String: String] = [:]
        for (key, value) in self.params {
            params[key.replace(with: placeholders)] = value.replace(with: placeholders)
        }

        // Bind.
        let oldRequest = NSMutableURLRequest(url: url)  // The binding API is only available to NSMutableURLRequest now.
        if let requestBinder = requestBinder {
            requestBinder(oldRequest)
        }
        var request = oldRequest as URLRequest

        // Build request.
        request.httpMethod = method
        do {
            request = try URLEncoding.methodDependent.encode(request, with: params)
        } catch let error {
            log.error("\(self): Failed to add \(params) to the request: \(error)")
            return nil
        }
        // Headers.
        request.setValue(ActionEntry.userAgent, forHTTPHeaderField: "User-Agent")
        for (key, value) in headers {
            request.setValue(value.replace(with: placeholders), forHTTPHeaderField: key.replace(with: placeholders))
        }
        // Body.
        if let body = body {
            request.httpBody = Data(body.utf8)
        }

        return request
    }

    func captureNewVars(resp: String) throws -> [String: Any] {
        if self.vars.isEmpty {
            return [:]  // Don't parse HTML if there is nothing to capture.
        }

        guard let doc = try? HTML(html: resp, encoding: String.Encoding.utf8) else {
            log.error("\(self): Failed to parse HTML from \(resp.debugDescription).")
            throw CampNetError.invalidConfiguration  // Not a valid HTML doc.
        }

        var newVars: [String: Any] = [:]

        for (name, xpath) in self.vars {
            let nodes = doc.xpath(xpath)

            if name.hasSuffix("[]") {
                // Capture an array.
                var texts: [String] = []
                for node in nodes {
                    texts.append(node.text?.trimmed ?? "")
                }
                newVars[name.replacingOccurrences(of: "[]", with: "")] = texts
            } else {
                // Capture a single value.
                if let node = nodes.first {
                    newVars[name] = node.text?.trimmed ?? ""
                } else {
                    log.warning("\(self): Failed to capture \(name).")
                }
            }
        }

        return newVars
    }

    func runScript(context: JSContext, resp: String? = nil, newVars: [String: Any]? = nil) throws {
        // Set response if needed.
        if let resp = resp {
            context.setObject(resp, forKeyedSubscript: ActionEntry.respName as (NSCopying & NSObjectProtocol))
        }

        // Send new vars if needed.
        if let newVars = newVars {
            context.setObject(newVars, forKeyedSubscript: ActionEntry.newVarsName as (NSCopying & NSObjectProtocol))
            _ = context.evaluateScript("Object.assign(\(ActionEntry.varsName), \(ActionEntry.newVarsName));")
            if let error = context.exception {
                log.error("\(self): Failed to send new vars: \(error). " +
                    "resp: \(resp.debugDescription). newVars: \(newVars.debugDescription).")
                throw CampNetError.internalError
            }
        }

        // Run script.
        _ = context.evaluateScript(script)
        if let errorString = context.exception?.description {
            if let error = CampNetError(identifier: errorString) {
                throw error
            } else {
                log.error("\(self): Failed to execute script: \(errorString). " +
                          "resp: \(resp.debugDescription). newVars: \(newVars.debugDescription).")
                throw CampNetError.invalidConfiguration
            }
        }
    }

    func getResults(context: JSContext) throws -> [String: Any] {
        guard let results = context.objectForKeyedSubscript(ActionEntry.varsName).toDictionary()
            as? [String: Any] else {
            log.error("\(self): Failed to get results. " +
                      "Object: \(context.objectForKeyedSubscript(ActionEntry.varsName).debugDescription)")
            throw CampNetError.internalError
        }

        return results
    }
}

extension ActionEntry: CustomStringConvertible {
    public var description: String {
        return identifier
    }
}

public struct Action {
    public enum Role: String {
        case login
        case status
        case profile
        case loginIp = "login_ip"
        case logoutSession = "logout_session"
        case history
        case logout
    }

    public static var networkActivityIndicatorHandler = { (_: Bool) in }

    static let jsVm = JSVirtualMachine()!
    fileprivate static var networkActivityCounter = 0

    public static func changeNetworkActivityCount(_ delta: Int) {
        DispatchQueue.main.async {
            Action.networkActivityCounter += delta
            networkActivityIndicatorHandler(Action.networkActivityCounter > 0)
        }
    }

    public var configurationIdentifier: String
    public var role: Role
    public var identifier: String

    public var entries: [ActionEntry] = []

    init?(configurationIdentifier: String, role: Role, yaml: Yaml) {
        let identifier = "\(configurationIdentifier).actions.\(role)"
        self.configurationIdentifier = configurationIdentifier
        self.role = role
        self.identifier = identifier

        guard let array = yaml.array else {
            log.error("\(identifier): Not an array.")
            return nil
        }

        for (index, entry) in array.enumerated() {
            guard let entry = ActionEntry(actionIdentifier: identifier, index: index, yaml: entry) else {
                log.error("\(identifier): Invalid action entry on index \(index).")
                return nil
            }
            entries.append(entry)
        }
    }

    public func commit(username: String, password: String, extraVars: [String: Any] = [:],
                       on queue: DispatchQueue, requestBinder: RequestBinder? = nil) -> Promise<[String: Any]> {

        var initialVars: [String: Any] = [
            "username": username,
            "password": password,
        ]
        for (key, value) in extraVars {
            initialVars[key] = value
        }

        let context = JSContext(virtualMachine: Action.jsVm)!
        context.setObject(initialVars, forKeyedSubscript: ActionEntry.varsName as (NSCopying & NSObjectProtocol))
        setHashFunctions(context)

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.timeoutIntervalForRequest = ActionEntry.timeout
        let session = URLSession(configuration: sessionConfiguration)

        Action.changeNetworkActivityCount(1)

        var promise = Promise.value(initialVars)
        for entry in entries {
            promise = promise.then(on: queue) { vars in
                return entry.commit(currentVars: vars, context: context, session: session, on: queue,
                                    requestBinder: requestBinder)
            }
        }

        promise = promise.map(on: queue) { vars in
            // Add timestamp if needed.
            var vars = vars
            if vars["updated_at"] == nil {
                vars["updated_at"] = Date()
            }
            return vars
        }
        .ensure(on: queue) {
            Action.changeNetworkActivityCount(-1)
        }

        return promise
    }

    fileprivate func setHashFunctions(_ context: JSContext) {
        let md5: @convention(block) (String) -> String = { s in
            return s.md5()
        }
        let sha1: @convention(block) (String) -> String = { s in
            return s.sha1()
        }

        context.setObject(unsafeBitCast(md5, to: AnyObject.self), forKeyedSubscript: "md5" as (NSCopying & NSObjectProtocol))
        context.setObject(unsafeBitCast(sha1, to: AnyObject.self), forKeyedSubscript: "sha1" as (NSCopying & NSObjectProtocol))
    }
}

extension Action: CustomStringConvertible {
    public var description: String {
        return identifier
    }
}
