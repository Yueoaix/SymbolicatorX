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
    
    var tabView = NSTabView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        setupUI()
    }
}

// MARK: - UI
extension MainViewController {
    
    private func setupUI() {
        
//        tabView.tabViewType = .noTabsBezelBorder
        let macItem = NSTabViewItem(viewController: MacViewController())
        macItem.label = "Mac"
        let deviceItem = NSTabViewItem(viewController: DeviceViewController())
        deviceItem.label = "Device"
        tabView.addTabViewItem(macItem)
        tabView.addTabViewItem(deviceItem)
        view.addSubview(tabView)
        tabView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}
