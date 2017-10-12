//
//  CampNetError.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/10.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

public enum CampNetError: Error {
    case offcampus
    case unauthorized
    case arrears

    case networkError
    case invalidConfiguration
    case internalError
    case unknown(String)

    public var localizedDescription: String {
        let key: String
        var argument: String?

        switch self {
        case .offcampus: key = "offcampus"
        case .unauthorized: key = "unauthorized"
        case .arrears: key = "arrears"

        case .networkError: key = "networkError"
        case .invalidConfiguration: key = "invalidConfiguration"
        case .internalError: key = "internalError"

        case let .unknown(detail):
            key = "unknown"
            argument = detail
        }

        let formatString = Configuration.bundle.localizedString(forKey: key, value: nil, table: nil)
        if let argument = argument {
            return String.localizedStringWithFormat(formatString, argument)
        } else {
            return formatString
        }
    }

    init?(identifier: String) {
        switch identifier {
        case "offcampus": self = .offcampus
        case "unauthorized": self = .unauthorized
        case "arrears": self = .arrears

        case "network_error": self = .networkError
        case "invalid_configuration": self = .invalidConfiguration
        case "internal_error": self = .internalError
        default:
            if let detail = identifier.chopPrefix("unknown: ") {
                self = .unknown(detail)
            } else {
                return nil
            }
        }
    }
}
