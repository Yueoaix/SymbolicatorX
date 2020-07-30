//
//  InstallationProxy.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation


public enum InstallationProxyError: Int32, Error {
    case invalidArgument = -1
    case plistError = -2
    case connectionFailed = -3
    case operationInProgress = -4
    case operationFailed = -5
    case receiveTimeout = -6
    case alreadyArchived = -7
    case apiInternalError = -8
    case applicationAlreadyInstalled = -9
    case applicationMoveFailed = -10
    case applicationSinfCaptureFailed = -11
    case applicationSandboxFailed = -12
    case applicationVerificationFailed = -13
    case archiveDestructionFailed = -14
    case bundleVerificationFailed = -15
    case carrierBundleCopyFailed = -16
    case carrierBundleDirectoryCreationFailed = -17
    case carrierBundleMissingSupportedSims = -18
    case commCenterNotificationFailed = -19
    case containerCreationFailed = -20
    case containerPownFailed = -21
    case containerRemovableFailed = -22
    case embeddedProfileInstallFailed = -23
    case executableTwiddleFailed = -24
    case existenceCheckFailed = -25
    case installMapUpdateFailed = -26
    case manifestCaptureFailed = -27
    case mapGenerationFailed = -28
    case missingBundleExecutable = -29
    case missingBundleIdentifier = -30
    case missingBundlePath = -31
    case missingContainer = -32
    case notificationFailed = -33
    case packageExtractionFailed = -34
    case packageInspectionFailed = -35
    case packageMoveFailed = -36
    case pathConversionFailed = -37
    case restoreContainerFailed = -38
    case seatbeltProfileRemovableFailed = -39
    case stageCreationFailed = -40
    case symlinkFailed = -41
    case unknownCommand = -42
    case itunesARtworkCaptureFailed = -43
    case itunesMetadataCaptureFailed = -44
    case deviceOSVersionTooLow = -45
    case deviceFamilyNotSupported = -46
    case packagePatchFailed = -47
    case incorrectArchitecture = -48
    case pluginCopyFailed = -49
    case breadcrumbFailed = -50
    case breadcrumbUnlockFailed = -51
    case geojsonCaputreFailed = -52
    case newsstandArtworkCaputureFailed = -53
    case missingCommand = -54
    case notEntitled = -55
    case missingPackagePath = -56
    case missingContainerPath = -57
    case missingApplicationIdentifier = -58
    case missingAttributeValue = -59
    case lookupFailed = -60
    case dictionaryCreationFailed = -61
    case installProhibited = -62
    case uninstallProhibited = -63
    case missingBUndleVersion = -64
    case unknown = -256
    
    case deallocatedClient = 100
}

public struct InstallationProxyStatusError {
    public let name: String?
    public let description: String?
    public let code: UInt64
}

public enum InstallationProxyClientOptionsKey {
    case skipUninstall(Bool)
    case applicationSinf(Plist)
    case itunesMetadata(Plist)
    case returnAttributes(Plist)
    case applicationType(ApplicationType)
}

public enum ApplicationType: String {
    case system = "System"
    case user = "User"
    case any = "Any"
    case `internal` = "Internal"
}

extension InstallationProxyClientOptionsKey {
    public var key: String {
        switch self {
        case .skipUninstall:
            return "SkipUninstall"
        case .applicationSinf:
            return "ApplicationSINF"
        case .itunesMetadata:
            return "iTunesMetadata"
        case .returnAttributes:
            return "ReturnAttributes"
        case .applicationType:
            return "ApplicationType"
        }
    }
}

public struct InstallationProxyOptions {
    
    var rawValue: plist_t?
    
    init() {
        self.rawValue = instproxy_client_options_new()
    }
    
    public func add(arguments: InstallationProxyClientOptionsKey...) {
        guard let rawValue = self.rawValue else {
            return
        }
        
        for argument in arguments {
            switch argument {
            case .skipUninstall(let bool):
                plist_dict_set_item(rawValue, argument.key, plist_new_bool(bool ? 1 : 0))
            case .applicationSinf(let plist),
                 .itunesMetadata(let plist),
                 .returnAttributes(let plist):
                plist_dict_set_item(rawValue, argument.key, plist_copy(plist.rawValue))
            case .applicationType(let type):
                plist_dict_set_item(rawValue, argument.key, plist_new_string(type.rawValue))
            }
        }
    }
    
    public func setReturnAttributes(arguments: String...) {
        guard let rawValue = self.rawValue else {
            return
        }
        let returnAttributes = plist_new_array()
        for argument in arguments {
            plist_array_append_item(returnAttributes, plist_new_string(argument))
        }
        
        plist_dict_set_item(rawValue, "ReturnAttributes", returnAttributes)
    }
    
    public mutating func free() {
        guard let rawValue = self.rawValue else {
            return
        }
        instproxy_client_options_free(rawValue)
        self.rawValue = nil
    }
}

public struct InstallationProxy {
    
    static func start<T>(device: Device, label: String, action: (InstallationProxy) throws -> T) throws -> T {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        var ipc: instproxy_client_t? = nil
        let rawError = instproxy_client_start_service(device, &ipc, label)
        if let error = LockdownError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let client = ipc else {
            throw InstallationProxyError.unknown
        }
        
        var proxy = InstallationProxy(rawValue: client)
        defer { proxy.free() }
        
        return try action(InstallationProxy(rawValue: client))
    }
    
    public static func commandGetName(command: Plist) -> String? {
        var pname: UnsafeMutablePointer<Int8>? = nil
        instproxy_command_get_name(command.rawValue, &pname)
        
        guard let name = pname else {
            return nil
        }
        defer { name.deallocate() }
        return String(cString: name)
    }
    
    public static func statusGetName(status: Plist) -> String? {
        var pname: UnsafeMutablePointer<Int8>? = nil
        instproxy_status_get_name(status.rawValue, &pname)
        
        guard let name = pname else {
            return nil
        }
        defer { name.deallocate() }
        return String(cString: name)
    }
    
    public static func statusGetError(status: Plist) -> InstallationProxyStatusError? {
        var pname: UnsafeMutablePointer<Int8>? = nil
        var pdescription: UnsafeMutablePointer<Int8>? = nil
        var pcode: UInt64 = 0
        let rawError = instproxy_status_get_error(status.rawValue, &pname, &pdescription, &pcode)
        guard InstallationProxyError(rawValue: rawError.rawValue) != nil else {
            return nil
        }

        var name: String? = nil
        var description: String? = nil

        if let namePointer = pname {
            defer { namePointer.deallocate() }
            name = String(cString: namePointer)
        }
        if let descriptionPointer = pdescription {
            defer { descriptionPointer.deallocate() }
            description = String(cString: descriptionPointer)
        }
        
        return InstallationProxyStatusError(name: name, description: description, code: pcode)
    }
    
    public static func statusGetCurrentList(status: Plist) {
        // TODO
    }
    
    public static func statusGetPercentComplete(status: Plist) -> Int32 {
        var percent: Int32 = 0
        instproxy_status_get_percent_complete(status.rawValue, &percent)
        
        return percent
    }
    
    private var rawValue: instproxy_client_t?
    
    init(rawValue: instproxy_client_t) {
        self.rawValue = rawValue
    }
    
    init(device: Device, service: LockdownService) throws {
        guard let device = device.rawValue else {
            throw MobileDeviceError.deallocatedDevice
        }
        guard let service = service.rawValue else {
            throw LockdownError.notStartService
        }
        
        var client: instproxy_client_t? = nil
        let rawError = instproxy_client_new(device, service, &client)
        if let error = LockdownError(rawValue: rawError.rawValue) {
            throw error
        }
        guard client != nil else {
            throw InstallationProxyError.unknown
        }
        
        self.rawValue = client
    }
    
    public func browse(options: Plist) throws -> Plist {
        guard let rawValue = self.rawValue else {
            throw InstallationProxyError.deallocatedClient
        }
        
        var presult: plist_t? = nil
        let rawError = instproxy_browse(rawValue, options.rawValue, &presult)
        if let error = InstallationProxyError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let result = presult else {
            throw InstallationProxyError.unknown
        }
        
        return Plist(rawValue: result)
    }
    
    public func browse(options: Plist, callback: @escaping (Plist?, Plist?) -> Void) throws -> Disposable {
        guard let rawValue = self.rawValue else {
            throw InstallationProxyError.deallocatedClient
        }
        
        let userData = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.passRetained(Wrapper(value: callback))
        
        let rawError = instproxy_browse_with_callback(rawValue, options.rawValue, { (command, status, userData) in
            guard let userData = userData else {
                return
            }
            let pointer = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.fromOpaque(userData)
            let callback = pointer.takeUnretainedValue().value
            callback(Plist(nillableValue: command), Plist(nillableValue: status))
            pointer.release()
        }, userData.toOpaque())
        
        if let error = InstallationProxyError(rawValue: rawError.rawValue) {
            userData.release()
            throw error
        }
        
        return Dispose {
            userData.release()
        }
    }

    public func lookup(appIDs: [String]?, options: Plist) throws -> Plist {
        guard let rawValue = self.rawValue else {
            throw InstallationProxyError.deallocatedClient
        }
        
        let buffer: UnsafeMutableBufferPointer<UnsafePointer<Int8>?>?
        defer { buffer?.deallocate() }

        _ = appIDs?.map { $0.utf8CString }
        
        if let appIDs = appIDs {
            let pbuffer = UnsafeMutableBufferPointer<UnsafePointer<Int8>?>.allocate(capacity: appIDs.count + 1)
            for (i, id) in appIDs.enumerated() {
                pbuffer[i] = id.unsafePointer()
            }
            pbuffer[appIDs.count] = nil
            buffer = pbuffer
            
        } else {
            buffer = nil
        }
        
        var presult: plist_t? = nil
        let rawError = instproxy_lookup(rawValue, buffer?.baseAddress, options.rawValue, &presult)
    
        buffer?.forEach { $0?.deallocate() }
        
        if let error = InstallationProxyError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let result = presult else {
            throw InstallationProxyError.unknown
        }
        
        return Plist(rawValue: result)
    }
    
    public func install(pkgPath: String, options: Plist?, callback: @escaping (Plist?, Plist?) -> Void) throws -> Disposable {
        guard let rawValue = self.rawValue else {
            throw InstallationProxyError.deallocatedClient
        }
        
        let userData = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.passRetained(Wrapper(value: callback))
        let rawError = instproxy_install(rawValue, pkgPath, options?.rawValue, { (command, status, userData) in
            guard let userData = userData else {
                return
            }
            
            let wrapper = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.fromOpaque(userData)
            let callback = wrapper.takeUnretainedValue().value
            callback(Plist(nillableValue: command), Plist(nillableValue: status))
        }, userData.toOpaque())
        if let error = InstallationProxyError(rawValue: rawError.rawValue) {
            userData.release()
            throw error
        }
        
        return Dispose {
            userData.release()
        }
    }
    
    public func upgrade(pkgPath: String, options: Plist, callback: @escaping (Plist?, Plist?) -> Void) throws -> Disposable {
        guard let rawValue = self.rawValue else {
            throw InstallationProxyError.deallocatedClient
        }
        
        let userData = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.passRetained(Wrapper(value: callback))
        let rawError = instproxy_upgrade(rawValue, pkgPath, options.rawValue, { (command, status, userData) in
            guard let userData = userData else {
                return
            }
            
            let wrapper = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.fromOpaque(userData)
            let callback = wrapper.takeUnretainedValue().value
            callback(Plist(nillableValue: command), Plist(nillableValue: status))
        }, userData.toOpaque())
        if let error = InstallationProxyError(rawValue: rawError.rawValue) {
            userData.release()
            throw error
        }
        
        return Dispose {
            userData.release()
        }
    }
    
    public func uninstall(appID: String, options: Plist, callback: @escaping (Plist?, Plist?) -> Void) throws -> Disposable {
        guard let rawValue = self.rawValue else {
            throw InstallationProxyError.deallocatedClient
        }
        
        let userData = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.passRetained(Wrapper(value: callback))
        let rawError = instproxy_uninstall(rawValue, appID, options.rawValue, { (command, status, userData) in
            guard let userData = userData else {
                return
            }
            
            let wrapper = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.fromOpaque(userData)
            let callback = wrapper.takeUnretainedValue().value
            callback(Plist(nillableValue: command), Plist(nillableValue: status))
        }, userData.toOpaque())
        if let error = InstallationProxyError(rawValue: rawError.rawValue) {
            userData.release()
            throw error
        }
        
        return Dispose {
            userData.release()
        }
    }
    
    public func lookupArchives(options: Plist) throws -> Plist {
        guard let rawValue = self.rawValue else {
            throw InstallationProxyError.deallocatedClient
        }
        
        var presult: plist_t? = nil
        let rawError = instproxy_lookup_archives(rawValue, options.rawValue, &presult)
        if let error = InstallationProxyError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let result = presult else {
            throw InstallationProxyError.unknown
        }
        
        return Plist(rawValue: result)
    }
    
    public func archive(appID: String, options: Plist, callback: @escaping (Plist?, Plist?) -> Void) throws -> Disposable {
        guard let rawValue = self.rawValue else {
            throw InstallationProxyError.deallocatedClient
        }
        
        let userData = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.passRetained(Wrapper(value: callback))
        let rawError = instproxy_archive(rawValue, appID, options.rawValue, { (command, status, userData) in
            guard let userData = userData else {
                return
            }
            
            let wrapper = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.fromOpaque(userData)
            let callback = wrapper.takeUnretainedValue().value
            callback(Plist(nillableValue: command), Plist(nillableValue: status))
        }, userData.toOpaque())
        if let error = InstallationProxyError(rawValue: rawError.rawValue) {
            userData.release()
            throw error
        }
        
        return Dispose {
            userData.release()
        }
    }
    
    public func restore(appID: String, options: Plist, callback: @escaping (Plist?, Plist?) -> Void) throws -> Disposable {
        guard let rawValue = self.rawValue else {
            throw InstallationProxyError.deallocatedClient
        }
        
        let userData = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.passRetained(Wrapper(value: callback))
        let rawError = instproxy_restore(rawValue, appID, options.rawValue, { (command, status, userData) in
            guard let userData = userData else {
                return
            }
            
            let wrapper = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.fromOpaque(userData)
            let callback = wrapper.takeUnretainedValue().value
            callback(Plist(nillableValue: command), Plist(nillableValue: status))
        }, userData.toOpaque())
        if let error = InstallationProxyError(rawValue: rawError.rawValue) {
            userData.release()
            throw error
        }
        
        return Dispose {
            userData.release()
        }
    }
    
    public func removeArchive(appID: String, options: Plist, callback: @escaping (Plist?, Plist?) -> Void) throws -> Disposable {
        guard let rawValue = self.rawValue else {
            throw InstallationProxyError.deallocatedClient
        }
        
        let userData = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.passRetained(Wrapper(value: callback))
        let rawError = instproxy_remove_archive(rawValue, appID, options.rawValue, { (command, status, userData) in
            guard let userData = userData else {
                return
            }
            
            let wrapper = Unmanaged<Wrapper<(Plist?, Plist?) -> Void>>.fromOpaque(userData)
            let callback = wrapper.takeUnretainedValue().value
            callback(Plist(nillableValue: command), Plist(nillableValue: status))
        }, userData.toOpaque())
        if let error = InstallationProxyError(rawValue: rawError.rawValue) {
            userData.release()
            throw error
        }
        
        return Dispose {
            userData.release()
        }
    }
    
    public func checkCapabilitiesMatch(capabilities: [String], options: Plist, result: Plist) throws -> Plist {
        guard let rawValue = self.rawValue else {
            throw InstallationProxyError.deallocatedClient
        }

        let buffer = UnsafeMutableBufferPointer<UnsafePointer<Int8>?>.allocate(capacity: capabilities.count + 1)
        defer { buffer.deallocate() }
        for (i, capability) in capabilities.enumerated() {
            buffer[i] = capability.unsafePointer()
        }
        buffer[capabilities.count] = nil
        
        var presult: plist_t? = nil
        let rawError = instproxy_check_capabilities_match(rawValue, buffer.baseAddress, options.rawValue, &presult)
        buffer.forEach { $0?.deallocate() }
        if let error = InstallationProxyError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let result = presult else {
            throw InstallationProxyError.unknown
        }

        return Plist(rawValue: result)
    }
    
    public func getPath(for bundleIdentifier: String) throws -> String {
        guard let rawValue = self.rawValue else {
            throw InstallationProxyError.deallocatedClient
        }
        var ppath: UnsafeMutablePointer<Int8>? = nil
        let rawError = instproxy_client_get_path_for_bundle_identifier(rawValue, bundleIdentifier, &ppath)
        if let error = InstallationProxyError(rawValue: rawError.rawValue) {
            throw error
        }
        guard let path = ppath else {
            throw InstallationProxyError.unknown
        }
        defer { path.deallocate() }
        
        return String(cString: path)
    }
    
    public mutating func free() {
        guard let rawValue = self.rawValue else {
            return
        }
        
        instproxy_client_free(rawValue)
        self.rawValue = nil
    }
}

