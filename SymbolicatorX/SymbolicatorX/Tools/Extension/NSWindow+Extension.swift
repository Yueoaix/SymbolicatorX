//
//  NSWindow+Extension.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/31.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

extension NSWindow {
    
    func alert(message: String) {
        
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self, completionHandler: nil)
    }
    
}
