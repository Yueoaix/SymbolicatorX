//
//  NSTextView+LineNumber.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/16.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa
import ObjectiveC


private var LineNumberViewAssocObjKey = "LineNumberViewAssocObjKey"

extension NSTextView {
    var lineNumberView:LineNumberRulerView {
        get {
            return objc_getAssociatedObject(self, &LineNumberViewAssocObjKey) as! LineNumberRulerView
        }
        set {
            objc_setAssociatedObject(self, &LineNumberViewAssocObjKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func setupLineNumberView() {
        if font == nil {
            font = NSFont.systemFont(ofSize: 16)
        }
        
        if let scrollView = enclosingScrollView {
            lineNumberView = LineNumberRulerView(textView: self)
            
            scrollView.verticalRulerView = lineNumberView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        }
        
        postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(framDidChange), name: NSView.frameDidChangeNotification, object: self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: NSText.didChangeNotification, object: self)
    }
    
    @objc func framDidChange(notification: NSNotification) {
        
        lineNumberView.needsDisplay = true
    }
    
    @objc func textDidChange(notification: NSNotification) {
        
        lineNumberView.needsDisplay = true
    }
}
