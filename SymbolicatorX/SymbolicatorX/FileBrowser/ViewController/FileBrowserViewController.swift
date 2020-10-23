//
//  FileBrowserViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/27.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class FileBrowserViewController: BaseViewController {
    
    private let devicePopBtn = DevicePopUpButton()
    private let appPopBtn = NSPopUpButton()
    private let outlineView = FileOutlineView()
    private let progressIndicator = FileProgressIndicator()
    private var exportBtn: NSButton!
    private var backBtn: NSButton!
    
    private var houseArrest: HouseArrest?
    private var afcClient: AfcClient?
    private var file: FileModel?
    
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
    }
    
    deinit {
        houseArrest?.free()
        afcClient?.free()
    }
}

// MARK: - Load Data
extension FileBrowserViewController {
    
    private func loadAppData() {
        
        guard
            let device = devicePopBtn.getSelecteDevice()
        else {
            clearData()
            return
        }
        
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
            let device = devicePopBtn.getSelecteDevice(),
            appPopBtn.indexOfSelectedItem < appInfoDict.count
        else { return }
        
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
        appPopBtn.removeAllItems()
        outlineView.reloadData()
        exportBtn.isEnabled = false
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
        selectedFile.forEach { (file) in
            total += file.allFileCount()
        }
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = appPopBtn.selectedItem?.title ?? ""
        savePanel.beginSheetModal(for: view.window!) { (response) in
            
            switch response {
            case .OK:
                guard let url = savePanel.url else { return }
                self.progressIndicator.start(taskCount: total)
                DispatchQueue.global().async {

                    selectedFile.forEach { (file) in
                        file.exportFiles(toPath: url.appendingPathComponent(file.name)) { [weak self] in
                            DispatchQueue.main.async {
                                self?.progressIndicator.finish(count: 1)
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

// MARK: - TableViewMenuDelegate
extension FileBrowserViewController: OutlineViewMenuDelegate {
    
    func didClickMenu(outlineView: NSOutlineView, type: MenuType) {
        
        guard type == .remove else { return }

        outlineView.selectedRowIndexes.forEach { (row) in
            
            guard
                let fileModel = outlineView.item(atRow: row) as? FileModel,
                let parentFileModel = outlineView.parent(forItem: fileModel) as? FileModel,
                let index = parentFileModel.children.firstIndex(of: fileModel)
            else { return }
            
            do{
                try fileModel.removeFile()
                outlineView.beginUpdates()
                parentFileModel.children.remove(at: index)
                outlineView.removeItems(at: IndexSet.init(integer: index), inParent: parentFileModel, withAnimation: .slideUp)
                outlineView.endUpdates()
            }catch{
                view.window?.alert(message: error.localizedDescription)
            }
        }
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
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        
        return .every;
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        
        guard
            let draggedFiles = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil),
            var fileModel = item as? FileModel
        else {
            return false
        }
        
        if !fileModel.isDirectory {
            fileModel = outlineView.parent(forItem: fileModel) as! FileModel
        }
        
        var total = draggedFiles.count
        let draggedFileURLs = draggedFiles.compactMap { (draggedFile) -> URL? in
            guard let draggedFile = draggedFile as? NSURL else { return nil }
            
            let allSubFiles = FileManager.default.enumerator(at: draggedFile.filePathURL!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles, errorHandler: nil)
            total += allSubFiles?.allObjects.count ?? 0
            return draggedFile.filePathURL
        }
        
        progressIndicator.start(taskCount: total)
        DispatchQueue.global().async {
            do{
                try fileModel.uploadFiles(fileURLs: draggedFileURLs) {
                    DispatchQueue.main.async {
                        self.progressIndicator.finish(count: 1)
                    }
                }
            }catch{
                self.view.window?.alert(message: error.localizedDescription)
            }
        }
        return true
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
        outlineView.menuDelegate = self
        outlineView.outlineTableColumn = column1
        outlineView.registerForDraggedTypes([(kUTTypeFileURL as
        NSPasteboard.PasteboardType)])
        
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
        
        progressIndicator.setCallback(start: {
            [weak self] in
            self?.progressIndicator.isHidden = false
            self?.backBtn.isEnabled = false
            self?.exportBtn.isEnabled = false
        }, progress: nil) {
            [weak self] in
            
            self?.progressIndicator.isHidden = true
            self?.backBtn.isEnabled = true
            self?.exportBtn.isEnabled = true
            self?.outlineView.reloadData()
        }
    }
    
}
