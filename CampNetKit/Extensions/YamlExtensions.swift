//
//  YamlExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/10.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import Yaml

extension Yaml {
    var doublePair: (Double, Double)? {
        guard let first = self[0].double,
            let second = self[1].double else {
                return nil
        }
        return (first, second)
    }
    
    var doublePairArray: [(Double, Double)]? {
        guard let array = self.array else {
            return nil
        }
        
        var pairs: [(Double, Double)] = []
        for element in array {
            guard let pair = element.doublePair else {
                return nil
            }
            pairs.append(pair)
        }
        return pairs
    }
    
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
