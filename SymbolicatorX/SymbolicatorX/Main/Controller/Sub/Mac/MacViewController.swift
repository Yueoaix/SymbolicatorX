//
//  MacViewController.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/5.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class MacViewController: BaseViewController {
    
    private var crashFile: CrashFile?
    private var dsymFile: DSYMFile?
    private var isSymbolicating = false
    
    private let textWindowController = TextWindowController()
    private let crashFileDropZoneView = DropZoneView(fileTypes: [".crash", ".txt"], text: "Drop Crash Report or Sample")
    private let dsymFileDropZoneView = DropZoneView(fileTypes: [".dSYM"], text: "Drop App DSYM")
    
    private let symbolicateButton = NSButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        setupUI()
    }
}

// MARK: - Action
extension MacViewController {
    
    @objc private func didClickSymbolicateBtn(_ sender: NSButton) {
        textWindowController.showWindow(nil)
        guard
            !isSymbolicating,
            let crashFile = crashFile,
            let dsymFile = dsymFile
        else { return }
        
        isSymbolicating = true
        
        Symbolicator.symbolicate(crashFile: crashFile, dsymFile: dsymFile, errorHandler: { [weak self] (error) in
            
            self?.isSymbolicating = false
            print(error)
        }) { [weak self] (content) in
            
            self?.isSymbolicating = false
            print(content)
        }
    }
}

// MARK: - DropZoneViewDelegate
extension MacViewController: DropZoneViewDelegate {
    
    func receivedFile(dropZoneView: DropZoneView, fileURL: URL) {
        
        if dropZoneView == crashFileDropZoneView {
            
            crashFile = CrashFile(path: fileURL)
            if let crashFile = crashFile, dsymFile?.canSymbolicate(crashFile) != true {
                
                startSearchForDSYM()
            }
        } else if dropZoneView == dsymFileDropZoneView {
            
            dsymFile = DSYMFile(path: fileURL)
            dsymFileDropZoneView.setDetailText(dsymFile?.path.path)
        }
    }
}

// MARK: - Search
extension MacViewController {
    
    private func startSearchForDSYM() {
        
        guard let crashFile = crashFile, let crashFileUUID = crashFile.uuid
            else { return }
        
        dsymFileDropZoneView.setDetailText("Searching…")
        
        DSYMSearch.search(forUUID: crashFileUUID.pretty, crashFileDirectory: crashFile.path.deletingLastPathComponent().path, errorHandler: { (error) in
            
            print("DSYM Search Error: \(error)")
        }) { [weak self] (result) in
            
            defer {
                self?.dsymFileDropZoneView.setDetailText(self?.dsymFile?.path.path)
            }
            
            guard let `self` = self, let foundDSYMPath = result else { return }
            
            let foundDSYMURL = URL(fileURLWithPath: foundDSYMPath)
            self.dsymFile = DSYMFile(path: foundDSYMURL)
            self.dsymFileDropZoneView.setFile(foundDSYMURL)
        }
    }
}

// MARK: - UI
extension MacViewController {
    
    private func setupUI() {
        
        crashFileDropZoneView.translatesAutoresizingMaskIntoConstraints = false
        crashFileDropZoneView.delegate = self
        view.addSubview(crashFileDropZoneView)
        crashFileDropZoneView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(240)
        }
        
        dsymFileDropZoneView.translatesAutoresizingMaskIntoConstraints = false
        dsymFileDropZoneView.delegate = self
        view.addSubview(dsymFileDropZoneView)
        dsymFileDropZoneView.snp.makeConstraints { (make) in
            make.top.right.equalToSuperview()
            make.width.height.equalTo(crashFileDropZoneView)
        }
        
        symbolicateButton.translatesAutoresizingMaskIntoConstraints = false
        symbolicateButton.title = "Symbolicate"
        symbolicateButton.bezelStyle = .rounded
        symbolicateButton.focusRingType = .none
        symbolicateButton.target = self
        symbolicateButton.action = #selector(didClickSymbolicateBtn(_:))
        view.addSubview(symbolicateButton)
        symbolicateButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(crashFileDropZoneView.snp.bottom).offset(6)
        }
    }
}
