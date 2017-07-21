//
//  Action.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/10.
//  Copyright © 2017年 Sihan Li. All rights reserved.
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
    static let varsName = "vars"
    static let respName = "resp"
    
    public var actionIdentifier: String
    public var index: Int
    public var identifier: String
    
    public var method: String
    public var url: String
    public var params: [String: String] = [:]
    public var vars: [String: String] = [:]
    public var offcampusIfFailed: Bool
    public var script: String
    
    init?(actionIdentifier: String, index: Int, yaml: Yaml) {
        self.actionIdentifier = actionIdentifier
        self.index = index
        self.identifier = "\(actionIdentifier)[\(index)]"
        
        self.method = yaml["method"].string ?? "GET"
        
        guard let url = yaml["url"].string else {
            print("url key is missing for \(identifier).")
            return nil
        }
        self.url = url
        
        if let params = yaml["params"].stringDictionary {
            self.params = params
        }
        
        if let vars = yaml["vars"].stringDictionary {
            self.vars = vars
        }
        
        self.offcampusIfFailed = yaml["offcampus_if_failed"].bool ?? false
        self.script = "(\(ActionEntry.respName)) => {\n\(yaml["script"].string ?? "")\n}"
    }
    
    func commit(currentVars: [String: Any] = [:],
                context: JSContext,
                session: URLSession,
                on queue: DispatchQueue = DispatchQueue.global(qos: .utility),
                requestBinder: RequestBinder? = nil) -> Promise<[String: Any]> {
        // Load placeholders from vars.
        var placeholders: [String: String] = [:]
        for (key, value) in currentVars {
            if let value = value as? String {
                placeholders[key] = value
            } else if let value = value as? Int {
                placeholders[key] = String(value)
            }
        }
        
        // Build request.
        guard let request = buildRequest(placeholders: placeholders, requestBinder: requestBinder) else {
            print("Failed to build the request for \(identifier).")
            return Promise(error: CampNetError.invalidConfiguration)
        }
        
        print("Commiting \(identifier).")
        
        return session.dataTask(with: request).asString().recover(on: queue) { error -> Promise<String> in
            print("Data task of \(self.identifier) failed: \(error)")
            throw self.offcampusIfFailed ? CampNetError.offcampus : CampNetError.networkError
        }
        .then(on: queue) { resp in
            print("Processing the response of \(self.identifier).")
            
            let newVars = try self.captureNewVars(resp: resp)    // Capture new vars from HTML if needed.
            try self.runScript(context: context, resp: resp ,newVars: newVars)     // Invoke script.
            let results = try self.getResults(context: context)  // Get results.

            return Promise(value: results)
        }
    }
    
    func buildRequest(placeholders: [String: String] = [:], requestBinder: RequestBinder?) -> URLRequest? {
        // Prepare arguments.
        let urlString = url.replace(with: placeholders)
        guard let url = URL(string: urlString) else {
            print("Failed to convert \(urlString) to URL.")
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
            print("Failed to add \(params) to the request: \(error)")
            return nil
        }
        
        return request
    }
    
    func captureNewVars(resp: String) throws -> [String: Any] {
        if self.vars.isEmpty {
            return [:]  // Don't parse HTML if there is nothing to capture.
        }
        
        guard let doc = HTML(html: resp, encoding: String.Encoding.utf8) else {
            print("Failed to parse HTML of \(identifier): \(resp)")
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
                    print("Failed to capture \(identifier).vars.\(name), continue anyway.")
                }
            }
        }
        
        return newVars
    }
    
    func runScript(context: JSContext, resp: String, newVars: [String: Any]) throws {
        // Send new vars.
        _ = context.evaluateScript("(newVars) => { Object.assign(\(ActionEntry.varsName), newVars) }").call(withArguments: [newVars])
        if let error = context.exception {
            print("Failed to send new vars of \(identifier): \(error)")
            throw CampNetError.internalError
        }
        
        // Run script.
        _ = context.evaluateScript(script).call(withArguments: [resp])
        if let errorString = context.exception?.description {
            print("Failed to execute the script of \(identifier): \(errorString). resp: \(resp.debugDescription). newVars: \(newVars.debugDescription).")
            if let error = CampNetError(identifier: errorString) {
                throw error
            } else {
                throw CampNetError.invalidConfiguration
            }
        }
    }
    
    func getResults(context: JSContext) throws -> [String: Any] {
        guard let results = context.objectForKeyedSubscript(ActionEntry.varsName).toDictionary() as? [String: Any] else {
            print("Failed to get the results of \(identifier). Object: \(context.objectForKeyedSubscript(ActionEntry.varsName).debugDescription)")
            throw CampNetError.internalError
        }
        
        return results
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
    
    public var configurationIdentifier: String
    public var role: Role
    public var identifier: String
    
    public var entries: [ActionEntry] = []
    
    init?(configurationIdentifier: String, role: Role, yaml: Yaml) {
        self.configurationIdentifier = configurationIdentifier
        self.role = role
        self.identifier = "\(configurationIdentifier).actions.\(role)"
        
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
    
    public func commit(username: String, password: String, extraVars: [String: Any] = [:], on queue: DispatchQueue = DispatchQueue.global(qos: .utility), requestBinder: RequestBinder? = nil) -> Promise<[String: Any]> {

        var initialVars: [String: Any] = [
            "username": username,
            "password": password,
            "password_md5": password.md5()
        ]
        for (key, value) in extraVars {
            initialVars[key] = value
        }
        
        let context = JSContext()!
        context.setObject(initialVars, forKeyedSubscript: ActionEntry.varsName as (NSCopying & NSObjectProtocol))
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        var promise = Promise<[String: Any]>(value: initialVars)
        for entry in entries {
            promise = promise.then(on: queue) { vars in
                return entry.commit(currentVars: vars, context: context, session: session, on: queue, requestBinder: requestBinder)
            }
        }
        
        // Add timestamp if needed.
        promise = promise.then(on: queue) { vars in
            var vars = vars
            if vars["updated_at"] == nil {
                vars["updated_at"] = Date()
            }
            return Promise(value: vars)
        }
        
        return promise
    }
}
