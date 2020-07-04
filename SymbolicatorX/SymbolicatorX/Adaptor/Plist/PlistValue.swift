//
//  PlistValue.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation

public extension Plist {
    init(string: String) {
        self.rawValue = plist_new_string(string)
    }
    
    init(bool: Bool) {
        self.rawValue = plist_new_bool(bool ? 1 : 0)
    }
    
    init(uint: UInt64) {
        self.rawValue = plist_new_uint(uint)
    }
    
    init(uid: UInt64) {
        self.rawValue = plist_new_uid(uid)
    }
    
    init(real: Double) {
        self.rawValue = plist_new_real(real)
    }
    
    init(data: Data) {
        let count = data.count
        self.rawValue = data.withUnsafeBytes { (data) -> plist_t? in
            let value = data.baseAddress?.assumingMemoryBound(to: Int8.self)
            return plist_new_data(value, UInt64(count))
        }
    }
    
    init(date: Date) {
        let timeInterval = date.timeIntervalSinceReferenceDate
        var sec = 0.0
        let usec = modf(timeInterval, &sec)
        self.rawValue = plist_new_date(Int32(sec), Int32(round(usec * 1000000)))
    }
    
    var key: String? {
        get {
            guard nodeType == .key else {
                return nil
            }
            var pkey: UnsafeMutablePointer<Int8>? = nil
            plist_get_key_val(rawValue, &pkey)
            guard let key = pkey else {
                return nil
            }
            defer { key.deallocate() }
            return String(cString: key)
        }
        set {
            guard let key = newValue else {
                return
            }
            plist_set_key_val(rawValue, key)
        }
    }
    
    var string: String? {
        get {
            guard nodeType == .string else {
                return nil
            }
            var pkey: UnsafeMutablePointer<Int8>? = nil
            plist_get_string_val(rawValue, &pkey)
            guard let key = pkey else {
                return nil
            }
            defer { key.deallocate() }
            return String(cString: key)
        }
        set {
            guard let string = newValue else {
                return
            }
            plist_set_string_val(rawValue, string)
        }
    }
    
    var bool: Bool? {
        get {
            guard nodeType == .boolean else {
                return nil
            }
            var bool: UInt8 = 0
            plist_get_bool_val(rawValue, &bool)
            
            return bool > 0
        }
        set {
            guard let bool = newValue else {
                return
            }
            plist_set_bool_val(rawValue, bool ? 1 : 0)
        }
    }
    
    var real: Double? {
        get {
            guard nodeType == .real else {
                return nil
            }
            var double: Double = 0
            plist_get_real_val(rawValue, &double)
            
            return double
        }
        set {
            guard let real = newValue else {
                return
            }
            plist_set_real_val(rawValue, real)
        }
    }
    
    var data: Data? {
        get {
            guard nodeType == .data else {
                return nil
            }
            var pvalue: UnsafeMutablePointer<Int8>? = nil
            var length: UInt64 = 0
            plist_get_data_val(rawValue, &pvalue, &length)
            guard let value = pvalue else {
                return nil
            }
            defer { value.deallocate() }
            return Data(bytes: UnsafeRawPointer(value), count: Int(length))
        }
        set {
            newValue?.withUnsafeBytes { (data: UnsafeRawBufferPointer) -> Void in
                plist_set_data_val(rawValue, data.bindMemory(to: Int8.self).baseAddress, UInt64(data.count))
            }
        }
    }
    
    var date: Date? {
        get {
            guard nodeType == .date else {
                return nil
            }
            
            var sec: Int32 = 0
            var usec: Int32 = 0
            plist_get_date_val(rawValue, &sec, &usec)

            return Date(timeIntervalSinceReferenceDate: Double(sec) + Double(usec) / 1000000)
        }
        set {
            guard nodeType == .date, let date = newValue?.timeIntervalSinceReferenceDate else {
                return
            }
            var sec: Double = 0
            let usec = modf(date, &sec)
            plist_set_date_val(rawValue, Int32(sec), Int32(usec * 1000000))
        }
    }
    
    var uid: UInt64? {
        get {
            guard nodeType == .uid else {
                return nil
            }
            var uid: UInt64 = 0
            plist_get_uid_val(rawValue, &uid)
            
            return uid
        }
        set {
            guard let uid = newValue else {
                return
            }
            plist_set_uid_val(rawValue, uid)
        }
    }
    
    var uint: UInt64? {
        get {
            guard nodeType == .uint else {
                return nil
            }
            var uint: UInt64 = 0
            plist_get_uint_val(rawValue, &uint)
            return uint
        }
        set {
            guard let uint = newValue else {
                return
            }
            plist_set_uint_val(rawValue, uint)
        }
    }
}
