//
//  Configuration.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/18.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import Yaml

class Configuration: CustomStringConvertible {
    static var pool: [String: Configuration] = [:]
    static func load(identifier: String) -> Configuration? {
        if let config = pool[identifier] {
            print("Cached configuration (\(identifier)) found.")
            return config
        }

        if let config = Configuration(identifier: identifier) {
            Configuration.pool[identifier] = config  // Cache it.
            return config
        } else {
            return nil
        }
    }
    
    let identifier: String
    var ssids: [String]
    var loginAction: NetworkAction
    var statusAction: NetworkAction
    var logoutAction: NetworkAction
    
    var description: String { return "Configuration(\(identifier))" }
    
    init?(identifier: String) {
        print("Loading configuration (\(identifier)).")

        self.identifier = identifier

        guard let url = Bundle.main.url(forResource: identifier, withExtension: "yaml", subdirectory: "Configs") else {
            print("Failed to find configuration (\(identifier)).")
            return nil
        }
    
        guard let content = try? String(contentsOf: url) else {
            print("Failed to read the configuration (\(identifier)).")
            return nil
        }
        guard let yaml = try? Yaml.load(content) else {
            print("Failed to load YAML out of configuration (\(identifier)).")
            return nil
        }
        
        guard let ssids = yaml["ssids"].stringArray,
              let loginAction = yaml["login"].networkAction,
              let statusAction = yaml["status"].networkAction,
              let logoutAction = yaml["logout"].networkAction else {
            print("Missing key in configuration (\(identifier)).")
            return nil
        }

        self.ssids = ssids
        self.loginAction = loginAction
        self.statusAction = statusAction
        self.logoutAction = logoutAction

        print("Configuration (\(identifier)) loaded.")
    }
}
