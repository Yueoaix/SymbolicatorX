//
//  String+Unsafe.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


extension String {
    func unsafeMutablePointer() -> UnsafeMutablePointer<Int8>? {
        let cString = utf8CString
        let buffer = UnsafeMutableBufferPointer<Int8>.allocate(capacity: cString.count)
        _ = buffer.initialize(from: cString)
        
        return buffer.baseAddress
    }
    
    func unsafePointer() -> UnsafePointer<Int8>? {
        return UnsafePointer<Int8>(unsafeMutablePointer())
    }
    
    static func array(point: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> [String] {
        
        var count = 0
        var p = point?[count]
        while p != nil {
            count += 1
            p = point?[count]
        }
        
        let bufferPointer = UnsafeMutableBufferPointer<UnsafeMutablePointer<Int8>?>(start: point, count: count)
        let list = bufferPointer.compactMap { $0 }.map { String(cString: $0) }
        
        return list
    }
}
