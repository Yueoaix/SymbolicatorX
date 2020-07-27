//
//  NSButton+Extension.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/27.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

extension NSButton {
    
    static func makeButton(title: String, target: AnyObject, action: Selector) -> NSButton {
        
        let button = NSButton()
        button.title = title
        button.bezelStyle = .rounded
        button.focusRingType = .none
        button.target = target
        button.action = action
        
        return button
    }
    
}
