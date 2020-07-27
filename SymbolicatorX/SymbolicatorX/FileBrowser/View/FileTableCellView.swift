//
//  FileTableCellView.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/27.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class FileTableCellView: NSTableCellView {
    
    let icon = NSImageView.init()
    let title = NSTextField.init()
    
    var model: FileModel? {
        didSet {
            title.stringValue = model?.name ?? ""
            title.toolTip = title.stringValue
            if model?.isDirectory ?? false {
                icon.image = NSImage.init(named: NSImage.folderName)
            }else{
                icon.image = NSWorkspace.shared.icon(forFileType: model?.extension ?? "")
            }
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    func setupUI() {
        
        // 添加图片
        icon.image = NSImage.init(named: NSImage.folderName)
        addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(5)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        // 添加标题
        title.isBordered = false
        title.isEditable = false
        title.bezelStyle = .roundedBezel
        addSubview(title)
        title.snp.makeConstraints { (make) in
            make.left.equalTo(icon.snp.right).offset(10)
            make.top.bottom.right.equalToSuperview()
        }
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
}
