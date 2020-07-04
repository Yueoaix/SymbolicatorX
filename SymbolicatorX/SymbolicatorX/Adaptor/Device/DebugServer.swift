//
//  DebugServer.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


public enum DebugServerError: Int32, Error {
    case invalidArgument = -1
    case muxError = -2
    case sslError = -3
    case responseError = -4
    case unknown = -256
    
    case deallocatedClient = 100
    case deallocatedCommand = 101
}

public struct DebugServerCommand {
    
    var rawValue: debugserver_command_t?
    
    init(rawValue: debugserver_command_t) {
        self.rawValue = rawValue
    }
    
    init(name: String, arguments: [String]) throws {
        let buffer = UnsafeMutableBufferPointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: arguments.count + 1)
        defer { buffer.deallocate() }
        for (i, argument) in arguments.enumerated() {
            buffer[i] = argument.unsafeMutablePointer()
        }

        buffer[arguments.count] = nil
        let rawError = debugserver_command_new(name, Int32(arguments.count), buffer.baseAddress, &rawValue)
        buffer.forEach { $0?.deallocate() }
        if let error = DebugServerError(rawValue: rawError.rawValue) {
            throw error
        }
        guard rawValue == nil else {
            throw DebugServerError.unknown
        }
    }
    
    public mutating func free() {
        guard let rawValue = self.rawValue else {
            return
        }
        debugserver_command_free(rawValue)
        self.rawValue = nil
    }
}

public struct DebugServer {
    static func start<T>(device: Device, label: String, body: (DebugServer) throws -> T) throws -> T {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        
        return try label.withCString({ (label) -> T in
            var pclient: debugserver_client_t? = nil
            let rawError = debugserver_client_start_service(device, &pclient, label)
            if let error = DebugServerError(rawValue: rawError.rawValue) {
                throw error
            }
            guard let client = pclient else {
                throw DebugServerError.unknown
            }
            var server = DebugServer(rawValue: client)
            defer { server.free() }
            
            return try body(server)
        })
    }
    
    public static func encodeString(buffer: String) -> Data {
        buffer.withCString { (buffer) -> Data in
            var pencodedBuffer: UnsafeMutablePointer<Int8>? = nil
            var encodedLength: UInt32 = 0
            debugserver_encode_string(buffer, &pencodedBuffer, &encodedLength)
            guard let encodedBuffer = pencodedBuffer else {
                return Data()
            }
            
            let bufferPointer = UnsafeBufferPointer<Int8>(start: encodedBuffer, count: Int(encodedLength))
            defer { bufferPointer.deallocate() }
            return Data(buffer: bufferPointer)
        }
    }
    
    private var rawValue: debugserver_client_t?

    init(rawValue: debugserver_client_t) {
        self.rawValue = rawValue
    }
    
    init(device: Device, service: LockdownService) throws {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        guard let service = service.rawValue else {
            throw LockdownError.notStartService
        }
        
        var client: debugserver_client_t? = nil
        let rawError = debugserver_client_new(device, service, &client)
        if let error = DebugServerError(rawValue: rawError.rawValue) {
            throw error
        }
        guard client != nil else {
            throw DebugServerError.unknown
        }
        self.rawValue = client
    }
    
    public func send(data: String, size: UInt32) throws -> UInt32 {
        guard let rawValue = self.rawValue else {
            throw DebugServerError.deallocatedClient
        }
        
        return try data.withCString { (data) -> UInt32 in
            var sent: UInt32 = 0
            let rawError = debugserver_client_send(rawValue, data, size, &sent)
            if let error = DebugServerError(rawValue: rawError.rawValue) {
                throw error
            }
            
            return sent
        }
    }
    
    public func receive(size: UInt32, timeout: UInt32? = nil) throws -> (Data, UInt32) {
        guard let rawValue = self.rawValue else {
            throw DebugServerError.deallocatedClient
        }
        
        let data = UnsafeMutablePointer<Int8>.allocate(capacity: 0)
        defer { data.deallocate() }
        var received: UInt32 = 0
        let rawError: debugserver_error_t
        if let timeout = timeout {
            rawError = debugserver_client_receive_with_timeout(rawValue, data, size, &received, timeout)
        } else {
            rawError = debugserver_client_receive(rawValue, data, size, &received)
        }
        
        if let error = DebugServerError(rawValue: rawError.rawValue) {
            throw error
        }
        
        let buffer = UnsafeBufferPointer<Int8>(start: data, count: Int(received))
        defer { buffer.deallocate() }
        return (Data(buffer: buffer), received)
    }
    
    public func sendCommand(command: DebugServerCommand) throws -> Data {
        guard let rawValue = self.rawValue else {
            throw DebugServerError.deallocatedClient
        }
        guard let rawCommand = command.rawValue else {
            throw DebugServerError.deallocatedCommand
        }
        
        var presponse: UnsafeMutablePointer<Int8>? = nil
        var responseSize: Int = 0
        let rawError = debugserver_client_send_command(rawValue, rawCommand, &presponse, &responseSize)
        if let error = DebugServerError(rawValue: rawError.rawValue) {
            throw error
        }
        
        guard let response = presponse else {
            throw DebugServerError.unknown
        }
        
        let buffer = UnsafeBufferPointer<Int8>(start: response, count: responseSize)
        defer { buffer.deallocate() }
        return Data(buffer: buffer)
    }
    
    public func receiveResponse() throws -> Data {
        guard let rawValue = self.rawValue else {
            throw DebugServerError.deallocatedClient
        }
        
        var presponse: UnsafeMutablePointer<Int8>? = nil
        var responseSize: Int = 0
        let rawError = debugserver_client_receive_response(rawValue, &presponse, &responseSize)
        if let error = DebugServerError(rawValue: rawError.rawValue) {
            throw error
        }
        
        guard let response = presponse else {
            throw DebugServerError.unknown
        }
        
        let buffer = UnsafeBufferPointer<Int8>(start: response, count: responseSize)
        defer { buffer.deallocate() }
        return Data(buffer: buffer)
    }
    
    public func setAckMode(enabled: Bool) throws {
        guard let rawValue = self.rawValue else {
            throw DebugServerError.deallocatedClient
        }
        
        let rawError = debugserver_client_set_ack_mode(rawValue, enabled ? 1 : 0)
        if let error = DebugServerError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func setARGV(argv: [String]) throws -> String {
        guard let rawValue = self.rawValue else {
            throw DebugServerError.deallocatedClient
        }
        
        let argc = argv.count
        let buffer = UnsafeMutableBufferPointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: argc + 1)
        defer { buffer.deallocate() }
        for (i, argument) in argv.enumerated() {
            buffer[i] = argument.unsafeMutablePointer()
        }
        buffer[argc] = nil
        var presponse: UnsafeMutablePointer<Int8>? = nil
        let rawError = debugserver_client_set_argv(rawValue, Int32(argc), buffer.baseAddress, &presponse)
        buffer.forEach { $0?.deallocate() }
        if let error = DebugServerError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let response = presponse else {
            throw DebugServerError.unknown
        }
        defer { response.deallocate() }
        
        return String(cString: response)
    }
    
    public func setEnvironmentHexEncoded(env: String) throws -> String {
        guard let rawValue = self.rawValue else {
            throw DebugServerError.deallocatedClient
        }
        
        return try env.withCString { (env) -> String in
            var presponse: UnsafeMutablePointer<Int8>? = nil
            let rawError = debugserver_client_set_environment_hex_encoded(rawValue, env, &presponse)
            if let error = DebugServerError(rawValue: rawError.rawValue) {
                throw error
            }
            guard let response = presponse else {
                throw DebugServerError.unknown
            }
            defer { response.deallocate() }
            
            return String(cString: response)
        }
    }
    
    public mutating func free() {
        guard let rawValue = self.rawValue else {
            return
        }
        debugserver_client_free(rawValue)
        self.rawValue = nil
    }
}

extension DebugServer {

    func receiveAll(timeout: UInt32? = nil) throws -> Data {
        let size: UInt32 = 131072
        var buffer = Data()
        
        while(true) {
            let (data, received) = try receive(size: size, timeout: timeout)
            buffer += data
            if received == 0 {
                break
            }
        }

        return buffer
    }
}
