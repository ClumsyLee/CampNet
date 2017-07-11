//
//  CollectionExtensions.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/11.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
