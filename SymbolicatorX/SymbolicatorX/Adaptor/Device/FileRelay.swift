//
//  FileRelay.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


public enum FileRelayError: Int32, Error {
    case invalidArgument = -1
    case plistError = -2
    case muxError = -3
    case invalidSource = -4
    case stagingEmpty = -5
    case permissionDenied = -6
    case unknown = -256
    
    case deallocatedClient = 100
}

public enum FileRelayRequestSource: String {
    case appleSupport = "AppleSupport"
    case network = "Network"
    case vpn = "VPN"
    case wifi = "Wifi"
    case userDatabases = "UserDatabases"
    case crashReporter = "CrashReporter"
    case tmp = "tmp"
    case systemConfiguration = "SystemConfiguration"
}

public struct FileRelayClient {
    
    public static func start<T>(device: Device, label: String, body: (FileRelayClient) throws -> T) throws -> T {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        
        var pclient: file_relay_client_t? = nil
        let rawError = file_relay_client_start_service(device, &pclient, label)
        if let error = FileRelayError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let pointer = pclient else {
            throw FileRelayError.unknown
        }
        var client = FileRelayClient(rawValue: pointer)
        let result = try body(client)
        try client.free()
        return result
    }
    
    var rawValue: file_relay_client_t?

    init(rawValue: file_relay_client_t) {
        self.rawValue = rawValue
    }
    
    public init(device: Device, service: LockdownService) throws {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        guard let service = service.rawValue else {
            throw LockdownError.notStartService
        }
        
        var fileRelay: file_relay_client_t? = nil
        let rawError = file_relay_client_new(device, service, &fileRelay)
        if let error = FileRelayError(rawValue: rawError.rawValue) {
            throw error
        }
        self.rawValue = fileRelay
    }
    
    public func requestSources(sources: [FileRelayRequestSource], timeout: UInt32? = nil) throws -> DeviceConnection {
        guard let rawValue = self.rawValue else {
            throw FileRelayError.deallocatedClient
        }

        let buffer = UnsafeMutableBufferPointer<UnsafePointer<Int8>?>.allocate(capacity: sources.count + 1)
        defer { buffer.deallocate() }
        for (i, source) in sources.enumerated() {
            buffer[i] = source.rawValue.unsafePointer()
        }
        buffer[sources.count] = nil
        
        var connection = DeviceConnection()
        let rawError: file_relay_error_t
        if let timeout = timeout {
            rawError = file_relay_request_sources_timeout(rawValue, buffer.baseAddress, &connection.rawValue, timeout)
        } else {
            rawError = file_relay_request_sources(rawValue,  buffer.baseAddress,&connection.rawValue)
        }
        buffer.forEach { $0?.deallocate() }
         
        if let error = FileRelayError(rawValue: rawError.rawValue) {
            throw error
        }
        
        return connection
    }
    
    public mutating func free() throws {
        guard let rawValue = self.rawValue else {
            return
        }
        let rawError = file_relay_client_free(rawValue)
        if let error = FileRelayError(rawValue: rawError.rawValue) {
            throw error
        }
        self.rawValue = nil
    }
}
