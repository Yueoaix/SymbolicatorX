//
//  BaseWindowController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class BaseWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        center()
    }

    func center() {
        
        guard
            let screen = NSScreen.main,
            let window = window
            else { return }
        
        let screenFrame = screen.frame
        let windowSize = window.frame.size
        let windowOrigin = CGPoint(
            x: screenFrame.midX - windowSize.width / 2,
            y: screenFrame.midY - windowSize.height / 2
        )
        window.setFrameOrigin(windowOrigin)
    }
}
