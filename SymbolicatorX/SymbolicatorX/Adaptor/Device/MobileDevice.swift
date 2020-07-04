//
//  MobileDevice.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


public enum MobileDeviceError: Int32, Error {
    case invalidArgument = -1
    case unknown = -2
    case noDevice = -3
    case notEnoughData = -4
    case sslError = -5
    case timeout = -6
    
    case deallocatedDevice = 100
    case disconnected = 101
    
    public var localizedDescription: String {
        switch self {
        case .invalidArgument:
            return "invalid argument"
        case .unknown:
            return "unknown"
        case .noDevice:
            return "no device"
        case .notEnoughData:
            return "not enough data"
        case .sslError:
            return "ssl error"
        case .timeout:
            return "timeout"
        case .deallocatedDevice:
            return "deallocated device"
        case .disconnected:
            return "disconnected"
        
        }
    }
}

class Wrapper<T> {
    let value: T
    init(value: T) {
        self.value = value
    }
}

public enum ConnectionType: UInt32 {
    case usbmuxd = 1
    case network = 2
}

public struct DeviceInfo {
    let udid: String
    let connectionType: ConnectionType
}

public protocol Disposable {
    func dispose()
}

struct Dispose: Disposable {
    private let action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    func dispose() {
        self.action()
    }
}

public struct MobileDevice {
    public enum EventType: UInt32 {
        case add = 1
        case remove = 2
        case paired = 3
    }

    public struct Event {
        public let type: EventType?
        public let udid: String?
        public let connectionType: ConnectionType?
    }
    
    private init() {
    }
    
    public static var debug: Bool = false {
        didSet {
            idevice_set_debug_level(debug ? 1 : 0)
        }
    }
    
    public static func eventSubscribe(callback: @escaping (Event) throws -> Void) throws -> Disposable {
       
        let p = Unmanaged.passRetained(Wrapper(value: callback))

        let rawError = idevice_event_subscribe({ (event, userData) in
            guard let userData = userData,
                let rawEvent = event else {
                return
            }

            let action = Unmanaged<Wrapper<(Event) -> Void>>.fromOpaque(userData).takeUnretainedValue().value
            
            let event = Event(
                type: EventType(rawValue: rawEvent.pointee.event.rawValue),
                udid: String(cString: rawEvent.pointee.udid),
                connectionType: ConnectionType(rawValue: rawEvent.pointee.conn_type.rawValue)
            )
            action(event)
        }, p.toOpaque())

        if let error = MobileDeviceError(rawValue: rawError.rawValue) {
            throw error
        }
        
        return Dispose {
            p.release()
        }
    }
    
    public static func eventUnsubscribe() -> MobileDeviceError? {
        let error = idevice_event_unsubscribe()
        return MobileDeviceError(rawValue: error.rawValue)
    }
    
    public static func getDeviceList() throws -> [String] {
        
        var devices: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>? = nil
        var count: Int32 = 0
        let rawError = idevice_get_device_list(&devices, &count)
        if let error = MobileDeviceError(rawValue: rawError.rawValue) {
            throw error
        }
        
        defer { idevice_device_list_free(devices) }

        let bufferPointer = UnsafeMutableBufferPointer<UnsafeMutablePointer<Int8>?>(start: devices, count: Int(count))
        let idList = bufferPointer.compactMap { $0 }.map { String(cString: $0) }
        
        return idList
    }
    
    public static func getDeviceListExtended() throws -> [DeviceInfo] {
        var pdevices: UnsafeMutablePointer<idevice_info_t?>? = nil
        var count: Int32 = 0
        let rawError = idevice_get_device_list_extended(&pdevices, &count)
        if let error = MobileDeviceError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let devices = pdevices else {
            throw MobileDeviceError.unknown
        }
        defer { idevice_device_list_extended_free(devices) }
        
        var list: [DeviceInfo] = []
        for item in UnsafeMutableBufferPointer<idevice_info_t?>(start: devices, count: Int(count)) {
            guard let item = item else {
                continue
            }
            let udid = String(cString: item.pointee.udid)
            guard let connectionType = ConnectionType(rawValue: item.pointee.conn_type.rawValue) else {
                continue
            }
            
            list.append(DeviceInfo(udid: udid, connectionType: connectionType))
        }
        
        return list
    }
}

