//
//  YamlExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/10.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import Foundation
import Yaml

extension Yaml {
    var stringArray: [String]? {
        guard let array = self.array else {
            return nil
        }

        var stringArray: [String] = []
        for value in array {
            guard let value = value.string else {
                return nil
            }
            stringArray.append(value)
        }
        return stringArray
    }

    var stringDictionary: [String: String]? {
        guard let dict = self.dictionary else {
            return nil
        }

        var stringDict: [String: String] = [:]
        for (key, value) in dict {
            guard let key = key.string, let value = value.string else {
                return nil
            }
            stringDict[key] = value
        }
        return stringDict
    }
}
