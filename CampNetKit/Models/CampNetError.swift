//
//  CampNetError.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/10.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import Foundation

public enum CampNetError: Error {
    case offcampus
    case offline
    case unauthorized
    case arrears

    case networkError
    case invalidConfiguration
    case internalError
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .offcampus: return L10n.CampNetError.offcampus
        case .offline: return L10n.CampNetError.offline
        case .unauthorized: return L10n.CampNetError.unauthorized
        case .arrears: return L10n.CampNetError.arrears

        case .networkError: return L10n.CampNetError.networkError
        case .invalidConfiguration: return L10n.CampNetError.invalidConfiguration
        case .internalError: return L10n.CampNetError.internalError
        case let .unknown(detail): return L10n.CampNetError.unknown(detail)
        }
    }

    init?(identifier: String) {
        switch identifier {
        case "offcampus": self = .offcampus
        case "offline": self = .offline
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
