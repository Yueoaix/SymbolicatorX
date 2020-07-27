//
//  DevicePannel.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/17.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class DevicePanel: NSPanel {

    convenience init(size: NSSize) {
        self.init()
        setupUI(size: size)
    }
    
}

extension DevicePanel {
    
    private func setupUI(size: NSSize) {
        
        contentViewController = DeviceViewController()
        setFrame(NSRect(origin: CGPoint(x: 0, y: 0), size: size), display: true)
    }
}
