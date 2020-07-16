//
//  TextWindowController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/16.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class TextWindowController: BaseWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        setupUI()
    }
    
    override var windowNibName: NSNib.Name? {
        get {
            NSNib.Name("TextWindowController")
        }
    }
    
    public func setText(_ text: String) {
        
        guard let textViewController = self.contentViewController as? TextViewController else {
            return
        }
        
        textViewController.setText(text)
    }
}

// MARK: - Action
extension TextWindowController {
    
    @objc private func didClickLocationBtn() {
        
    }
    
    @objc private func didClickSaveBtn() {
        
    }
}

// MARK: - NSToolbarDelegate
extension TextWindowController: NSToolbarDelegate {
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier {
        case .location:
            return makeToolbarItem(identifier: .location, action: #selector(didClickLocationBtn))
        case .save:
            return makeToolbarItem(identifier: .save, action: #selector(didClickSaveBtn))
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
extension TextWindowController {
    
    private func setupUI() {
        
        self.contentViewController = TextViewController()
        
        let toolbar = NSToolbar(identifier: "TextWindowControllerToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window?.toolbar = toolbar
    }
    
    private func makeToolbarItem(identifier: NSToolbarItem.Identifier, action: Selector) -> NSToolbarItem {
        
        let title = identifier.rawValue
        
        let toolbarItem = NSToolbarItem(itemIdentifier: .save)
        toolbarItem.label = title
        toolbarItem.paletteLabel = title
        toolbarItem.target = self
        toolbarItem.action = action

        let button = NSButton()
        button.bezelStyle = .texturedRounded
        button.title = title
        button.target = self
        button.action = action
        toolbarItem.view = button

        return toolbarItem
    }
}
