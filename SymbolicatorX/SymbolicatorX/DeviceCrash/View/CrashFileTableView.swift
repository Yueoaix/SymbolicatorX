//
//  CrashFileTableView.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/24.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

protocol TableViewMenuDelegate: class {
    func didClickMenu(tableView: NSTableView, type: MenuType)
}

enum MenuType {
    case view
    case save
    case remove
}

class CrashFileTableView: NSTableView {
    
    public weak var menuDelegate: TableViewMenuDelegate?
    
    private lazy var cmenu: NSMenu = {
        
        let menu = NSMenu()
        
        let viewItem = NSMenuItem()
        viewItem.title = "View"
        viewItem.target = self
        viewItem.action = #selector(didClickViewMenu)
        menu.addItem(viewItem)
        
        let saveItem = NSMenuItem()
        saveItem.title = "Save"
        saveItem.target = self
        saveItem.action = #selector(didClickSaveMenu)
        menu.addItem(saveItem)
        
        return menu
    }()
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        
        let location = convert(event.locationInWindow, from: nil)
        let row = self.row(at: location)
        if row >= 0 && event.type == .rightMouseDown {
            selectRowIndexes(IndexSet(arrayLiteral: row), byExtendingSelection: false)
        }
        
        guard selectedRowIndexes.count > 0 else { return nil }
        
        return cmenu
    }
    
}

// MARK: - Menu Action
extension CrashFileTableView {
    
    @objc private func didClickViewMenu() {
        menuDelegate?.didClickMenu(tableView: self, type: .view)
    }
        
    @objc private func didClickSaveMenu() {
        menuDelegate?.didClickMenu(tableView: self, type: .save)
    }
}
