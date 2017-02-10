//
//  NetworkAction.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/28.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import JavaScriptCore

import Alamofire
import Kanna
import PromiseKit
import SwiftyUserDefaults
import Yaml

typealias RequestBinder = (NSMutableURLRequest) -> Void

enum CampNetError: Error {
    enum UnauthorizedReason {
        case username
        case password
        case usernamePassword
        case billing
    }
    
    case offcampus
    case unauthorized(reason: UnauthorizedReason)  // Account setting should be changed.
    case arrears

    case invalidConfiguration
    case networkError
    case internalError
    case unknown
    
    init?(identifier: String) {
        switch identifier {
        case "offcampus": self = .offcampus
        case "unauthorized.username": self = .unauthorized(reason: .username)
        case "unauthorized.password": self = .unauthorized(reason: .password)
        case "unauthorized.username_password": self = .unauthorized(reason: .usernamePassword)
        case "unauthorized.billing": self = .unauthorized(reason: .billing)
        case "arrears": self = .arrears

        case "network_error": self = .networkError
        case "invalid_configuration": self = .invalidConfiguration
        case "internal_error": self = .internalError
        case "unknown": self = .unknown
        default: return nil
        }
    }
}

class ActionEntry {
    static let varsName = "vars"
    static let respName = "resp"
    
    static func makeIdentifier(actionIdentifier: String, index: Int) -> String {
        return "\(actionIdentifier)[\(index)]"
    }

    let actionIdentifier: String
    let index: Int
    var identifier: String { return ActionEntry.makeIdentifier(actionIdentifier: actionIdentifier, index: index) }
    

    var method: String
    var url: String
    var params: [String: String] = [:]
    var expect: NSRegularExpression?
    var errors: [(CampNetError, NSRegularExpression)] = []
    var vars: [String: String] = [:]
    var postHook: String
    
    init?(actionIdentifier: String, index: Int, yaml: Yaml) {
        self.actionIdentifier = actionIdentifier
        self.index = index
        let identifier = ActionEntry.makeIdentifier(actionIdentifier: actionIdentifier, index: self.index)

        method = yaml["method"].string ?? "GET"
        
        guard let url = yaml["url"].string else {
            print("url key is missing for \(identifier).")
            return nil
        }
        self.url = url
        
        if let params = yaml["params"].stringDictionary {
            self.params = params
        }
        
        if let expect = yaml["expect"].regex {
            self.expect = expect
        }
        
        if let errors = yaml["errors"].stringDictionary {
            for (id, regexString) in errors {
                guard let error = CampNetError(identifier: id) else {
                    print("Unknown error id \(id) for \(identifier).")
                    return nil
                }
                guard let regex = try? NSRegularExpression(pattern: regexString) else {
                    print("Invalid regex \(regexString) for \(identifier).")
                    return nil
                }
                self.errors.append((error, regex))
            }
        }
        
        if let vars = yaml["vars"].stringDictionary {
            self.vars = vars
        }
        
        postHook = "(\(ActionEntry.respName)) => {\n\(yaml["post_hook"].string ?? "")\n}"
    }

    func commit(placeholders: [String: String] = [:],
                on queue: DispatchQueue,
                context: JSContext,
                session: URLSession,
                requestBinder: RequestBinder? = nil) -> Promise<[String: ActionResult]> {

        // Build request.
        guard let request = buildRequest(placeholders: placeholders, requestBinder: requestBinder) else {
            print("Failed to build the request for \(identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        
        print("Commiting \(identifier).")

        return session.dataTask(with: request).asString().recover(on: queue) { error -> Promise<String> in
            print("Data task of \(self.identifier) failed: \(error)")
            throw CampNetError.networkError
        }
        .then(on: queue) { resp in
            // Decode to string.
            // guard let resp = String(data: data, encoding: .utf8) ??
            //                  String(data: data, encoding: .gb18030) else {
            //     print("Unable to decode the data of \(self.identifier). Data: \(data)")
            //     throw CampNetError.internalError
            // }
            
            print("Processing the response of \(self.identifier).")

            try self.matchExpectAndErrors(resp: resp)    // Match expect and errors.
            let vars = try self.captureVars(resp: resp)  // Capture vars.
            try self.send(context: context, vars: vars)         // Send vars.
            try self.runPostHook(context: context, resp: resp)  // Invoke postHook.
            
            return Promise(value: try self.getResults(context: context))
        }
    }
    
    func buildRequest(placeholders: [String: String] = [:], requestBinder: RequestBinder?) -> URLRequest? {
        let urlString = url.replace(with: placeholders)
        guard let url = URL(string: urlString) else {
            print("Failed to convert \(urlString) to URL.")
            return nil
        }
        
        var params: [String: String] = [:]
        for (key, value) in self.params {
            params[key.replace(with: placeholders)] = value.replace(with: placeholders)
        }
        
        let oldRequest = NSMutableURLRequest(url: url)  // The binding API is only available to NSMutableURLRequest now.
        if let requestBinder = requestBinder {
            requestBinder(oldRequest)
        }
        var request = oldRequest as URLRequest
        
        request.httpMethod = method
        do {
            request = try URLEncoding.queryString.encode(request, with: params)
        } catch let error {
            print("Failed to add \(params) to the request: \(error)")
            return nil
        }
        
        return request
    }
    
    func matchExpectAndErrors(resp: String) throws {
        var bad = false
        if let expect = self.expect {
            if resp.match(regex: expect) {
                print("\(identifier).expect matches resp.")
                return
            } else {
                print("\(identifier).expect doesn't match resp.")
                bad = true
            }
        }
        
        // Match errors if there is no expectation, or if the expectation failled.
        for (error, regex) in self.errors {
            if resp.match(regex: regex) {
                print("\(identifier).errors.\(error) matches resp.")
                throw error
            }
        }
        // No matching errors.
        if bad {
            print("No errors in \(identifier).errors matches resp.")
            throw CampNetError.unknown
        }
    }
    
    func captureVars(resp: String) throws -> [String: ActionResult] {
        if self.vars.isEmpty {
            return [:]  // Don't parse HTML if there is nothing to capture.
        }

        guard let doc = HTML(html: resp, encoding: String.Encoding.utf8) else {
            print("Failed to parse HTML of \(identifier): \(resp)")
            throw CampNetError.invalidConfiguration  // Not a valid HTML doc.
        }

        var vars: [String: ActionResult] = [:]

        for (name, xpath) in self.vars {
            let nodes = doc.xpath(xpath)
            
            if name.withArrayNotation {
                var texts: [String] = []
                for node in nodes {
                    texts.append(node.text?.trimmed ?? "")
                }
                vars[name] = ActionResult(texts)
            } else {
                if let node = nodes.first {
                    vars[name] = ActionResult(node.text?.trimmed ?? "")
                } else {
                    print("Failed to capture \(identifier).vars.\(name), continue anyway.")
                }
            }
        }

        return vars
    }
    
    func send(context: JSContext, vars: [String: Any]) throws {
        _ = context.evaluateScript("(vars) => { Object.assign(\(ActionEntry.varsName), vars) }").call(withArguments: [vars])
        if let error = context.exception {
            print("Failed to send vars of \(identifier): \(error)")
            throw CampNetError.internalError
        }
    }
    
    func runPostHook(context: JSContext, resp: String) throws {
        _ = context.evaluateScript(postHook).call(withArguments: [resp])
        if let error = context.exception {
            // TODO: throw certain errors if possible.
            print("Failed to execute post hook of \(identifier): \(error)")
            throw CampNetError.invalidConfiguration
        }
    }
    
    func getResults(context: JSContext) throws -> [String: ActionResult] {
        guard let vars = context.objectForKeyedSubscript(ActionEntry.varsName).toDictionary() as? [String: Any] else {
            throw CampNetError.internalError
        }
        
        var results: [String: ActionResult] = [:]
        for (key, value) in vars {
            results[key] = ActionResult(value)
        }

        return results
    }
}

class Action {
    enum Role: String {
        case login
        case status
        case profile
        case modifyCustomMaxOnlineNum = "modify_custom_max_online_num"
        case loginIp = "login_ip"
        case logoutSession = "logout_session"
        case history
        case logout
    }
    
    static func makeIdentifier(configurationIdentifier: String, role: Role) -> String {
        return "\(configurationIdentifier).actions.\(role)"
    }

    let configurationIdentifier: String
    let role: Role
    var identifier: String { return Action.makeIdentifier(configurationIdentifier: configurationIdentifier, role: role) }

    var entries: [ActionEntry] = []

    init?(configurationIdentifier: String, role: Role, yaml: Yaml) {
        self.configurationIdentifier = configurationIdentifier
        self.role = role
        let identifier = Action.makeIdentifier(configurationIdentifier: configurationIdentifier, role: role)

        guard let array = yaml.array else {
            print("\(identifier) is not an array.")
            return nil
        }

        for (index, entry) in array.enumerated() {
            guard let entry = ActionEntry(actionIdentifier: identifier, index: index, yaml: entry) else {
                print("Invalid action entry on index \(index).")
                return nil
            }
            entries.append(entry)
        }
    }

    func commit(username: String, password: String, extraVars: [String: String] = [:], on queue: DispatchQueue, requestBinder: RequestBinder? = nil) -> Promise<[String: ActionResult]> {

        var placeholders: [String: String] = [
            "username": username,
            "password": password,
            "password.md5": password.md5,
        ]
        for (key, value) in extraVars {
            placeholders[key] = value
        }

        let context = JSContext()!
        initializeVars(context: context)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        var promise = Promise<[String: ActionResult]>(value: [:])
        
        for entry in entries {
            promise = promise.then(on: queue) { vars in
                // Merge vars to placeholders.
                var placeholders = placeholders
                for (name, value) in vars {
                    if let value = value.string {
                        placeholders["vars.\(name)"] = value
                    }
                }
                return entry.commit(placeholders: placeholders, on: queue, context: context, session: session, requestBinder: requestBinder)
            }
        }
        
        print("Action \(identifier) committed.")
        return promise
    }
    
    func initializeVars(context: JSContext) {
        context.evaluateScript("var \(ActionEntry.varsName) = {}")
    }
}
