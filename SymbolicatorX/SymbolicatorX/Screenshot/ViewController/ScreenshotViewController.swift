//
//  ScreenshotViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/10/30.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class ScreenshotViewController: BaseViewController {
    
    private let devicePopBtn = DevicePopUpButton()
    
    private let screenImageView = NSImageView()
    private var exportBtn: NSButton!
    private var refreshBtn: NSButton!
    private var backBtn: NSButton!
    
    private var screenData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        setupUI()
    }
    
}

// MARK: - Action
extension ScreenshotViewController {
    
    @objc private func didClickExportBtn() {
        
        guard let data = self.screenData else {
            view.window?.alert(message: "No Screen Data")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = Date().description(with: Locale.current)
        savePanel.beginSheetModal(for: view.window!) { (response) in
            
            switch response {
            case .OK:
                guard let url = savePanel.url else { return }
                
                try? data.write(to: url, options: .atomic)
                NSWorkspace.shared.activateFileViewerSelecting([url])
            default:
                return
            }
        }
    }
    
    @objc private func didClickRefreshBtn() {
        
        guard
            let device = devicePopBtn.getSelecteDevice()
        else {
            view.window?.alert(message: "No Selected Device")
            return
        }
        
        do {
            var lockdownClient = try LockdownClient(device: device, withHandshake: true)
            var lockdownService = try lockdownClient.getService(service: .screenshot)
            var screenshotService = try ScreenshotService(device: device, service: lockdownService)
            
            screenData = try screenshotService.takeScreenshot()
            guard let data = screenData else { return }
            let screenImage = NSImage(data: data)
            let imageSize = screenImage?.size ?? CGSize(width: 1, height: 1)
            screenImageView.image = screenImage?.resize(CGSize(width: 210 * (imageSize.width / imageSize.height), height: 210))
            
            lockdownClient.free()
            lockdownService.free()
            screenshotService.free()
        } catch {
            print(error)
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
        
        didClickRefreshBtn()
    }
    
}

// MARK: - UI
extension ScreenshotViewController {
    
    private func setupUI() {
        
        backBtn = NSButton.makeButton(title: "Back", target: self, action: #selector(didClickBackBtn))
        view.addSubview(backBtn)
        backBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(32)
            make.width.equalTo(85)
        }
        
        exportBtn = NSButton.makeButton(title: "Export", target: self, action: #selector(didClickExportBtn))
        view.addSubview(exportBtn)
        exportBtn.snp.makeConstraints { (make) in
            make.top.equalTo(backBtn.snp.bottom).offset(10)
            make.centerX.height.width.equalTo(backBtn)
        }
        
        refreshBtn = NSButton.makeButton(title: "Refresh", target: self, action: #selector(didClickRefreshBtn))
        view.addSubview(refreshBtn)
        refreshBtn.snp.makeConstraints { (make) in
            make.top.equalTo(exportBtn.snp.bottom).offset(10)
            make.centerX.height.width.equalTo(backBtn)
        }
        
        devicePopBtn.target = self
        devicePopBtn.action = #selector(didChangeDevice(_:))
        devicePopBtn.focusRingType = .none
        view.addSubview(devicePopBtn)
        devicePopBtn.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(10)
            make.width.equalTo(120)
        }
        
        view.addSubview(screenImageView)
        screenImageView.snp.makeConstraints { (make) in
            make.top.equalTo(devicePopBtn.snp.bottom).offset(4)
            make.left.equalTo(devicePopBtn)
            make.width.equalTo(119)
            make.height.equalTo(210)
        }
        
    }
}
