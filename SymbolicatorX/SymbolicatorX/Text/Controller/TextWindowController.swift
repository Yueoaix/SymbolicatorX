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
        self.contentViewController = TextViewController()
    }
    
    override var windowNibName: NSNib.Name? {
        get {
            NSNib.Name("TextWindowController")
        }
    }
    
}
