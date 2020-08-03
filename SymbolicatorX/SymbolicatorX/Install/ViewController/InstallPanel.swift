//
//  InstallPanel.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/8/3.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class InstallPanel: NSPanel {

    convenience init(size: NSSize) {
        self.init()
        setupUI(size: size)
    }
    
}

extension InstallPanel {
    
    private func setupUI(size: NSSize) {
        
        contentViewController = InstallViewController()
        setFrame(NSRect(origin: CGPoint(x: 0, y: 0), size: size), display: true)
    }
}
