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
    var afc: AfcClient?
    var data: Data? {
        
        guard let afcClient = afc else { return nil }
        
        do {
            let handle = try afcClient.fileOpen(filename: path, fileMode: .rdOnly)
            let data = try afcClient.fileRead(handle: handle)
            try afcClient.fileClose(handle: handle)
            return data
        } catch {
            print(error)
        }
        
        return nil
    }
    
    
    init(filePath: String, fileInfo: [String], afcClient: AfcClient) {
        
        var fileInfoDict = [String:String]()
        for i in stride(from: 0, to: fileInfo.count, by: 2) {
            fileInfoDict[fileInfo[i]] = fileInfo[i+1]
        }
        
        afc = afcClient
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
