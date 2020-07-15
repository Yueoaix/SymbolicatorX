//
//  TextViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/15.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class TextViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.red.cgColor
    }
    
}
