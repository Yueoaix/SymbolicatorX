//
//  DeviceConnection.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


public struct DeviceConnection {
    
    var rawValue: idevice_connection_t?
    
    init(rawValue: idevice_connection_t) {
        self.rawValue = rawValue
    }

    init() {
        self.rawValue = nil
    }
    
    public func send(data: Data) throws -> UInt32 {
        guard let rawValue = self.rawValue else {
            throw MobileDeviceError.disconnected
        }

        return try data.withUnsafeBytes { (pdata) -> UInt32 in
            
            var sentBytes: UInt32 = 0
            
            let pdata = pdata.baseAddress?.bindMemory(to: Int8.self, capacity: data.count)
            let rawError = idevice_connection_send(rawValue, pdata, UInt32(data.count), &sentBytes)
            if let error = MobileDeviceError(rawValue: rawError.rawValue) {
                throw error
            }
            
            return sentBytes
        }
    }
    
    public func receive(timeout: UInt32? = nil, length: UInt32) throws -> (Data, UInt32) {
        guard let rawValue = self.rawValue else {
            throw MobileDeviceError.disconnected
        }
        
        let pdata = UnsafeMutablePointer<Int8>.allocate(capacity: Int(length))
        
        defer { pdata.deallocate() }
        let rawError: idevice_error_t
        var receivedBytes: UInt32 = 0
        if let timeout = timeout {
            rawError = idevice_connection_receive_timeout(rawValue, pdata, length, &receivedBytes, timeout)
        } else {
            rawError = idevice_connection_receive(rawValue, pdata, length, &receivedBytes)
        }
        
        if let error = MobileDeviceError(rawValue: rawError.rawValue) {
            throw error
        }

        return (Data(bytes: pdata, count: Int(receivedBytes)), receivedBytes)
    }
    
    public func setSSL(enable: Bool) throws {
        guard let rawValue = self.rawValue else {
            throw MobileDeviceError.disconnected
        }
        if enable {
            idevice_connection_enable_ssl(rawValue)
        } else {
            idevice_connection_disable_ssl(rawValue)
        }
    }
    
    public func getFileDescriptor() throws -> Int32 {
        guard let rawValue = self.rawValue else {
            throw MobileDeviceError.disconnected
        }
        var fd: Int32 = 0
        let rawError = idevice_connection_get_fd(rawValue, &fd)
        if let error = MobileDeviceError(rawValue: rawError.rawValue) {
            throw error
        }
        
        return fd
    }
    
    public mutating func free() {
        guard let rawValue = self.rawValue else {
            return
        }
        idevice_disconnect(rawValue)
        self.rawValue = nil
    }
}

public class NativeDeviceConnection {
    private let connection: InternalNativeDeviceConnection
    
    init(sock: Int32) {
        connection = InternalNativeDeviceConnection(sock: sock)
    }
    
    public func start() throws {
        try connection.start()
    }
    
    public func send(data: Data) {
        connection.send(data: data)
    }
    
    public func receive(callback: @escaping (Data) -> Void) {
        connection.outputCallback = callback
    }
}

private let bufferSize = 1024
private class InternalNativeDeviceConnection: NSObject, StreamDelegate {
    
    private let sock: Int32
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    
    var outputCallback: ((Data) -> Void)?
    
    init(sock: Int32) {
        self.sock = sock
    }
    
    func start() throws {
        self.receive()
    }
    
    func receive() {
        while true {
            var buffer = Data()
            var bytes = [CChar](repeating: 0, count: bufferSize)
            while true {

                let recvBytes = recv(sock, &bytes, bufferSize, 0)
                guard recvBytes > -1 else {
                    print("recv error: \(String(errorNumber: errno))")
                    return
                }
                switch recvBytes {
                case 0:
                    return
                case bufferSize:
                    buffer += Data(bytes: &bytes, count: bufferSize)
                    continue
                default:
                    buffer += Data(bytes: &bytes, count: recvBytes)
                    break
                }
                break
            }
            
            self.outputCallback?(buffer)
        }
    }
    
    func send(data: Data) {
        var data = [UInt8](data)
        Darwin.send(sock, &data, data.count, 0)
    }
}

extension String {
    init(errorNumber: Int32) {
        guard let code = POSIXErrorCode(rawValue: errorNumber) else {
            self = "unknown"
            return
        }

        let error = POSIXError(code)
        
        self = "\(error.code.rawValue  ): \(error.localizedDescription)"
    }
}
