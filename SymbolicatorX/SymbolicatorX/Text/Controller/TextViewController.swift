//
//  TextViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/15.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class TextViewController: BaseViewController {
    
    private let scrollView = NSScrollView()
    private let textView = NSTextView()
    
    public var text: String {
        get {
            return textView.string
        }
        set {
            textView.string = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        setupUI()
    }
}

// MARK: - UI
extension TextViewController {
    
    private func setupUI() {
        
        view.setFrameSize(NSSize(width: 1100, height: 800))
        
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        textView.autoresizingMask = .width
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.setupLineNumberView()
    }
}
