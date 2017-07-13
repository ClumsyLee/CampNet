//
//  ArrayExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/13.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

extension Array {
    mutating func pushToFirst(from: Int) {
        insert(remove(at: from), at: 0)
    }
}
