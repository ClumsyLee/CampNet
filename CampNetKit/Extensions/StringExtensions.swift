//
//  StringExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/11.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

extension String {
    func replace(with placeholders: [String: String]) -> String {
        var string = self
        for (key, value) in placeholders {
            string = string.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return string
    }
    
    subscript (index: Int) -> String {
        return String(self[self.index(self.startIndex, offsetBy: index)])
    }
    
    subscript (range: Range<Int>) -> String {
        let startIndex =  self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(startIndex, offsetBy: range.upperBound - range.lowerBound)
        return self[startIndex..<endIndex]
    }
    
//    var int: Int? {
//        return Int(self)
//    }
//    
//    var double: Double? {
//        return Double(self)
//    }
    
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
