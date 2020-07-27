//
//  FileBrowserPanel.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/27.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class FileBrowserPanel: NSPanel {

    convenience init(size: NSSize) {
        self.init()
        setupUI(size: size)
    }
    
}

extension FileBrowserPanel {
    
    private func setupUI(size: NSSize) {
        
        contentViewController = FileBrowserViewController()
        setFrame(NSRect(origin: CGPoint(x: 0, y: 0), size: size), display: true)
    }
}
