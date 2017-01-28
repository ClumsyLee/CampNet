//
//  Configuration.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/18.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import Yaml

class Configuration {
    var ssids: [String]
    var loginAction: NetworkAction
    var statusAction: NetworkAction
    var logoutAction: NetworkAction
    
    init?(identifier: String) {
        print("Loading configuration (\(identifier)).")

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
