//
//  BasePanel.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/10/30.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class BasePanel: NSPanel {

    convenience init(size: NSSize, viewController: NSViewController) {
        self.init()
        setupUI(size: size, viewController: viewController)
    }
    
}

extension BasePanel {
    
    private func setupUI(size: NSSize, viewController: NSViewController) {
        
        contentViewController = viewController
        setFrame(NSRect(origin: CGPoint(x: 0, y: 0), size: size), display: true)
    }
}
