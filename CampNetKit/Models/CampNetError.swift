//
//  CampNetError.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/10.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

public enum CampNetError: String, Error {
    case offcampus
    case unauthorized
    case arrears
    
    case networkError
    case invalidArguments
    case invalidConfiguration
    case internalError
    case unknown
    
    public var localizedDescription: String {
        return Configuration.bundle.localizedString(forKey: rawValue, value: nil, table: nil)
    }
    
    init?(identifier: String) {
        switch identifier {
        case "offcampus": self = .offcampus
        case "unauthorized": self = .unauthorized
        case "arrears": self = .arrears
            
        case "network_error": self = .networkError
        case "invalid_arguments": self = .invalidArguments
        case "invalid_configuration": self = .invalidConfiguration
        case "internal_error": self = .internalError
        case "unknown": self = .unknown
        default: return nil
        }
    }
}
