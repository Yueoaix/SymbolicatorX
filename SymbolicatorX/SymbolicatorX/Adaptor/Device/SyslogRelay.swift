//
//  SyslogRelay.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


public enum SyslogRelayError: Int32, Error {
    case invalidArgument = -1
    case muxError = -2
    case sslError = -3
    case notEnoughData = -4
    case timeout = -5
    case unknown = -256
}

public struct SyslogReceivedData: CustomStringConvertible {
    public fileprivate(set) var message: String
    public let date: Date
    public let name: String
    public let processInfo: String
    
    public var description: String {
        return "\(dateFormatter.string(from: date)) \(name) \(processInfo) \(message)"
    }
}

public struct SyslogRelayClient {
    
    public static func startService<T>(device: Device, label: String, body: (SyslogRelayClient) throws -> T) throws -> T {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        
        var pclient: syslog_relay_client_t? = nil
        let rawError = syslog_relay_client_start_service(device, &pclient, label)
        if let error = SyslogRelayError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let pointer = pclient else {
            throw SyslogRelayError.unknown
        }
        var client = SyslogRelayClient(rawValue: pointer)
        let result = try body(client)
        client.free()
        return result
    }
    
    private var rawValue: syslog_relay_client_t?
    
    init(rawValue: syslog_relay_client_t) {
        self.rawValue = rawValue
    }
    
    public init(device: Device, service: LockdownService) throws {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        guard let service = service.rawValue else {
            throw LockdownError.notStartService
        }
        
        var syslogRelay: syslog_relay_client_t? = nil
        let rawError = syslog_relay_client_new(device, service, &syslogRelay)
        if let error = SyslogRelayError(rawValue: rawError.rawValue) {
            throw error
        }
        self.rawValue = syslogRelay
    }
    
    public func startCapture(callback: @escaping (Int8) -> Void) throws -> Disposable {
        let p = Unmanaged.passRetained(Wrapper(value: callback))
        
        let rawError = syslog_relay_start_capture(rawValue, { (character, userData) in
            guard let userData = userData else {
                return
            }
            
            let action = Unmanaged<Wrapper<(Int8) -> Void>>.fromOpaque(userData).takeUnretainedValue().value
            action(character)
        }, p.toOpaque())
        
        if let error = SyslogRelayError(rawValue: rawError.rawValue) {
            throw error
        }
        
        return Dispose {
            p.release()
        }
    }
    
    public func stopCapture() throws {
        let rawError = syslog_relay_stop_capture(rawValue)
        if let error = SyslogRelayError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func receive(timeout: UInt32? = nil) throws -> String {
        let data = UnsafeMutablePointer<Int8>.allocate(capacity: Int.max)
        var received: UInt32 = 0
        let rawError: syslog_relay_error_t
        if let timeout = timeout {
            rawError = syslog_relay_receive_with_timeout(rawValue, data, UInt32(Int.max), &received, timeout)
        } else {
            rawError = syslog_relay_receive(rawValue, data, UInt32(Int.max), &received)
        }
        
        if let error = SyslogRelayError(rawValue: rawError.rawValue) {
            throw error
        }
        
        return String(cString: data)
    }
    
    public mutating func free() {
        guard let rawValue = self.rawValue else {
            return
        }
        syslog_relay_client_free(rawValue)
        self.rawValue = nil
    }
}

public extension SyslogRelayClient {
    func startCaptureMessage(callback: @escaping (SyslogReceivedData) -> Void) throws -> Disposable {
        var buffer: [Int8] = []
        var previousMessage: SyslogReceivedData?
        return try startCapture { (character) in
            buffer.append(character)
            
            guard character == 10 else {
                return
            }
            
            let lineString = String(cString: buffer + [0])
            buffer = []
            guard let data = tryParseMessage(message: lineString) else {
                previousMessage?.message += lineString
                return
            }
            guard let message = previousMessage else {
                previousMessage = data
                return
            }
            previousMessage = data
            callback(message)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM dd HH:mm:ss"
    return formatter
}()

private func tryParseMessage(message: String) -> SyslogReceivedData? {
    let data = message.split(separator: " ")
    guard data.count > 5 else {
        return nil
    }
    let dateString = data[0..<3].joined(separator: " ")
    guard let date = dateFormatter.date(from: dateString) else {
        return nil
    }
    let name = data[3]
    let processInfo = data[4]

    return SyslogReceivedData(
        message: String(data[5...].joined(separator: " ")),
        date: date,
        name: String(name),
        processInfo: String(processInfo)
    )
}

