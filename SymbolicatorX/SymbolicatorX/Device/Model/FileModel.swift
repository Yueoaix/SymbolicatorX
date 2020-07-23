//
//  FileModel.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/23.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation

struct FileModel {
    
    let path: String
    let isDirectory: Bool
    var date: Date?
    let name: String
    let `extension`: String
    
    
    init(filePath: String, fileInfo: [String]) {
        
        var fileInfoDict = [String:String]()
        for i in stride(from: 0, to: fileInfo.count, by: 2) {
            fileInfoDict[fileInfo[i]] = fileInfo[i+1]
        }
        
        path = filePath
        name = (filePath as NSString).lastPathComponent
        `extension` = (filePath as NSString).pathExtension
        isDirectory = fileInfoDict["st_ifmt"] == "S_IFDIR"
        if let mtimeStr = fileInfoDict["st_mtime"], var mtime = TimeInterval(mtimeStr) {
            mtime /= 1000000000
            date = Date(timeIntervalSince1970: mtime)
        }
    }
}
