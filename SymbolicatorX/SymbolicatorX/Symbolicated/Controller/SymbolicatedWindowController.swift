//
//  TextWindowController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/16.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class SymbolicatedWindowController: BaseWindowController {
    
    private var textViewController = TextViewController()
    private let savePanel = NSSavePanel()
    
    public var fileName: String? {
        didSet {
            guard let name = fileName else { return }
            savePanel.nameFieldStringValue = name
        }
    }
    public var saveUrl: URL?
    public var text: String {
        get {
            return textViewController.text
        }
        set {
            textViewController.text = newValue
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        setupUI()
    }
    
    override var windowNibName: NSNib.Name? {
        get {
            NSNib.Name("SymbolicatedWindowController")
        }
    }
}

// MARK: - Action
extension SymbolicatedWindowController {
    
    @objc private func didClickLocationBtn() {
        let crashInfoPattern = "Thread\\s+\\d+\\s+\\(crashed\\)\n(.*(\\d|\\w)+.+\n)+"
        let crashPattern = "(?:^Thread \\d+.*\n)*^Thread \\d+ Crashed:\\s*.*\n(?:^\\s*\\d{1,3}.*\n)+"

        textViewController.location(pattern: "(\(crashInfoPattern)|\(crashPattern))")
    }
    
    @objc private func didClickSaveBtn() {
        
        if let saveUrl = saveUrl {
            
            try? text.write(to: saveUrl, atomically: true, encoding: .utf8)
            window?.orderOut(nil)
            NSWorkspace.shared.activateFileViewerSelecting([saveUrl])
        } else {

            savePanel.beginSheetModal(for: window!) { (response) in
                
                switch response {
                case .OK:
                    guard let url = self.savePanel.url else { return }
                    try? self.text.write(to: url, atomically: true, encoding: .utf8)
                    self.window?.close()
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                default:
                    return
                }
            }
        }
    }
}

// MARK: - NSToolbarDelegate
extension SymbolicatedWindowController: NSToolbarDelegate {
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier {
        case .location:
            return NSToolbar.makeToolbarItem(identifier: .location, target: self, action: #selector(didClickLocationBtn))
        case .save:
            return NSToolbar.makeToolbarItem(identifier: .save, target: self, action: #selector(didClickSaveBtn))
        default:
            return nil
        }
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .location, .save]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace, .location, .save]
    }
}

// MARK:  - Toolbar Identifier
extension NSToolbarItem.Identifier {
    static let location = NSToolbarItem.Identifier(rawValue: "Location")
    static let save = NSToolbarItem.Identifier(rawValue: "Save")
}

// MARK: - UI
extension SymbolicatedWindowController {
    
    private func setupUI() {
        
        window?.title = "Content"
        contentViewController = textViewController
        
        let toolbar = NSToolbar(identifier: self.className)
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window?.toolbar = toolbar
    }
}
