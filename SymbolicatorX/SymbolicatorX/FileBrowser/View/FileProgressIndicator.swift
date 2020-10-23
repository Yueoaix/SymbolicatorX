//
//  FileProgressIndicator.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/10/23.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class FileProgressIndicator: NSProgressIndicator {
    
    typealias StartHandler = () -> Void
    typealias ProgressHandler = (Double) -> Void
    typealias CompletionHandler = () -> Void
    
    private var taskCount: Int = 0
    private var finishCount: Int = 0
    private var startHandler: StartHandler?
    private var progressHandler: ProgressHandler?
    private var completionHandler: CompletionHandler?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FileProgressIndicator {
    
    public func setCallback(start: StartHandler?, progress: ProgressHandler?, completion: CompletionHandler?) {
        
        startHandler = start
        progressHandler = progress
        completionHandler = completion
    }
    
    public func start(taskCount: Int) {
        
        self.taskCount = taskCount
        finishCount = 0
        doubleValue = 0
        startAnimation(self)
        startHandler?()
    }
    
    func finish(count: Int) {
        
        finishCount += count
        doubleValue = Double(finishCount)/Double(taskCount)
        progressHandler?(doubleValue)
        
        if finishCount == taskCount {
            completionHandler?()
        }
    }
}
