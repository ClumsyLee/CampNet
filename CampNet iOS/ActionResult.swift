//
//  ActionResult.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/2/8.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

class ActionResult {
    struct Regex {
        static let double = try! NSRegularExpression(pattern: "\\d+(\\.\\d*)?")
        static let usage = try! NSRegularExpression(pattern: "(\\d+(\\.\\d*)?)\\s*([KMG]?)")
        static let mac = try! NSRegularExpression(pattern: "([0-9A-F]{2}:){5}[0-9A-F]")
        static let compactMac = try! NSRegularExpression(pattern: "[0-9A-F]{12}")
    }
    
    static let dateFormatters: [ISO8601DateFormatter] = {
        var formatters: [ISO8601DateFormatter] = []
        
        let optionsList: [ISO8601DateFormatter.Options] = [
            [.withFullDate, .withFullTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withSpaceBetweenDateAndTime]
        ]
        
        for options in optionsList {
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 8 * 3600)  // UTC +8
            formatter.formatOptions = options
            formatters.append(formatter)
        }
        
        return formatters
    }()


    let value: Any
    
    var string: String? {
        return value as? String
    }
    
    var stringArray: [String]? {
        return value as? [String]
    }
    
    var int: Int? {
        return value as? Int ??
               self.string?.int
    }
    
    var intArray: [Int]? {
        return value as? [Int]
    }
    
    var double: Double? {
        return value as? Double ??
               self.string?.double
    }
    
    var doubleArray: [Double]? {
        return value as? [Double]
    }
    
    var innerInt: Int? {
        return self.int ??
               self.InnerDouble?.int
    }
    
    var InnerDouble: Double? {
        return self.double ??
               self.string?.matchGroups(regex: Regex.double)?[0]?.double
    }
    
    var date: Date? {
        if let date = value as? Date ??
                      self.double?.date {
            return date
        }
        if let string = self.string {
            for formatter in ActionResult.dateFormatters {
                if let date = formatter.date(from: string) {
                    return date
                }
            }
        }

        return nil
    }
    
    var usage: Int? {
        if let int = self.int {
            return int
        }
        if let groups = self.string?.uppercased().matchGroups(regex: Regex.usage),
           let number = groups[1]?.double,
           let unit = groups[3] {

            let ratio: Int
            switch unit {
            case "K": ratio = 1024
            case "M": ratio = 1024 * 1024
            case "G": ratio = 1024 * 1024 * 1024
            default: ratio = 1
            }
            
            return (number * ratio.double).rounded().int
        }
        
        return nil
    }
    
    var mac: String? {
        guard let string = self.string else { return nil }
        
        if string.match(regex: Regex.mac) {
            return string
        }
        if let mac = string.matchGroups(regex: Regex.compactMac)?[0] {
            return "\(mac[0..<2]):\(mac[2..<4]):\(mac[4..<6]):\(mac[6..<8]):\(mac[8..<10]):\(mac[10..<12])"
        }
        
        return nil
    }
    
    var ip: String? {
        // TODO: Implement this.
        return self.string
    }
    
    var dateArray: [Date]? {
        return getArray{$0.date}
    }

    var usageArray: [Int]? {
        return getArray{$0.usage}
    }
    
    var macArray: [String]? {
        return getArray{$0.mac}
    }

    var ipArray: [String]? {
        return getArray{$0.ip}
    }

    init(_ value: Any) {
        self.value = value
    }
    
    func getArray<T>(getter: (ActionResult) -> T?) -> [T]? {
        guard let array = value as? [T] else { return nil }
        
        var results: [T] = []
        for element in array {
            guard let result = getter(ActionResult(element)) else {return nil }
            results.append(result)
        }
        return results
    }
}
