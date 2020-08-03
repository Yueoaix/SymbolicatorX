//
//  InstallViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/8/3.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class InstallViewController: BaseViewController {
    
    private let installFilePath = "PublicStaging/com.zhongxiaoyue.SymbolicatorX"
    
    private let devicePopBtn = NSPopUpButton()
    private let progressIndicator = NSProgressIndicator()
    private var installBtn: NSButton!
    private var backBtn: NSButton!
    private let ipaFileDropZoneView = DropZoneView(fileTypes: [".ipa"], text: "Drop App IPA")

    private var deviceList = [Device]()
    private var deviceDisposable: Disposable?
    private var installDisposable: Disposable?
    private var fileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        setupUI()
        deviceEventSubscribe()
    }
    
    deinit {
        deviceList.forEach { ( device) in
            var device = device
            device.free()
        }
        _ = MobileDevice.eventUnsubscribe()
        deviceDisposable?.dispose()
        installDisposable?.dispose()
    }
    
}

// MARK: - Action
extension InstallViewController {
    
    @objc private func didClickInstallBtn() {
        
        guard let fileURL = fileURL else {
            view.window?.alert(message: "No IPA File")
            return
        }
        
        let device = self.deviceList[devicePopBtn.indexOfSelectedItem]
        progressIndicator.doubleValue = 0
        progressIndicator.isHidden = false
        backBtn.isEnabled = false
        installBtn.isEnabled = false
        
        DispatchQueue.global().async {
            do {
                
                var lockdownClient = try LockdownClient(device: device, withHandshake: true)
                var lockdownService = try lockdownClient.getService(service: .afc)
                var afcClient = try AfcClient(device: device, service: lockdownService)
                try? afcClient.removeFile(path: self.installFilePath)
                if (try? afcClient.getFileInfo(path: "PublicStaging")) != nil {
                    try afcClient.makeDirectory(path: "PublicStaging")
                }
                let handle = try afcClient.fileOpen(filename: self.installFilePath, fileMode: .wrOnly)
                try afcClient.fileWrite(handle: handle, fileURL: fileURL)
                try afcClient.fileClose(handle: handle)
                
                lockdownService.free()
                lockdownService = try lockdownClient.getService(service: .installationProxy)
                var install = try InstallationProxy(device: device, service: lockdownService)
                self.installDisposable?.dispose()
                self.installDisposable = try install.install(pkgPath: self.installFilePath, options: nil) { [weak self] (command, status) in
                    
                    guard let statusStr = status?["Status"]?.string else { return }
                    let percent = status?["PercentComplete"]?.uint ?? 0
                    let percentf = Double(percent)
                    
                    DispatchQueue.main.async {
                        self?.progressIndicator.doubleValue = percentf
                        if statusStr == "Complete" {
                            self?.progressIndicator.doubleValue = 100
                            self?.progressIndicator.isHidden = true
                            self?.backBtn.isEnabled = true
                            self?.installBtn.isEnabled = true
                            afcClient.free()
                            install.free()
                        }
                    }
                }
                lockdownClient.free()
            } catch {
                DispatchQueue.main.async {
                    self.progressIndicator.isHidden = true
                    self.backBtn.isEnabled = true
                    self.installBtn.isEnabled = true
                }
                print(error)
            }
        }
        
    }
    
    @objc private func didClickBackBtn() {
        
        guard
            let window = view.window,
            let parent = window.parent
        else { return }
        
        parent.endSheet(window)
    }
    
    @objc private func didChangeDevice(_ sender: NSPopUpButton) {
        
    }
    
}

// MARK: - Install
extension InstallViewController {
    
    private func deviceEventSubscribe() {
        
        do {
            deviceDisposable = try MobileDevice.eventSubscribe { [weak self] (event) in
                
                guard
                    let `self` = self,
                    let udid = event.udid,
                    let type = event.type,
                    let connectionType = event.connectionType
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
            view.window?.alert(message: error.localizedDescription)
        }
    }
    
    private func addDevice(udid: String, connectionType: ConnectionType) {
        
        var option: DeviceLookupOptions = .usbmux
        if connectionType == .network { option = .network }
        
        DispatchQueue.main.async {
            do {
                var device = try Device(udid: udid, options: option)
                var lockdownClient = try LockdownClient(device: device, withHandshake: false)
                let deviceName = try lockdownClient.getName()
                device.name = deviceName
                self.deviceList.append(device)
                self.devicePopBtn.addItem(withTitle: deviceName)
                lockdownClient.free()
            } catch {
                self.view.window?.alert(message: error.localizedDescription)
            }
        }
    }
    
    private func removeDevice(udid: String) {
        
        DispatchQueue.main.async {
            
            self.deviceList.removeAll { (device) -> Bool in
                var device = device
                let deviceUDID = try? device.getUDID()
                if deviceUDID == udid {
                    
                    let deviceName = device.name ?? ""
                    self.devicePopBtn.removeItem(withTitle: deviceName)
                    device.free()
                    return true
                }
                return false
            }
            
        }
    }
    
}

// MARK: - DropZoneViewDelegate
extension InstallViewController: DropZoneViewDelegate {
    
    func receivedFile(dropZoneView: DropZoneView, fileURL: URL) {
        self.fileURL = fileURL
    }
}

// MARK: - UI
extension InstallViewController {
    
    private func setupUI() {
        
        installBtn = NSButton.makeButton(title: "Install", target: self, action: #selector(didClickInstallBtn))
        view.addSubview(installBtn)
        installBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(10)
        }
        
        backBtn = NSButton.makeButton(title: "Back", target: self, action: #selector(didClickBackBtn))
        view.addSubview(backBtn)
        backBtn.snp.makeConstraints { (make) in
            make.right.equalTo(installBtn.snp.left).offset(-10)
            make.top.equalTo(installBtn)
        }
        
        devicePopBtn.target = self
        devicePopBtn.action = #selector(didChangeDevice(_:))
        devicePopBtn.focusRingType = .none
        view.addSubview(devicePopBtn)
        devicePopBtn.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(10)
            make.width.equalTo(120)
        }
        
        ipaFileDropZoneView.translatesAutoresizingMaskIntoConstraints = false
        ipaFileDropZoneView.delegate = self
        view.addSubview(ipaFileDropZoneView)
        ipaFileDropZoneView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(backBtn.snp.bottom).offset(10)
            make.width.equalTo(260)
            make.height.equalTo(210)
        }
        
        progressIndicator.isDisplayedWhenStopped = false
        progressIndicator.isIndeterminate = false
        progressIndicator.style = .bar
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 100
        progressIndicator.isHidden = true
        view.addSubview(progressIndicator)
        progressIndicator.snp.makeConstraints { (make) in
            make.left.equalTo(devicePopBtn)
            make.right.equalTo(installBtn)
            make.top.equalTo(devicePopBtn.snp.bottom).offset(-3)
        }
    }
}
