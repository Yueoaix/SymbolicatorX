//
//  Device.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


public struct DeviceLookupOptions: OptionSet {
    public static let usbmux = DeviceLookupOptions(rawValue: 1 << 1)
    public static let network = DeviceLookupOptions(rawValue: 1 << 2)
    public static let preferNetwork = DeviceLookupOptions(rawValue: 1 << 3)
    
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public struct Device {
    
    var rawValue: idevice_t? = nil
    
    public init(udid: String) throws {
        let rawError = idevice_new(&rawValue, udid)
        if let error = MobileDeviceError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public init(udid: String, options: DeviceLookupOptions) throws {
        let rawError = idevice_new_with_options(&rawValue, udid, .init(options.rawValue))
        if let error = MobileDeviceError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func connect(port: UInt) throws -> DeviceConnection {
        guard let device = self.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        
        var pconnection: idevice_connection_t? = nil
        let rawError = idevice_connect(device, UInt16(port), &pconnection)
        if let error = MobileDeviceError(rawValue: rawError.rawValue) {
            throw error
        }
        
        guard let connection = pconnection else {
            throw MobileDeviceError.unknown
        }
        let conn = DeviceConnection(rawValue: connection)
        return conn
    }
    
    public func getHandle() throws -> UInt32 {
        guard let rawValue = self.rawValue else {
            throw MobileDeviceError.disconnected
        }
        var handle: UInt32 = 0
        let rawError = idevice_get_handle(rawValue, &handle)
        
        if let error = MobileDeviceError(rawValue: rawError.rawValue) {
            throw error
        }
        
        return handle
    }
    
    public func getUDID() throws -> String {
        guard let rawValue = self.rawValue else {
            throw MobileDeviceError.disconnected
        }
        
        var pudid: UnsafeMutablePointer<Int8>? = nil
    
        let rawError = idevice_get_udid(rawValue, &pudid)
        if let error = MobileDeviceError(rawValue: rawError.rawValue) {
            throw error
        }
        
        guard let udid = pudid else {
            throw MobileDeviceError.unknown
        }
        
        defer { udid.deallocate() }
        return String(cString: udid)
    }
    
    public mutating func free() {
        if let rawValue = self.rawValue {
            idevice_free(rawValue)
            self.rawValue = nil
        }
    }
}

