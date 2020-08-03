//
//  FileBrowserViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/27.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class FileBrowserViewController: BaseViewController {
    
    private let devicePopBtn = NSPopUpButton()
    private let appPopBtn = NSPopUpButton()
    private let outlineView = NSOutlineView()
    private let progressIndicator = NSProgressIndicator()
    private var exportBtn: NSButton!
    private var backBtn: NSButton!
    
    private var disposable: Disposable?
    private var houseArrest: HouseArrest?
    private var afcClient: AfcClient?
    private var file: FileModel?
    private var deviceList = [Device]()
    
    private var appInfoDict = [String:Plist]() {
        didSet {
            appPopBtn.removeAllItems()
            appPopBtn.addItems(withTitles: appInfoDict.keys.sorted())
            selectLastApp()
            loadFileData()
        }
    }
    
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
        disposable?.dispose()
        houseArrest?.free()
        afcClient?.free()
    }
}

// MARK: - Load Data
extension FileBrowserViewController {
    
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
            view.window?.alert(message: error.localizedDescription)
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
                self.devicePopBtn.addItem(withTitle: deviceName)
                if self.deviceList.count == 1 {
                    self.loadAppData()
                }
                lockdownClient.free()
            } catch {
                self.view.window?.alert(message: error.localizedDescription)
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
                    if self.devicePopBtn.selectedItem?.title == deviceName {
                        isNeedRefresh = true
                    }
                    
                    self.devicePopBtn.removeItem(withTitle: deviceName)
                    device.free()
                    return true
                }
                return false
            }
            
            if isNeedRefresh {
                self.loadAppData()
            }
            
            if self.deviceList.count == 0 {
                self.clearData()
            }
        }
    }
    
    private func loadAppData() {
        
        guard
            deviceList.count > 0,
            devicePopBtn.indexOfSelectedItem < deviceList.count
        else { return }
        let device = deviceList[devicePopBtn.indexOfSelectedItem]
        let options = Plist(dictionary: ["ApplicationType":Plist(string: "User")])
        
        do {
            var lockdownClient = try LockdownClient(device: device, withHandshake: true)
            var installService = try lockdownClient.getService(service: .installationProxy)
            var install = try InstallationProxy(device: device, service: installService)
            let appListPlist = try install.browse(options: options)
            
            var appInfoDict = [String:Plist]()
            _ = appListPlist.array?.compactMap({ (appInfoItem) -> Plist? in
                
                guard
                    let signer = appInfoItem["SignerIdentity"]?.string,
                    signer.contains("Developer") || signer.contains("Development"),
                    let appName = appInfoItem["CFBundleDisplayName"]?.string
                else { return nil }
                
                appInfoDict[appName] = appInfoItem
                
                return appInfoItem
            })
            self.appInfoDict = appInfoDict
            
            lockdownClient.free()
            installService.free()
            install.free()
        } catch {
            view.window?.alert(message: error.localizedDescription)
        }
    }
    
    private func loadFileData() {
        
        guard
            deviceList.count > 0,
            devicePopBtn.indexOfSelectedItem < deviceList.count,
            appPopBtn.indexOfSelectedItem < appInfoDict.count
        else { return }
        
        let device = deviceList[devicePopBtn.indexOfSelectedItem]
        let title = appPopBtn.selectedItem?.title ?? ""
        let appInfo = appInfoDict[title]
        
        guard let appID = appInfo?["CFBundleIdentifier"]?.string else { return }
        lastSelectedAppID = appID
        
        DispatchQueue.global().async {
            do {
                var lockdownClient = try LockdownClient(device: device, withHandshake: true)
                var lockdownService = try lockdownClient.getService(service: .houseArrest)
                let houseArrest = try HouseArrest(device: device, service: lockdownService)
                try houseArrest.sendCommand(command: "VendContainer", appid: appID)
                _ = try houseArrest.getResult()
                let afcClient = try AfcClient(houseArrest: houseArrest)
                let fileInfo = try afcClient.getFileInfo(path: ".")
                self.file = FileModel(filePath: ".", fileInfo: fileInfo, afcClient: afcClient)
                DispatchQueue.main.async {
                    self.outlineView.reloadData()
                }
                self.houseArrest = houseArrest
                self.afcClient = afcClient
                lockdownClient.free()
                lockdownService.free()
            } catch {
                self.view.window?.alert(message: error.localizedDescription)
            }
        }
    }
    
    private func clearData() {
        file = nil
        devicePopBtn.removeAllItems()
        appPopBtn.removeAllItems()
        outlineView.reloadData()
    }
}

// MARK: - Action
extension FileBrowserViewController {
    
    @objc private func didClickBackBtn() {
        
        guard
            let window = view.window,
            let parent = window.parent
        else { return }
        
        parent.endSheet(window)
    }
    
    @objc private func didClickExportBtn() {
        
        var selectedFile = [FileModel]()
        outlineView.selectedRowIndexes.forEach { (row) in
            guard let file = outlineView.item(atRow: row) as? FileModel else { return }
            selectedFile.append(file)
        }
        
        guard selectedFile.count > 0 else { return }
        
        var total = 0
        var progress = 0
        selectedFile.forEach { (file) in
            total += file.allFileCount()
        }
        progressIndicator.doubleValue = 0
        progressIndicator.isHidden = total == 0
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = appPopBtn.selectedItem?.title ?? ""
        savePanel.beginSheetModal(for: view.window!) { (response) in
            
            switch response {
            case .OK:
                guard let url = savePanel.url else { return }
                self.progressIndicator.startAnimation(self)
                self.backBtn.isEnabled = false
                self.exportBtn.isEnabled = false
                DispatchQueue.global().async {

                    selectedFile.forEach { (file) in
                        file.save(toPath: url.appendingPathComponent(file.name)) { [weak self] in
                            progress += 1
                            DispatchQueue.main.async {
                                self?.progressIndicator.doubleValue = Double(progress)/Double(total)
                                if progress == total {
                                    self?.progressIndicator.isHidden = true
                                    self?.backBtn.isEnabled = true
                                    self?.exportBtn.isEnabled = true
                                }
                            }
                        }
                    }
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            default:
                return
            }
        }
    }
    
    @objc private func didChangeDevice(_ sender: NSPopUpButton) {
        
        loadAppData()
    }
    
    @objc private func didChangeApp(_ sender: NSPopUpButton) {
        
        loadFileData()
    }
    
}

// MARK: - NSOutlineViewDataSource
extension FileBrowserViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        if let file = item as? FileModel {
            
            return file.children.count
        } else {
            
            return file?.children.count ?? 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        if let file = item as? FileModel {
            
            return file.children[index]
        } else {
            
            return file!.children[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        let file = item as! FileModel
        
        return file.children.count > 0
    }
}

// MARK: - NSOutlineViewDelegate
extension FileBrowserViewController: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        var cell: NSTableCellView?
        let file = item as? FileModel
        if tableColumn == outlineView.tableColumns[0] {
            
            cell = (outlineView.makeView(withIdentifier: .file, owner: nil) as? FileTableCellView) ?? FileTableCellView()
            (cell as! FileTableCellView).model = file
        } else {
            
            cell = NSTableCellView.makeCellView(tableView: outlineView, identifier: .date)
            cell?.textField?.stringValue = file?.dateStr ?? ""
        }
        
        return cell
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        exportBtn.isEnabled = outlineView.selectedRowIndexes.count > 0
    }
    
}

// MARK: - Restory Last Selected
extension FileBrowserViewController {
    
    var lastSelectedAppID: String? {
        get {
            UserDefaults.standard.string(forKey: "lastSelectedAppID")
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "lastSelectedAppID")
        }
    }
    
    private func selectLastApp() {
        
        guard let lastAppID = lastSelectedAppID else { return }
        
        let appInfo = appInfoDict.values.first { (appInfo) -> Bool in
            guard let appID = appInfo["CFBundleIdentifier"]?.string else { return false }
            
            return appID == lastAppID
        }
        
        if let appName = appInfo?["CFBundleDisplayName"]?.string {
            appPopBtn.selectItem(withTitle: appName)
        }
    }
}

// MARK: - UI
extension FileBrowserViewController {
    
    private func setupUI() {
        
        exportBtn = NSButton.makeButton(title: "Export", target: self, action: #selector(didClickExportBtn))
        exportBtn.isEnabled = false
        view.addSubview(exportBtn)
        exportBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(10)
        }
        
        backBtn = NSButton.makeButton(title: "Back", target: self, action: #selector(didClickBackBtn))
        view.addSubview(backBtn)
        backBtn.snp.makeConstraints { (make) in
            make.right.equalTo(exportBtn.snp.left).offset(-10)
            make.top.equalTo(exportBtn)
        }
        
        devicePopBtn.target = self
        devicePopBtn.action = #selector(didChangeDevice(_:))
        devicePopBtn.focusRingType = .none
        view.addSubview(devicePopBtn)
        devicePopBtn.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(10)
            make.width.equalTo(120)
        }
        
        appPopBtn.target = self
        appPopBtn.action = #selector(didChangeApp(_:))
        appPopBtn.focusRingType = .none
        view.addSubview(appPopBtn)
        appPopBtn.snp.makeConstraints { (make) in
            make.top.equalTo(devicePopBtn)
            make.left.equalTo(devicePopBtn.snp.right).offset(10)
            make.width.equalTo(285)
        }
        
        let column1 = NSTableColumn(identifier: .name)
        column1.title = "name"
        column1.width = 395
        column1.maxWidth = 450
        column1.minWidth = 160
        outlineView.addTableColumn(column1)
        
        let column2 = NSTableColumn(identifier: .date)
        column2.title = "date"
        column2.width = 185
        column2.minWidth = 185
        outlineView.addTableColumn(column2)
        
        outlineView.allowsMultipleSelection = true
        outlineView.usesAlternatingRowBackgroundColors = true
        outlineView.delegate = self;
        outlineView.dataSource = self;
        outlineView.focusRingType = .none
        outlineView.rowHeight = 20
        outlineView.outlineTableColumn = column1
        
        let scrollView = NSScrollView()
        scrollView.focusRingType = .none
        scrollView.borderType = .bezelBorder
        scrollView.autohidesScrollers = true
        scrollView.documentView = outlineView
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.bottom.right.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(10)
            make.top.equalTo(devicePopBtn.snp.bottom).offset(10)
        }
        
        progressIndicator.isDisplayedWhenStopped = false
        progressIndicator.isIndeterminate = false
        progressIndicator.style = .bar
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 1
        progressIndicator.isHidden = true
        view.addSubview(progressIndicator)
        progressIndicator.snp.makeConstraints { (make) in
            make.left.equalTo(devicePopBtn)
            make.right.equalTo(exportBtn)
            make.top.equalTo(devicePopBtn.snp.bottom).offset(-3)
        }
    }
}
