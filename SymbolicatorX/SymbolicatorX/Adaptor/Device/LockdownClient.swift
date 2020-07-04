//
//  LockdownClient.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


public enum LockdownError: Error {
    case invalidArgument
    case invalidConfiguration
    case plistError
    case paireingFailed
    case sslError
    case dictError
    case receiveTimeout
    case muxError
    case noRunningSession
    case invalidResponse
    case missingKey
    case missingValue
    case getProhibited
    case setProhibited
    case remoteProhibited
    case immutableValue
    case passwordProtected
    case userDeniedPaireing
    case pairingDialogResponsePending
    case missingHostID
    case invalidHostID
    case sessionActive
    case sessionInactive
    case missingSessionID
    case invalidSessionID
    case missingService
    case invalidService
    case serviceLimit
    case missingPairRecord
    case savePairRecordFailed
    case invalidPairRecord
    case invlidActivationRecord
    case missingActivationRecord
    case serviceProhibited
    case escrowLocked
    case pairingProhibitedOverThisConnection
    case fmipProtected
    case mcProtected
    case mcChallengeRequired
    case unknown
    
    case deallocated
    case notStartService
    
    init?(rawValue: Int32) {
        switch rawValue {
        case 0:
            return nil
        case -1:
            self = .invalidArgument
        case -2:
            self = .invalidConfiguration
        case -3:
            self = .plistError
        case -4:
            self = .paireingFailed
        case -5:
            self = .sslError
        case -6:
            self = .dictError
        case -7:
            self = .receiveTimeout
        case -8:
            self = .muxError
        case -9:
            self = .noRunningSession
        case -10:
            self = .invalidResponse
        case -11:
            self = .missingKey
        case -12:
            self = .missingValue
        case -13:
            self = .getProhibited
        case -14:
            self = .setProhibited
        case -15:
            self = .remoteProhibited
        case -16:
            self = .immutableValue
        case -17:
            self = .passwordProtected
        case -18:
            self = .userDeniedPaireing
        case -19:
            self = .pairingDialogResponsePending
        case -20:
            self = .missingHostID
        case -21:
            self = .invalidHostID
        case -22:
            self = .sessionActive
        case -23:
            self = .sessionInactive
        case -24:
            self = .missingSessionID
        case -25:
            self = .invalidSessionID
        case -26:
            self = .missingService
        case -27:
            self = .invalidService
        case -28:
            self = .serviceLimit
        case -29:
            self = .missingPairRecord
        case -30:
            self = .savePairRecordFailed
        case -31:
            self = .invalidPairRecord
        case -32:
            self = .invlidActivationRecord
        case -33:
            self = .missingActivationRecord
        case -34:
            self = .serviceProhibited
        case -35:
            self = .escrowLocked
        case -36:
            self = .pairingProhibitedOverThisConnection
        case -37:
            self = .fmipProtected
        case -38:
            self = .mcProtected
        case -39:
            self = .mcChallengeRequired
        case -256:
            self = .unknown
        case 100:
            self = .deallocated
        default:
            return nil
        }
    }
}

public struct LockdownService {

    var rawValue: lockdownd_service_descriptor_t?
    
    init(rawValue: lockdownd_service_descriptor_t) {
        self.rawValue = rawValue
    }
    
    public mutating func free() {
        guard let rawValue = self.rawValue else {
            return
        }
        lockdownd_service_descriptor_free(rawValue)
        self.rawValue = nil
    }
}

public struct LockdownClient {
    
    var rawValue: lockdownd_client_t?
    
    public init(device: Device, withHandshake: Bool) throws {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        let uuid = UUID().uuidString
        let rawError: lockdownd_error_t
        var client: lockdownd_client_t? = nil

        if withHandshake {
            rawError = lockdownd_client_new_with_handshake(device, &client, uuid)
        } else {
            rawError = lockdownd_client_new(device, &client, uuid)
        }
         
        if let error = LockdownError(rawValue: rawError.rawValue) {
            throw error
        }
        guard client != nil else {
            throw LockdownError.unknown
        }
        self.rawValue = client
    }
    
    public func getService(identifier: String, withEscroBag: Bool = false) throws -> LockdownService {
        guard let lockdown = self.rawValue else {
            throw LockdownError.deallocated
        }
        
        var pservice: lockdownd_service_descriptor_t? = nil
        let lockdownError: lockdownd_error_t
        if withEscroBag {
            lockdownError = lockdownd_start_service_with_escrow_bag(lockdown, identifier, &pservice)
        } else {
            lockdownError = lockdownd_start_service(lockdown, identifier, &pservice)
        }
        if let error = LockdownError(rawValue: lockdownError.rawValue) {
            throw error
        }
        guard let rawService = pservice else {
            throw LockdownError.unknown
        }
        
        return LockdownService(rawValue: rawService)
    }
    
    public func startService<T>(identifier: String, withEscroBag: Bool = false, body: (LockdownService) throws -> T) throws -> T {
        var service = try getService(identifier: identifier, withEscroBag: withEscroBag)
        defer { service.free() }
        return try body(service)
    }

    public func getQueryType() throws -> String {
        guard let lockdown = self.rawValue else {
            throw LockdownError.deallocated
        }
        
        var ptype: UnsafeMutablePointer<Int8>? = nil
        let rawError = lockdownd_query_type(lockdown, &ptype)
        if let error = LockdownError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let type = ptype else {
            throw LockdownError.unknown
        }
        defer { type.deallocate() }
        
        return String(cString: type)
    }
    
    public func getValue(domain: String?, key: String?) throws -> Plist {
        guard let lockdown = self.rawValue else {
            throw LockdownError.deallocated
        }
        
        var pplist: plist_t? = nil
        let rawError = lockdownd_get_value(lockdown, domain, key, &pplist)
        if let error = LockdownError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let plist = pplist else {
            throw LockdownError.unknown
        }
        
        return Plist(rawValue: plist)
    }
    
    public func setValue(domain: String, key:String, value: Plist) throws {
        guard let lockdown = self.rawValue else {
            throw LockdownError.deallocated
        }
        guard let value = value.rawValue else {
            throw LockdownError.unknown
        }

        let rawError = lockdownd_set_value(lockdown, domain, key, value)
        if let error = LockdownError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func removeValue(domain: String, key: String) throws {
        guard let lockdown = self.rawValue else {
            throw LockdownError.deallocated
        }
        let rawError = lockdownd_remove_value(lockdown, domain, key)
        if let error = LockdownError(rawValue: rawError.rawValue) {
            throw error
        }
    }

    public func getName() throws -> String {
        guard let lockdown = self.rawValue else {
            throw LockdownError.deallocated
        }
        var rawName: UnsafeMutablePointer<Int8>? = nil
        let rawError = lockdownd_get_device_name(lockdown, &rawName)
        if let error = LockdownError(rawValue: rawError.rawValue) {
            throw error
        }
        
        guard let pname = rawName else {
            throw LockdownError.unknown
        }
        
        defer { pname.deallocate() }
        return String(cString: pname)
    }
    
    public func getDeviceUDID() throws -> String {
        guard let lockdown = self.rawValue else {
            throw LockdownError.deallocated
        }
        var pudid: UnsafeMutablePointer<Int8>? = nil
        let rawError =
            lockdownd_get_device_udid(lockdown, &pudid)
        if let error = LockdownError(rawValue: rawError.rawValue) {
            throw error
        }
        
        guard let udid = pudid else {
            throw LockdownError.unknown
        }
        defer { udid.deallocate() }
        return String(cString: udid)
        
    }
    
    public mutating func free() {
        guard let lockdown = self.rawValue else {
            return
        }
        lockdownd_client_free(lockdown)
        self.rawValue = nil
    }
}

public extension LockdownClient {

    func getService(service: AppleServiceIdentifier, withEscroBag: Bool = false) throws -> LockdownService {
        return try getService(identifier: service.rawValue, withEscroBag: withEscroBag)
    }
    
    func startService<T>(service: AppleServiceIdentifier, withEscroBag: Bool = false, body: (LockdownService) throws -> T) throws -> T {
        return try startService(identifier: service.rawValue, withEscroBag: withEscroBag, body: body)
    }
}

