//
//  BaseViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class BaseViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
    }
    
    override func loadView() {
        view = NSView(frame: NSRect.init(x: 0, y: 0, width: 600, height: 300))
    }
    
}
