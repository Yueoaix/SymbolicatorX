//
//  DeviceCrashPanel.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/17.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class DeviceCrashPanel: NSPanel {

    convenience init(size: NSSize) {
        self.init()
        setupUI(size: size)
    }
    
}

extension DeviceCrashPanel {
    
    private func setupUI(size: NSSize) {
        
        contentViewController = DeviceCrashViewController()
        setFrame(NSRect(origin: CGPoint(x: 0, y: 0), size: size), display: true)
    }
}
