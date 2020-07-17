//
//  NSToolbarItem+Extension.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/17.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation
import Cocoa

extension NSToolbar {
    
    static func makeToolbarItem(identifier: NSToolbarItem.Identifier, target: AnyObject, action: Selector) -> NSToolbarItem {
        
        let title = identifier.rawValue
        
        let toolbarItem = NSToolbarItem(itemIdentifier: .save)
        toolbarItem.label = title
        toolbarItem.paletteLabel = title
        toolbarItem.target = target
        toolbarItem.action = action

        let button = NSButton()
        button.bezelStyle = .texturedRounded
        button.title = title
        button.target = target
        button.action = action
        toolbarItem.view = button

        return toolbarItem
    }
}
