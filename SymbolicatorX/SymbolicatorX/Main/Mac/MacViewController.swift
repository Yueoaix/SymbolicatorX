//
//  MacViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class MacViewController: BaseViewController {
    
    let crashFileDropZone = DropZoneView(fileTypes: [".crash", ".txt"], text: "Drop Crash Report or Sample")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        setupUI()
    }
}

// MARK: - UI
extension MacViewController {
    
    private func setupUI() {

        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(crashFileDropZone)
        crashFileDropZone.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.equalTo(240)
        }
        
        
    }
    
}
