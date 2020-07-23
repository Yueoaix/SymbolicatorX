//
//  DeviceViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/17.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class DeviceViewController: BaseViewController {
    
    private let devicePopBtn = NSPopUpButton()
    private let appPopBtn = NSPopUpButton()
    private let tableView = NSTableView()
    
    private var deviceList = [Device]() {
        willSet {
            var deviceNameList = [String]()
            self.deviceList = newValue.filter { (device) -> Bool in
                
                guard
                    var lockdownClient = try? LockdownClient(device: device, withHandshake: false),
                    let deviceName = try? lockdownClient.getName()
                else { return false }
                
                deviceNameList.append(deviceName)
                lockdownClient.free()
                return true
            }
            
            DispatchQueue.main.async {
                let selectTitle = self.devicePopBtn.selectedItem?.title
                self.devicePopBtn.removeAllItems()
                self.devicePopBtn.addItems(withTitles: deviceNameList)
                
                if let title = selectTitle {
                    self.devicePopBtn.selectItem(withTitle: title)
                }else{
                    self.initAppData()
                }
            }
        }
    }
    
    private var appInfoDict = [String:Plist]() {
        didSet {
            
            DispatchQueue.main.async {
                self.appPopBtn.removeAllItems()
                self.appPopBtn.addItems(withTitles: self.appInfoDict.keys.sorted())
                self.initCrashFileData()
            }
        }
    }
    
    private var crashFileList = [FileModel]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        setupUI()
        initDeviceData()
        
    }
}

// MARK: - init Data
extension DeviceViewController {
    
    private func initDeviceData() {
        DispatchQueue.global().async {
            guard let deviceList = try? MobileDevice.getDeviceList().compactMap({ (udid) -> Device? in
                try? Device(udid: udid)
            }) else { return }
            
            self.deviceList = deviceList
        }
    }
    
    private func initAppData() {
        
        guard
            deviceList.count > 0,
            devicePopBtn.indexOfSelectedItem < deviceList.count
            else { return }
        let device = deviceList[devicePopBtn.indexOfSelectedItem]
        
        DispatchQueue.global().async {
            
            let options = Plist(dictionary: ["ApplicationType":Plist(string: "User")])
            do {
                var lockdownClient = try LockdownClient(device: device, withHandshake: true)
                var installService = try lockdownClient.getService(service: .installationProxy)
                var install = try InstallationProxy(device: device, service: installService)
                let appListPlist = try install.browse(options: options)
                
                var appInfoDict = [String:Plist]()
                _ = appListPlist.array?.map({ (appInfoItem) -> Plist in
                    
                    if let appName = appInfoItem["CFBundleDisplayName"]?.string {
                        appInfoDict[appName] = appInfoItem
                    }
                    return appInfoItem
                })
                self.appInfoDict = appInfoDict
                
                lockdownClient.free()
                installService.free()
                install.free()
            } catch {
                print(error)
            }
        }
    }
    
    private func initCrashFileData() {
        
        guard
            deviceList.count > 0,
            devicePopBtn.indexOfSelectedItem < deviceList.count,
            appPopBtn.indexOfSelectedItem < appInfoDict.count
            else { return }
        
        let device = deviceList[devicePopBtn.indexOfSelectedItem]
        let appInfo = appInfoDict[appPopBtn.selectedItem?.title ?? ""]
        let bundleExecutable = appInfo?["CFBundleExecutable"]?.string ?? ""
        
        do {
            let lockdownClient = try LockdownClient(device: device, withHandshake: true)
            let lockdownService = try lockdownClient.getService(service: .crashreportcopymobile)
            let afcClient = try AfcClient(device: device, service: lockdownService)
            let crashFileList = try afcClient.readDirectory(path: ".")
            let retiredFileList = try afcClient.readDirectory(path: "./Retired")
            
            let crashList = crashFileList.compactMap { (fileName) -> FileModel? in
                
                guard
                    fileName.scan(pattern: "^(\(bundleExecutable))-\\d{4}-\\d{2}-\\d{2}-\\d{6}").count > 0,
                    let fileInfo = try? afcClient.getFileInfo(path: fileName)
                else { return nil }
                
                return FileModel(filePath: fileName, fileInfo: fileInfo)
            }
            
            let retiredList = retiredFileList.compactMap { (fileName) -> FileModel? in
                guard
                    fileName.scan(pattern: "^(\(bundleExecutable))-\\d{4}-\\d{2}-\\d{2}-\\d{6}").count > 0,
                    let fileInfo = try? afcClient.getFileInfo(path: "./Retired/\(fileName)")
                else { return nil }
                
                return FileModel(filePath: "./Retired/\(fileName)", fileInfo: fileInfo)
            }
            
            self.crashFileList = crashList + retiredList
        } catch {
            print(error)
        }
        
    }
}

// MARK: - Action
extension DeviceViewController {
    
    @objc private func didClickConfirmBtn() {
        
        didClickCancelBtn()
    }
    
    @objc private func didClickCancelBtn() {
        
        guard
            let window = view.window,
            let parent = window.parent
            else { return }
        
        parent.endSheet(window)
    }
    
    @objc private func didChangeDevice(_ sender: NSPopUpButton) {
        
        initAppData()
    }
    
    @objc private func didChangeApp(_ sender: NSPopUpButton) {
        
        initCrashFileData()
    }
}

// MARK: - NSTableViewDataSource
extension DeviceViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return crashFileList.count
    }
}

// MARK: - NSTableViewDelegate
extension DeviceViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var cell: NSTableCellView?
        if tableColumn == tableView.tableColumns[0] {
            cell = makeCellView(identifier: .process)
            (cell?.subviews[0] as! NSTextField).stringValue = crashFileList[row].name
        } else {
            cell = makeCellView(identifier: .date)
            (cell?.subviews[0] as! NSTextField).stringValue = crashFileList[row].date?.description ?? ""
        }
        
        return cell
    }
    
    func makeCellView(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        
        if let cellView = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            
            return cellView
        }else{
            
            let cellView = NSTableCellView()
            cellView.identifier = identifier
            let textField =  NSTextField()
            textField.isEditable = false
            cellView.addSubview(textField)
            textField.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            return cellView
        }
    }
}

extension NSUserInterfaceItemIdentifier {
    static let process = NSUserInterfaceItemIdentifier("Process")
    static let date = NSUserInterfaceItemIdentifier("Date")
}

// MARK: - UI
extension DeviceViewController {
    
    private func setupUI() {
        
        let confirmBtn = makeButton(title: "Confirm", target: self, action: #selector(didClickConfirmBtn))
        view.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(10)
        }
        
        let cancelBtn = makeButton(title: "Cancel", target: self, action: #selector(didClickCancelBtn))
        view.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints { (make) in
            make.right.equalTo(confirmBtn.snp.left).offset(-10)
            make.top.equalTo(confirmBtn)
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
        
        tableView.focusRingType = .none
        tableView.rowHeight = 20
        tableView.delegate = self
        tableView.dataSource = self
        
        let column1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "name"))
        column1.title = "name"
        column1.width = 420
        column1.maxWidth = 450
        column1.minWidth = 160
        tableView.addTableColumn(column1)
        
        let column2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "date"))
        column2.title = "date"
        column2.width = 160
        tableView.addTableColumn(column2)
        
        let scrollView = NSScrollView()
        scrollView.focusRingType = .none
        scrollView.borderType = .bezelBorder
        scrollView.autohidesScrollers = true
        scrollView.documentView = tableView
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.bottom.right.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(10)
            make.top.equalTo(devicePopBtn.snp.bottom).offset(10)
        }
        
    }
    
    private func makeButton(title: String, target: AnyObject, action: Selector) -> NSButton {
        
        let button = NSButton()
        button.title = title
        button.bezelStyle = .rounded
        button.focusRingType = .none
        button.target = target
        button.action = action
        
        return button
    }
}
