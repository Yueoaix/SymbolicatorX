//
//  DeviceViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/17.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class DeviceViewController: BaseViewController {
    
    private let deviceBtn = NSPopUpButton()
    private let appBtn = NSPopUpButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        setupUI()
    }
    
}

extension DeviceViewController {
    
    @objc private func didClickConfirmBtn() {
           
        didClickCancelBtn()
    }
    
    @objc private func didClickCancelBtn() {
        
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
        
        let confirmBtn = makeButton(title: "Confirm", target: self, action: #selector(didClickConfirmBtn))
        view.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(10)
        }
        
        let cancelBtn = makeButton(title: "Cancel", target: self, action: #selector(didClickCancelBtn))
        view.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints { (make) in
            make.right.equalTo(confirmBtn.snp.left).offset(-10)
            make.top.equalTo(confirmBtn)
        }
        
        deviceBtn.addItems(withTitles: ["123","312","321"])
        deviceBtn.focusRingType = .none
        view.addSubview(deviceBtn)
        deviceBtn.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(10)
            make.width.equalTo(120)
        }
        
        appBtn.addItems(withTitles: ["123","312","321"])
        appBtn.focusRingType = .none
        view.addSubview(appBtn)
        appBtn.snp.makeConstraints { (make) in
            make.top.equalTo(deviceBtn)
            make.left.equalTo(deviceBtn.snp.right).offset(10)
            make.width.equalTo(285)
        }
        
        let tableView = NSTableView()
        tableView.focusRingType = .none
//        tableView.delegate = self
//        tableView.dataSource = self
        
        let column1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "name"))
        column1.title = "name"
        column1.width = 420
        column1.maxWidth = 450
        column1.minWidth = 160
        tableView.addTableColumn(column1)
        
        let column2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "date"))
        column2.title = "date"
        column2.width = 160
        tableView.addTableColumn(column2)
        
        let scrollView = NSScrollView()
        scrollView.focusRingType = .none
        scrollView.borderType = .bezelBorder
        scrollView.autohidesScrollers = true
        scrollView.documentView = tableView
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.bottom.right.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(10)
            make.top.equalTo(deviceBtn.snp.bottom).offset(10)
        }

    }
    
    private func makeButton(title: String, target: AnyObject, action: Selector) -> NSButton {
        
        let button = NSButton()
        button.title = title
        button.bezelStyle = .rounded
        button.focusRingType = .none
        button.target = target
        button.action = action
        
        return button
    }
}
