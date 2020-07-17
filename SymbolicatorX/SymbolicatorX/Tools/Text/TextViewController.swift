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

// MARK: - Find Target
extension TextViewController {
    
    public func location(pattern: String) {
        
        guard let range = text.findRange(pattern: pattern) else {
            return
        }
        
        textView.scrollRangeToVisible(range)
        highlight(range: range)
    }
    
    public func highlight(range: NSRange) {
        
        guard
            let textContainer = textView.layoutManager?.textContainers.first,
            let glyphRange = textView.layoutManager?.characterRange(forGlyphRange: range, actualGlyphRange: nil),
            let rect = textView.layoutManager?.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            else { return }
        
        let viewRect = NSRect(x: max(rect.minX - 5.0, 0), y: rect.minY - 5.0, width: rect.width + 10.0, height: rect.height + 10.0)
        
        let borderView = NSView(frame: viewRect)
        borderView.wantsLayer = true
        borderView.layer?.borderWidth = 4.0
        borderView.layer?.borderColor = NSColor.red.cgColor
        borderView.layer?.cornerRadius = 4.0
        borderView.alphaValue = 0
        textView.addSubview(borderView)
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 0.6
        animation.repeatCount = 3
        animation.duration = 0.5
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.completionHandler = {
            borderView.removeFromSuperview()
        }
        borderView.layer?.add(animation, forKey: "twinkle")
        NSAnimationContext.endGrouping()
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
