//
//  Utilities.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/2/3.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import Yaml

extension String.Encoding {
    static let gb18030 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
}

extension Yaml {
    var regex: NSRegularExpression? {
        guard let regex = self.string else {
            return nil
        }
        return try? NSRegularExpression(pattern: regex)
    }

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

extension String {
    func replace(with placeholders: [String: String]) -> String {
        var string = self
        for (key, value) in placeholders {
            string = string.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return string
    }
    
    func match(regex: NSRegularExpression, options: NSRegularExpression.MatchingOptions = []) -> Bool {
        return regex.numberOfMatches(in: self, options: options, range: NSMakeRange(0, (self as NSString).length)) > 0
    }
    
    subscript (index: Int) -> String {
        return String(self[self.index(self.startIndex, offsetBy: index)])
    }
    
    subscript (range: Range<Int>) -> String {
        let startIndex =  self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(startIndex, offsetBy: range.upperBound - range.lowerBound)
        return self[startIndex..<endIndex]
    }
    
    func matchGroups(regex: NSRegularExpression, options: NSRegularExpression.MatchingOptions = []) -> [String?]? {
        guard let match = regex.firstMatch(in: self, range: NSMakeRange(0, (self as NSString).length)) else {
            return nil
        }
        
        var groups: [String?] = []
        for index in 0..<match.numberOfRanges {
            if let range = match.rangeAt(index).toRange() {
                groups.append(self[range])
            } else {
                groups.append(nil)
            }
        }
        
        return groups
    }
    
    // Function adapted form http://stackoverflow.com/a/25136254/4154977
    var md5: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        
        if let d = self.data(using: String.Encoding.utf8) {
            _ = d.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
                CC_MD5(body, CC_LONG(d.count), &digest)
            }
        }
        
        return (0..<length).reduce("") {
            $0 + String(format: "%02x", digest[$1])
        }
    }
    
    var withArrayNotation: Bool {
        return self.hasPrefix("[") && self.hasSuffix("]")
    }
    
    var int: Int? {
        return Int(self)
    }

    var double: Double? {
        return Double(self)
    }
    
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Double {
    var int: Int {
        return Int(self)
    }
    
    var string: String {
        return String(self)
    }
    
    var date: Date {
        return Date(timeIntervalSince1970: self)
    }
}

extension Int {
    var double: Double {
        return Double(self)
    }
    
    var string: String {
        return String(self)
    }
}

extension Collection where Indices.Iterator.Element == Index {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
