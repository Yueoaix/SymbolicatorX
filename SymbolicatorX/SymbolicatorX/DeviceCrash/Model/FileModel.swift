//
//  FileModel.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/23.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation

class FileModel {
    
    let path: String
    let isDirectory: Bool
    var date: Date?
    var dateStr: String = ""
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
    
    lazy var children: [FileModel] = {
       
        guard isDirectory, let afcClient = afc else { return [] }

        let fileList = try? afcClient.readDirectory(path: path)
        var children = fileList?.compactMap { (fileName) -> FileModel? in
            
            let path = "\(self.path)/\(fileName)"
            guard
                fileName != "." && fileName != "..",
                fileName != ".com.apple.mobile_container_manager.metadata.plist",
                let fileInfo = try? afcClient.getFileInfo(path: path)
            else { return nil }
            
            return FileModel(filePath: path, fileInfo: fileInfo, afcClient: afcClient)
        }
        children?.sort(by: { (file1, file2) -> Bool in
            return file1.date!.compare(file2.date!) == .orderedDescending
        })
        return children ?? []
    }()
    
    
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
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateStr = dateFormatter.string(from: date!)
        }
           
    }
    
    public func save(toPath path: URL) {
        
        if isDirectory {
            
            children.forEach({ (file) in
                let file = file
                let subPath = path.appendingPathComponent(file.name)
                file.save(toPath: subPath)
            })
        }
        
        do {
            let directoryPath = path.deletingLastPathComponent()
            var isDirectory: ObjCBool = false
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: directoryPath.absoluteString, isDirectory: &isDirectory) || !isDirectory.boolValue {
                
                try fileManager .createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
            }
            try data?.write(to: path, options: .atomic)
        } catch {
            print(error)
        }
        
    }
    
}
