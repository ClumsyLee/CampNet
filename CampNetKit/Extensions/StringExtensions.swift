//
//  StringExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/11.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

extension String {
    public var reverseDomained: String {
        return self.components(separatedBy: ".").reversed().joined(separator: ".")
    }
    
    public var nonEmpty: String? {
        return self.isEmpty ? nil : self
    }
    
    func replace(with placeholders: [String: String]) -> String {
        var string = self
        for (key, value) in placeholders {
            string = string.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return string
    }

    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func chopPrefix(_ prefix: String) -> String? {
        if hasPrefix(prefix) {
            return String(self[index(startIndex, offsetBy: prefix.count)...])
        } else {
            return nil
        }
    }
}
