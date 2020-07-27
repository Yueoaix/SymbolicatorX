//
//  MainWindowController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class MainWindowController: BaseWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        setupUI()
    }

}

// MARK: - Action
extension MainWindowController {
    
    @objc private func didClickFileBrowserBtn() {
        
        let devicePannel = FileBrowserPanel(size: NSSize(width: 600, height: 282))
        devicePannel.parent = window
        window?.beginSheet(devicePannel, completionHandler: nil)
    }
    
    @objc private func didClickDeviceBtn() {
        
        let devicePannel = DeviceCrashPanel(size: NSSize(width: 600, height: 282))
        devicePannel.parent = window
        window?.beginSheet(devicePannel, completionHandler: nil)
        
        guard
            let mainViewController = contentViewController as? MainViewController,
            let deviceViewCotroller = devicePannel.contentViewController as? DeviceCrashViewController
        else { return }
        
        deviceViewCotroller.crashFileHandle = { [weak mainViewController] (crashFile) in
            mainViewController?.crashFile = crashFile
        }
    }
    
    @objc private func didClickSymbolicateBtn() {
        
        guard let mainViewController = contentViewController as? MainViewController else {
            return
        }
        
        mainViewController.symbolicate()
    }
}

// MARK: - NSToolbarDelegate
extension MainWindowController: NSToolbarDelegate {
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier {
        case .fileBrowser:
            return NSToolbar.makeToolbarItem(identifier: .fileBrowser, target: self, action: #selector(didClickFileBrowserBtn))
        case .device:
            return NSToolbar.makeToolbarItem(identifier: .device, target: self, action: #selector(didClickDeviceBtn))
        case .symbolicate:
            return NSToolbar.makeToolbarItem(identifier: .symbolicate, target: self, action: #selector(didClickSymbolicateBtn))
        default:
            return nil
        }
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .fileBrowser, .device, .symbolicate]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .fileBrowser, .device, .symbolicate]
    }
}

// MARK:  - Toolbar Identifier
extension NSToolbarItem.Identifier {
    static let device = NSToolbarItem.Identifier(rawValue: "Device Crash")
    static let symbolicate = NSToolbarItem.Identifier(rawValue: "Symbolicate")
    static let fileBrowser = NSToolbarItem.Identifier(rawValue: "File Browser")
}

// MARK: - UI
extension MainWindowController {
    
    private func setupUI() {
        
        let toolbar = NSToolbar(identifier: self.className)
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window?.toolbar = toolbar
    }
    
}
