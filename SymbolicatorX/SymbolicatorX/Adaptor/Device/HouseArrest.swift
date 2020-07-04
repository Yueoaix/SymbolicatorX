//
//  HouseArrest.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


public enum HouseArrestError: Int32, Error {
    case invalidArg = -1
    case plistError = -2
    case connFailed = -3
    case invalidMode = -4
    case unknown = -256
}

public struct HouseArrest {
    
    public static func startService<T>(device: Device, label: String, body: (HouseArrest) throws -> T) throws -> T {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        
        var pclient: house_arrest_client_t? = nil

        let rawError = house_arrest_client_start_service(device, &pclient, label)
        if let error = HouseArrestError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let pointer = pclient else {
            throw HouseArrestError.unknown
        }
        var client = HouseArrest(rawValue: pointer)
        let result = try body(client)
        client.free()
        return result
    }
    
    public var rawValue: house_arrest_client_t?
    
    init(rawValue: house_arrest_client_t) {
        self.rawValue = rawValue
    }
    
    public init(device: Device, service: LockdownService) throws {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        guard let service = service.rawValue else {
            throw LockdownError.notStartService
        }
        
        var client: house_arrest_client_t? = nil
        let rawError = house_arrest_client_new(device, service, &client)
        if let error = HouseArrestError(rawValue: rawError.rawValue) {
            throw error
        }
        self.rawValue = client
    }
    
    public func sendRequest(dict: Plist) throws {
        
        let rawError = house_arrest_send_request(rawValue, dict.rawValue)
        if let error = HouseArrestError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func sendCommand(command: String, appid: String) throws {
        
        let rawError = house_arrest_send_command(rawValue, command, appid)
        if let error = HouseArrestError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func getResult() throws -> Plist {
        
        var presult: plist_t? = nil
        let rawError = house_arrest_get_result(rawValue, &presult)
        if let error = HouseArrestError(rawValue: rawError.rawValue) {
            throw error
        }
        
        guard let result = presult else {
            throw HouseArrestError.unknown
        }
    
        return Plist(rawValue: result)
    }
    
    public mutating func free() {
        guard let rawValue = self.rawValue else {
            return
        }
        house_arrest_client_free(rawValue)
        self.rawValue = nil
    }
    
}
