//
//  NSTableCellView+Extesnion.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/27.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

extension NSTableCellView {
    
    static func makeCellView(tableView: NSTableView, identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        
        if let cellView = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            
            return cellView
        }else{
            
            let cellView = NSTableCellView()
            cellView.identifier = identifier
            let textField =  NSTextField()
            textField.isEditable = false
            textField.isBezeled = false
            cellView.textField = textField
            textField.bezelStyle = .roundedBezel
            cellView.addSubview(textField)
            textField.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.left.equalToSuperview()
            }
            return cellView
        }
    }
    
}
