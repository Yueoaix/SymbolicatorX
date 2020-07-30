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
    
    var crashFile: CrashFile? {
        didSet {
            if let crashFile = crashFile, dsymFile?.canSymbolicate(crashFile) != true {
                
                crashFileDropZoneView.setFile(crashFile.path)
                dsymFileDropZoneView.reset()
                startSearchForDSYM()
            }
        }
    }
    
    private var dsymFile: DSYMFile? {
        didSet {
            dsymFileDropZoneView.setDetailText(dsymFile?.path.path)
        }
    }
    
    private var isSymbolicating = false
    
    private let textWindowController = SymbolicatedWindowController()
    private let crashFileDropZoneView = DropZoneView(fileTypes: [".crash", ".txt"], text: "Drop Crash Report or Sample")
    private let dsymFileDropZoneView = DropZoneView(fileTypes: [".dSYM"], text: "Drop App DSYM")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        setupUI()
    }
    
    private func alert(message: String) {
        
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: view.window!, completionHandler: nil)
    }
}

// MARK: - Symbolicate
extension MainViewController {
    
    public func symbolicate() {
        
        if self.crashFile == nil {
            alert(message: "No Crash File")
        } else if self.dsymFile == nil {
            alert(message: "No DSYM File")
        }
        
        guard
            !isSymbolicating,
            let crashFile = crashFile,
            let dsymFile = dsymFile
        else { return }
        
        isSymbolicating = true
        
        Symbolicator.symbolicate(crashFile: crashFile, dsymFile: dsymFile, errorHandler: { [weak self] (error) in
            
            DispatchQueue.main.async {
                self?.alert(message: error)
                self?.isSymbolicating = false
            }
        }) { [weak self] (content) in
            
            DispatchQueue.main.async {
                self?.isSymbolicating = false
                self?.textWindowController.showWindow(nil)
                self?.textWindowController.fileName = crashFile.filename
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
        } else if dropZoneView == dsymFileDropZoneView {
            
            dsymFile = DSYMFile(path: fileURL)
        }
    }
}

// MARK: - Search
extension MainViewController {
    
    private func startSearchForDSYM() {
        
        guard let crashFile = crashFile, let crashFileUUID = crashFile.uuid
            else { return }
        
        dsymFileDropZoneView.setDetailText("Searching…")
        
        DSYMSearch.search(forUUID: crashFileUUID.pretty, crashFileDirectory: crashFile.path?.deletingLastPathComponent().path, errorHandler: { (error) in
            
            print("DSYM Search Error: \(error)")
        }) { [weak self] (result) in
            
            DispatchQueue.main.async {
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
