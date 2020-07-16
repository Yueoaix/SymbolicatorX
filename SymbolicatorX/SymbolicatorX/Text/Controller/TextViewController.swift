//
//  TextViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/15.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class TextViewController: BaseViewController {
    
    let scrollView = NSScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        setupUI()
    }
}

// MARK: - UI
extension TextViewController {
    
    private func setupUI() {
        
        scrollView.hasVerticalScroller = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        let textView = NSTextView()
        scrollView.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        scrollView.documentView = textView
        
    }
}
