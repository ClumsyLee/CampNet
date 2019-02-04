//
//  StringExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/11.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import Foundation

extension String.Encoding {
    static let gb_18030_2000 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
}

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

    // Based on PromiseKit.
    init?(data: Data, urlResponse: URLResponse) {
        var stringEncoding: String.Encoding? = nil

        if let encodingName = urlResponse.textEncodingName {
            let encoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
            if encoding != kCFStringEncodingInvalidId {
                stringEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(encoding))
            }
        }

        if let stringEncoding = stringEncoding {
            self.init(bytes: data, encoding: stringEncoding)
        } else if let string = String(bytes: data, encoding: .utf8) {
            self.init(string)
        } else if let string = String(bytes: data, encoding: .gb_18030_2000) {
            self.init(string)
        } else {
            return nil
        }
    }
}
