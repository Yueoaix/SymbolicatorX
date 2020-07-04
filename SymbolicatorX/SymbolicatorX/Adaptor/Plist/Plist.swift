//
//  Plist.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


public struct PlistError: Error {
    public enum PlistErrorType {
        case invalidArgument
    }
    
    public let type: PlistErrorType
    public let message: String
    
    public init(type: PlistErrorType, message: String) {
        self.type = type
        self.message = message
    }
}

public enum PlistType {
    case boolean
    case uint
    case real
    case string
    case array
    case dict
    case date
    case data
    case key
    case uid
    case none
    
    public init(rawValue: plist_type) {
        switch rawValue {
        case PLIST_BOOLEAN:
            self = .boolean
        case PLIST_UINT:
            self = .uint
        case PLIST_REAL:
            self = .real
        case PLIST_STRING:
            self = .string
        case PLIST_ARRAY:
            self = .array
        case PLIST_DICT:
            self = .dict
        case PLIST_DATE:
            self = .date
        case PLIST_DATA:
            self = .data
        case PLIST_KEY:
            self = .key
        case PLIST_UID:
            self = .uid
        default:
            self = .none
        }
    }
}

public struct Plist {
    public var rawValue: plist_t?
    
    public init(rawValue: plist_t) {
        self.rawValue = rawValue
    }

    public init?(nillableValue: plist_t?) {
        guard let rawValue = nillableValue else {
            return nil
        }
        self.rawValue = rawValue
    }
    
    mutating func free() {
        guard let rawValue = self.rawValue else {
            return
        }
        plist_free(rawValue)
        self.rawValue = nil
    }
}

public extension Plist {
    var size: UInt32? {
        switch nodeType {
        case .array:
            return plist_array_get_size(rawValue)
        case .dict:
            return plist_dict_get_size(rawValue)
        default:
            return nil
        }
    }
}

public extension Plist {

    static func copy(from node: Self) -> Self {
        return node
    }
    
    func getParent() -> Plist? {
        let parent = plist_get_parent(rawValue)
        return Plist(nillableValue: parent)
    }
    
    func xml() -> String? {
        var pxml: UnsafeMutablePointer<Int8>? = nil
        var length: UInt32 = 0
        plist_to_xml(rawValue, &pxml, &length)
        guard let xml = pxml else {
            return nil
        }
        
        defer { plist_to_xml_free(xml) }
        return String(cString: xml)
    }
    
    func bin() -> Data? {
        var pbin: UnsafeMutablePointer<Int8>? = nil
        var length: UInt32 = 0
        plist_to_bin(rawValue, &pbin, &length)
        guard let bin = pbin else {
            return nil
        }
        
        defer { plist_to_bin_free(bin) }
        return Data(bytes: UnsafeRawPointer(bin), count: Int(length))
    }
    
    var nodeType: PlistType {
        let type = plist_get_node_type(rawValue)
        return PlistType(rawValue: type)
    }
}

extension Plist: Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        plist_compare_node_value(lhs.rawValue, rhs.rawValue) > 0
    }
}

public extension Plist {
    
    init?(xml: String) {
        let length = xml.utf8CString.count
        var prawValue: plist_t? = nil
        plist_from_xml(xml, UInt32(length), &prawValue)
        guard let rawValue = prawValue else {
            return nil
        }
        self.rawValue = rawValue
    }
    
    init?(bin: Data) {
        let prawValue = bin.withUnsafeBytes { (bin) -> plist_t? in
            var plist: plist_t? = nil
            guard let pointer = bin.baseAddress else {
                return nil
            }

            plist_from_bin(pointer.bindMemory(to: Int8.self, capacity: bin.count), UInt32(bin.count), &plist)
            return plist
        }
        
        guard let rawValue = prawValue else {
            return nil
        }
        self.rawValue = rawValue
    }
    
    init?(memory: String) {
        let length = memory.utf8CString.count
        var prawValue: plist_t? = nil
        plist_from_memory(memory, UInt32(length), &prawValue)
        guard let rawValue = prawValue else {
            return nil
        }
        self.rawValue = rawValue
    }
    
    static func isBinary(data: String) -> Bool {
        plist_is_binary(data, UInt32(data.utf8CString.count)) > 0
    }
}

extension Plist: CustomStringConvertible {
    
    public var description: String {
        return xml() ?? ""
    }
}
