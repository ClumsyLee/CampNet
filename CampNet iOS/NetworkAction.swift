//
//  NetworkAction.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/28.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation
import Yaml
import Alamofire

extension String.Encoding {
    static let gb18030 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
}

struct NetworkAction {
    enum Result: String {
        case online
        case offline
        case unauthorized
        case arrears
        case error
    }
    
    var method: String
    var url: String
    var params: [String: String]
    var results: [Result: NSRegularExpression]
    
    func commit(placeholders: [String: String]? = nil,
                requestBinder: ((NSMutableURLRequest) -> Void)? = nil,
                session: URLSession,
                completionHandler: @escaping (Result) -> Void) {
        print("Commiting action.")

        // Replace placeholders in url and param values.
        var urlString = self.url
        var params = self.params

        if let placeholders = placeholders {
            for (fromStr, toStr) in placeholders {
                let fromStr = "{\(fromStr)}"
                urlString = urlString.replacingOccurrences(of: fromStr, with: toStr)
                for (key, value) in params {
                    params[key] = value.replacingOccurrences(of: fromStr, with: toStr)
                }
            }
        }
        
        guard let url = URL(string: urlString) else {
            print("Failed to convert \(urlString) to URL.")
            return
        }
        let oldRequest = NSMutableURLRequest(url: url)  // The binding API is only available to NSMutableURLRequest now.
        if let requestBinder = requestBinder {
            requestBinder(oldRequest)
        }

        var request = oldRequest as URLRequest
        request.httpMethod = method
        request.allowsCellularAccess = false
        
        do {
            request = try URLEncoding.queryString.encode(request, with: params)
        } catch {
            print("Failed to add params (\(params)) to the request.")
            return
        }

        let task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                print("Failed to get response. Error:", error as Any)
                completionHandler(.error)
                return
            }

            guard let dataStr = String(data: data, encoding: .utf8) ??
                                String(data: data, encoding: .gb18030) else {
                print("Unknown encoding received.")
                return
            }
            
            // Judge result.
            for (result, regex) in self.results {
                if let _ = regex.firstMatch(in: dataStr, range: NSMakeRange(0, (dataStr as NSString).length)) {
                    print("Result:", result)
                    completionHandler(result)
                    return
                }
            }
            print("No matching results.")
            completionHandler(.error)
        }
        task.resume()
        
        print("Action commited.")
    }
}

extension Yaml {
    var stringArray: [String]? {
        get {
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
    }
    
    var networkAction: NetworkAction? {
        get {
            guard let url = self["url"].string,
                  let resultsDict = self["results"].dictionary else {
                print("Required key(s) is missing in configuration.")
                return nil
            }
            let method = self["method"].string ?? "GET"
            let paramsDict = self["params"].dictionary ?? [:]

            var params: [String: String] = [:]
            for (key, value) in paramsDict {
                guard let key = key.string,
                    let value = value.string else {
                        print("Params must be string dictionary.")
                        return nil
                }
                params[key] = value
            }
            
            var results: [NetworkAction.Result: NSRegularExpression] = [:]
            for (key, value) in resultsDict {
                guard let key = key.string,
                      let value = value.string else {
                    print("Results must be string dictionary.")
                    return nil
                }
                guard let result = NetworkAction.Result(rawValue: key),
                      let regex = try? NSRegularExpression(pattern: value) else {
                    print("Invalid result (\(key): \(value)) found.")
                    return nil
                }
                results[result] = regex
            }
            
            return NetworkAction(method: method, url: url, params: params, results: results)
        }
    }
}
