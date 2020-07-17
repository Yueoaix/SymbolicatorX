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
    
    @objc private func didClickDeviceBtn() {
        
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
        case .device:
            return NSToolbar.makeToolbarItem(identifier: .device, target: self, action: #selector(didClickDeviceBtn))
        case .symbolicate:
            return NSToolbar.makeToolbarItem(identifier: .symbolicate, target: self, action: #selector(didClickSymbolicateBtn))
        default:
            return nil
        }
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .device, .symbolicate]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .device, .symbolicate]
    }
}

// MARK:  - Toolbar Identifier
extension NSToolbarItem.Identifier {
    static let device = NSToolbarItem.Identifier(rawValue: "Device")
    static let symbolicate = NSToolbarItem.Identifier(rawValue: "Symbolicate")
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
