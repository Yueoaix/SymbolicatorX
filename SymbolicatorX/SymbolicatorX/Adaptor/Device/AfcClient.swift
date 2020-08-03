//
//  AfcClient.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


public enum AfcError: Error {
    case unknown
    case opHeaderInvalid
    case noResources
    case read
    case write
    case unknownPacketType
    case invalidArg
    case objectNotFound
    case objectIsDir
    case permDenied
    case serviceNotConnected
    case opTimeout
    case tooMuchData
    case endOfData
    case opNotSupported
    case objectExists
    case objectBusy
    case noSpaceLeft
    case opWouldBlock
    case io
    case opInterrupted
    case opInProgress
    case `internal`
    case mux
    case noMem
    case notEnoughData
    case dirNotEmpty
    case forceSignedType
    
    init?(rawValue: Int32) {
        switch rawValue {
        case 1:
            self = .unknown
        case 2:
            self = .opHeaderInvalid
        case 3:
            self = .noResources
        case 4:
            self = .read
        case 5:
            self = .write
        case 6:
            self = .unknownPacketType
        case 7:
            self = .invalidArg
        case 8:
            self = .objectNotFound
        case 9:
            self = .objectIsDir
        case 10:
            self = .permDenied
        case 11:
            self = .serviceNotConnected
        case 12:
            self = .opTimeout
        case 13:
            self = .tooMuchData
        case 14:
            self = .endOfData
        case 15:
            self = .opNotSupported
        case 16:
            self = .objectExists
        case 17:
            self = .objectBusy
        case 18:
            self = .noSpaceLeft
        case 19:
            self = .opWouldBlock
        case 20:
            self = .io
        case 21:
            self = .opInterrupted
        case 22:
            self = .opInProgress
        case 23:
            self = .internal
        case 30:
            self = .mux
        case 31:
            self = .noMem
        case 32:
            self = .notEnoughData
        case 33:
            self = .dirNotEmpty
        case -1:
            self = .forceSignedType
        default:
            return nil
        }
    }
}

public enum AfcFileMode: UInt32 {
    case rdOnly = 0x00000001
    case rw = 0x00000002
    case wrOnly = 0x00000003
    case wr = 0x00000004
    case append = 0x00000005
    case rdAppend = 0x00000006
}

public enum AfcLinkType: UInt32 {
    case hardLink = 1
    case symLink = 2
}

public enum AfcLockOp: UInt32 {
    case sh = 5
    case ex = 6
    case un = 12
}

public struct AfcClient {
    
    public static func startService<T>(device: Device, label: String, body: (AfcClient) throws -> T) throws -> T {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        
        var pclient: afc_client_t? = nil
        let rawError = afc_client_start_service(device, &pclient, label)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let pointer = pclient else {
            throw AfcError.unknown
        }
        var client = AfcClient(rawValue: pointer)
        let result = try body(client)
        client.free()
        return result
    }
    
    private var rawValue: afc_client_t?
    
    init(rawValue: afc_client_t) {
        self.rawValue = rawValue
    }
    
    public init(houseArrest: HouseArrest) throws {
        
        var afc: afc_client_t? = nil
        let rawError = afc_client_new_from_house_arrest_client(houseArrest.rawValue, &afc)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
        
        self.rawValue = afc
    }
    
    public init(device: Device, service: LockdownService) throws {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        guard let service = service.rawValue else {
            throw LockdownError.notStartService
        }
        
        var afc: afc_client_t? = nil
        let rawError = afc_client_new(device, service, &afc)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
        self.rawValue = afc
    }
    
    public func getDeviceInfo() throws -> [String] {
        
        var deviceInformation: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>? = nil
        let rawError = afc_get_device_info(rawValue, &deviceInformation)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
        
        defer { afc_dictionary_free(deviceInformation) }
        
        let idList = String.array(point: deviceInformation)
        
        return idList
    }
    
    public func readDirectory(path: String) throws -> [String] {
        
        var directoryInformation: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>? = nil
        let rawError = afc_read_directory(rawValue, path,  &directoryInformation)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
        
        defer { afc_dictionary_free(directoryInformation) }
        
        let idList = String.array(point: directoryInformation)
        
        return idList
        
    }
    
    public func getFileInfo(path: String) throws -> [String] {
        
        var fileInformation: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>? = nil
        let rawError = afc_get_file_info(rawValue, path, &fileInformation)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
        
        defer { afc_dictionary_free(fileInformation) }
        
        let idList = String.array(point: fileInformation)
        
        return idList
        
    }
    
    public func fileOpen(filename: String, fileMode: AfcFileMode) throws -> UInt64 {
        
        var handle: UInt64 = 0
        
        let rawError = afc_file_open(rawValue, filename, afc_file_mode_t(fileMode.rawValue), &handle)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
        
        return handle
    }
    

    public func fileClose(handle: UInt64) throws {
        
        let rawError = afc_file_close(rawValue, handle)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func fileLock(handle: UInt64, operation: AfcLockOp) throws {
        
        let rawError = afc_file_lock(rawValue, handle, afc_lock_op_t(operation.rawValue))
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func fileRead(handle: UInt64) throws -> Data {
        
        var data = Data()
        let length: UInt32 = 10000
        var result = try fileRead(handle: handle, length: length)
        while result.1 > 0 {
            data += result.0
            result = try fileRead(handle: handle, length: length)
        }
        
        return data
    }
    
    public func fileRead(handle: UInt64, length: UInt32) throws -> (Data, UInt32) {
        
        let pdata = UnsafeMutablePointer<Int8>.allocate(capacity: Int(length))
        defer { pdata.deallocate() }
        
        var bytesRead: UInt32 = 0
        
        let rawError = afc_file_read(rawValue, handle, pdata, length, &bytesRead)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
        
        return (Data(bytes: pdata, count: Int(bytesRead)), bytesRead)
    }
    
    public func fileWrite(handle: UInt64, data: Data) throws ->UInt32 {
        
        return try data.withUnsafeBytes({ (pdata) -> UInt32 in
            
            var bytesWritten: UInt32 = 0
            let pdata = pdata.baseAddress?.bindMemory(to: Int8.self, capacity: data.count)
            let rawError = afc_file_write(rawValue, handle, pdata, UInt32(data.count), &bytesWritten)
            
            if let error = AfcError(rawValue: rawError.rawValue) {
                throw error
            }
            
            return bytesWritten
        })
    }
    
    public func fileWrite(handle: UInt64, fileURL: URL) throws {
        
        let data = try Data(contentsOf: fileURL)
        var total = data.count
        var length = 10000
        var index = 0
        
        repeat{
            
            if total < length { length = total }
            total -= length
            
            let subData = data[index..<(index + length)]
            index = index + length
            _ = try fileWrite(handle: handle, data: subData)
            
        } while total > 0
    }
    
    public func fileSeek(handle: UInt64, offset: Int64, whence: Int32) throws {
        
        let rawError = afc_file_seek(rawValue, handle, offset, whence)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func fileTell(handle: UInt64) throws -> UInt64 {
        
        var position: UInt64 = 0
        
        let rawError = afc_file_tell(rawValue, handle, &position)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
        
        return position
    }
    
    public func fileTruncate(handle: UInt64, newsize: UInt64) throws {
        
        let rawError = afc_file_truncate(rawValue, handle, newsize)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func removeFile(path: String) throws {
        
        let rawError = afc_remove_path(rawValue, path)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func renamePath(from: String, to: String) throws {
        
        let rawError = afc_rename_path(rawValue, from, to)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func makeDirectory(path: String) throws {
        
        let rawError = afc_make_directory(rawValue, path)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func truncate(path: String, newsize: UInt64) throws {
        
        let rawError = afc_truncate(rawValue, path, newsize)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func makeLink(linkType: AfcLinkType, target: String, linkName: String) throws {
        
        let rawError = afc_make_link(rawValue, afc_link_type_t(linkType.rawValue), target, linkName)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func setFileTime(path: String, date: Date) throws {
        
        let rawError = afc_set_file_time(rawValue, path, UInt64(date.timeIntervalSinceReferenceDate))
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func removePathAndContents(path: String) throws {
        
        let rawError = afc_remove_path_and_contents(rawValue, path)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
    }
    
    public func getDeviceInfoKey(key: String) throws -> String? {
        
        var pvalue: UnsafeMutablePointer<Int8>? = nil
        let rawError = afc_get_device_info_key(rawValue, key, &pvalue)
        if let error = AfcError(rawValue: rawError.rawValue) {
            throw error
        }
        
        guard let value = pvalue else {
            return nil
        }
        defer { value.deallocate() }
        return String(cString: value)
    }
    
    public mutating func free() {
        guard let rawValue = self.rawValue else {
            return
        }
        afc_client_free(rawValue)
        self.rawValue = nil
    }
    
}
