//
//  DevicePopUpButton.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/8/4.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class DevicePopUpButton: NSPopUpButton {
    
    private var disposable: Disposable?
    private var deviceList = [Device]()
    
    init() {
        super.init(frame: NSRect.zero, pullsDown: false)
        deviceEventSubscribe()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    public func getSelecteDevice() -> Device? {
        
        guard deviceList.count > 0, indexOfSelectedItem < deviceList.count else {
            return nil
        }
        
        return deviceList[indexOfSelectedItem]
    }
    
    deinit {
        deviceList.forEach { ( device) in
            var device = device
            device.free()
        }
        _ = MobileDevice.eventUnsubscribe()
        disposable?.dispose()
    }
}

extension DevicePopUpButton {
    
    private func deviceEventSubscribe() {
        
        do {
            disposable = try MobileDevice.eventSubscribe { [weak self] (event) in
                
                guard
                    let `self` = self,
                    let udid = event.udid,
                    let type = event.type,
                    let connectionType = event.connectionType,
                    connectionType == .usbmuxd
                else {
                    return
                }
                
                let isExist = self.deviceList.count > 0 && self.deviceList.contains { (device) -> Bool in
                    let deviceUDID = try? device.getUDID()
                    return deviceUDID == udid
                }

                switch type {
                    
                case .add:
                    if !isExist {
                        self.addDevice(udid: udid, connectionType: connectionType)
                    }
                case .remove:
                    if isExist {
                        self.removeDevice(udid: udid)
                    }
                case .paired:
                    print("paired udid: \(udid)")
                    break
                }
            }
        } catch {
            window?.alert(message: error.localizedDescription)
        }
    }
    
    private func addDevice(udid: String, connectionType: ConnectionType) {
        
        var option: DeviceLookupOptions = .usbmux
        if connectionType == .network {
            option = .network
        }
        
        DispatchQueue.main.async {
            
            do {
                var device = try Device(udid: udid, options: option)
                var lockdownClient = try LockdownClient(device: device, withHandshake: false)
                let deviceName = try lockdownClient.getName()
                device.name = deviceName
                self.deviceList.append(device)
                self.addItem(withTitle: deviceName)
                if self.deviceList.count == 1, let action = self.action {
                    NSApplication.shared.sendAction(action, to: self.target, from: nil)
                }
                lockdownClient.free()
            } catch {
                self.window?.alert(message: error.localizedDescription)
            }
            
        }
    }
    
    private func removeDevice(udid: String) {
        
        DispatchQueue.main.async {
            
            var isNeedRefresh = false
            self.deviceList.removeAll { (device) -> Bool in
                
                var device = device
                let deviceUDID = try? device.getUDID()
                if deviceUDID == udid {
                    
                    let deviceName = device.name ?? ""
                    if self.selectedItem?.title == deviceName {
                        isNeedRefresh = true
                    }
                    
                    self.removeItem(withTitle: deviceName)
                    device.free()
                    return true
                }
                return false
            }
            
            if isNeedRefresh, let action = self.action {
                NSApplication.shared.sendAction(action, to: self.target, from: nil)
            }

        }
    }
    
}
