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
    
    private var crashFile: CrashFile?
    private var dsymFile: DSYMFile?
    private var isSymbolicating = false
    
    private let textWindowController = SymbolicatedWindowController()
    private let crashFileDropZoneView = DropZoneView(fileTypes: [".crash", ".txt"], text: "Drop Crash Report or Sample")
    private let dsymFileDropZoneView = DropZoneView(fileTypes: [".dSYM"], text: "Drop App DSYM")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        setupUI()
    }
}

// MARK: - Symbolicate
extension MainViewController {
    
    public func symbolicate() {
        
        guard
            !isSymbolicating,
            let crashFile = crashFile,
            let dsymFile = dsymFile
            else { return }
        
        isSymbolicating = true
        
        Symbolicator.symbolicate(crashFile: crashFile, dsymFile: dsymFile, errorHandler: { [weak self] (error) in
            
            DispatchQueue.main.async {
                self?.isSymbolicating = false
            }
        }) { [weak self] (content) in
            
            DispatchQueue.main.async {
                self?.isSymbolicating = false
                self?.textWindowController.showWindow(nil)
                self?.textWindowController.text = content
                self?.textWindowController.saveUrl = crashFile.symbolicatedContentSaveURL
            }
        }
    }
}

// MARK: - DropZoneViewDelegate
extension MainViewController: DropZoneViewDelegate {
    
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
extension MainViewController {
    
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
extension MainViewController {
    
    private func setupUI() {
        
        crashFileDropZoneView.translatesAutoresizingMaskIntoConstraints = false
        crashFileDropZoneView.delegate = self
        view.addSubview(crashFileDropZoneView)
        crashFileDropZoneView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(240)
        }
        
        dsymFileDropZoneView.translatesAutoresizingMaskIntoConstraints = false
        dsymFileDropZoneView.delegate = self
        view.addSubview(dsymFileDropZoneView)
        dsymFileDropZoneView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.top.width.height.equalTo(crashFileDropZoneView)
        }
    }
}
