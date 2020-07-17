//
//  DeviceViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/17.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class DeviceViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        setupUI()
    }
    
}

extension DeviceViewController {
    
    @objc private func didClickOkBtn() {
        
        guard
            let window = view.window,
            let parent = window.parent
        else { return }
        
        parent.endSheet(window)
    }
}

// MARK: - UI
extension DeviceViewController {
    
    private func setupUI() {
        
        let okBtn = NSButton()
        okBtn.title = "OK"
        okBtn.bezelStyle = .rounded
        okBtn.focusRingType = .none
        okBtn.target = self
        okBtn.action = #selector(didClickOkBtn)
        view.addSubview(okBtn)
        okBtn.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
}
