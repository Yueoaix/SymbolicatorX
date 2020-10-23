//
//  FileOutlineView.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/10/23.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

protocol OutlineViewMenuDelegate: class {
    func didClickMenu(outlineView: NSOutlineView, type: MenuType)
}

class FileOutlineView: NSOutlineView {
    
    public weak var menuDelegate: OutlineViewMenuDelegate?
    
    private lazy var cmenu: NSMenu = {
        
        let menu = NSMenu()
        
        let removeItem = NSMenuItem()
        removeItem.title = "Remove"
        removeItem.target = self
        removeItem.action = #selector(didClickRemoveMenu)
        menu.addItem(removeItem)
        
        return menu
    }()

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        
        if selectedRowIndexes.count == 0 {
            
            let location = convert(event.locationInWindow, from: nil)
            let row = self.row(at: location)
            if row >= 0 && event.type == .rightMouseDown {
                selectRowIndexes(IndexSet(arrayLiteral: row), byExtendingSelection: false)
            }
        }
        
        guard selectedRowIndexes.count > 0 else { return nil }
        
        return cmenu
    }
}

// MARK: - Menu Action
extension FileOutlineView {
    
    @objc private func didClickRemoveMenu() {
        
        menuDelegate?.didClickMenu(outlineView: self, type: .remove)
    }
}
