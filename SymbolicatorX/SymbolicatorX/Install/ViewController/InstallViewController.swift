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
    
    private let devicePopBtn = DevicePopUpButton()
    private let progressIndicator = NSProgressIndicator()
    private var installBtn: NSButton!
    private var backBtn: NSButton!
    private let ipaFileDropZoneView = DropZoneView(fileTypes: [".ipa"], text: "Drop App IPA")

    private var disposable: Disposable?
    private var IPAFileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        setupUI()
    }
    
    deinit {
        disposable?.dispose()
    }
    
}

// MARK: - Action
extension InstallViewController {
    
    @objc private func didClickInstallBtn() {
        
        guard let IPAFileURL = IPAFileURL else {
            view.window?.alert(message: "No IPA File")
            return
        }
        
        guard
            let device = devicePopBtn.getSelecteDevice()
        else {
            view.window?.alert(message: "No Selected Device")
            return
        }
        
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
                try afcClient.fileWrite(handle: handle, fileURL: IPAFileURL, progressHandler: { [weak self] (progress) in
                    DispatchQueue.main.async {
                        self?.progressIndicator.doubleValue = progress * 100 * 0.5;
                    }
                })
                try afcClient.fileClose(handle: handle)
                
                lockdownClient.free()
                lockdownClient = try LockdownClient(device: device, withHandshake: true)
                lockdownService.free()
                lockdownService = try lockdownClient.getService(service: .installationProxy)
                var install = try InstallationProxy(device: device, service: lockdownService)
                self.disposable?.dispose()
                self.disposable = try install.install(pkgPath: self.installFilePath, options: nil) { [weak self] (command, status) in
                    
                    let statusStr = status?["Status"]?.string ?? ""
                    let errorStr = status?["Error"]?.string
                    let percent = status?["PercentComplete"]?.uint ?? 0
                    let percentf = Double(percent)
                    
                    DispatchQueue.main.async {
                        self?.progressIndicator.doubleValue = 50 + (percentf * 0.5)
                        if statusStr == "Complete" {
                            stopInstall()
                            afcClient.free()
                            install.free()
                        } else if let error = errorStr {
                            stopInstall()
                            afcClient.free()
                            install.free()
                            self?.view.window?.alert(message: error)
                        }
                    }
                }
                lockdownClient.free()
            } catch {
                DispatchQueue.main.async {
                    self.progressIndicator.isHidden = true
                    self.backBtn.isEnabled = true
                    self.installBtn.isEnabled = true
                    self.view.window?.alert(message: error.localizedDescription)
                }
                print(error)
            }
        }
        
        func stopInstall() {
            progressIndicator.isHidden = true
            backBtn.isEnabled = true
            installBtn.isEnabled = true
        }
    }
    
    @objc private func didClickBackBtn() {
        
        guard
            let window = view.window,
            let parent = window.sheetParent
        else { return }
        
        parent.endSheet(window)
    }
    
    @objc private func didChangeDevice(_ sender: NSPopUpButton) {
        
    }
    
}

// MARK: - DropZoneViewDelegate
extension InstallViewController: DropZoneViewDelegate {
    
    func receivedFile(dropZoneView: DropZoneView, fileURL: URL) {
        self.IPAFileURL = fileURL
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
