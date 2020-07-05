//
//  MainViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa
import SnapKit

class MainViewController: BaseViewController {
    
    var tabView = NSTabView(frame: NSRect.init(x: 0, y: 0, width: 100, height: 100))

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        setupUI()
    }
}

// MARK: - UI
extension MainViewController {
    
    func setupUI() {
        
        view.frame = NSRect(x: 0, y: 0, width: 600, height: 300)
        
        tabView.tabViewType = .noTabsBezelBorder
        let macItem = NSTabViewItem(viewController: MacViewController())
        let deviceItem = NSTabViewItem(viewController: DeviceViewController())
        tabView.addTabViewItem(macItem)
        tabView.addTabViewItem(deviceItem)
        view.addSubview(tabView)
        tabView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}
