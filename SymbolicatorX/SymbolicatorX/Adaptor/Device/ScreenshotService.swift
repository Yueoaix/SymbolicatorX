//
//  ScreenshotService.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


public enum ScreenshotError: Int32, Error {
    case invalidArgument = -1
    case plistError = -2
    case muxError = -3
    case sslError = -4
    case receiveTimeout = -5
    case badVersion = -6
    case unknown = -256
    
    case deallocatedService = 100
}


public struct ScreenshotService {

    static func start<T>(device: Device, label: String, body: (ScreenshotService) throws -> T) throws -> T {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        
        var pscreenshot: screenshotr_client_t? = nil
        var screenshotError = screenshotr_client_start_service(device, &pscreenshot, label)
        
        if let error = ScreenshotError(rawValue: screenshotError.rawValue) {
            throw error
        }
        guard let screenshot = pscreenshot else {
            throw ScreenshotError.unknown
        }
        
        var service = ScreenshotService(rawValue: screenshot)
        defer { service.free() }
        return try body(service)
    }
    
    var rawValue: screenshotr_client_t?
    
    init(rawValue: screenshotr_client_t) {
        self.rawValue = rawValue
    }
    
    init(device: Device, service: LockdownService) throws {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        guard let service = service.rawValue else {
            throw LockdownError.notStartService
        }

        var client: screenshotr_client_t? = nil
        let rawError = screenshotr_client_new(device, service, &client)
        if let error = ScreenshotError(rawValue: rawError.rawValue) {
            throw error
        }
        guard client != nil else {
            throw ScreenshotError.unknown
        }
        self.rawValue = client
    }
    
    public func takeScreenshot() throws -> Data {
        guard let rawValue = self.rawValue else {
            throw ScreenshotError.deallocatedService
        }
        
        var image: UnsafeMutablePointer<Int8>? = nil
        var size: UInt64 = 0
        
        let rawError = screenshotr_take_screenshot(rawValue, &image, &size)
        if let error = ScreenshotError(rawValue: rawError.rawValue) {
            throw error
        }
        
        let buffer = UnsafeBufferPointer(start: image, count: Int(size))
        defer { buffer.deallocate() }

        return Data(buffer: buffer)
    }
    
    public mutating func free() {
        guard let rawValue = self.rawValue else {
            return
        }
        screenshotr_client_free(rawValue)
        self.rawValue = nil
    }
}

