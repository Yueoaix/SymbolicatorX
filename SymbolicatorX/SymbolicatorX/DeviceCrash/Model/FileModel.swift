//
//  FileModel.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/23.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation

class FileModel {
    
    typealias CompletionHandler = () -> Void
    
    let path: String
    let isDirectory: Bool
    var date: Date?
    var dateStr: String = ""
    let name: String
    let `extension`: String
    var afc: AfcClient?
    var data: Data? {
        
        guard let afcClient = afc, !isDirectory else { return nil }
        
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
    
    public func allFileCount() -> Int {
        
        var count = 0
        if isDirectory {
            children.forEach { (file) in
                count += file.allFileCount()
            }
        }else{
            count = 1
        }
        
        return count
    }
    
    public func save(toPath path: URL, completion: @escaping CompletionHandler) {
        
        if isDirectory {
            
            children.forEach({ (file) in
                let file = file
                let subPath = path.appendingPathComponent(file.name)
                file.save(toPath: subPath, completion: completion)
            })
            return
        }
        
        do {
            let directoryPath = path.deletingLastPathComponent()
            var isDirectory: ObjCBool = false
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: directoryPath.absoluteString, isDirectory: &isDirectory) || !isDirectory.boolValue {
                
                try fileManager .createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
            }
            try data?.write(to: path, options: .atomic)
            completion()
        } catch {
            print(error)
        }
    }
    
}

// MARK: - Upload Data
extension FileModel {
    
    func makeFileModel(filePath: String, afcClient: AfcClient) -> FileModel? {
        
        guard let fileInfo = try? afcClient.getFileInfo(path: filePath) else { return nil }
        
        return FileModel(filePath: filePath, fileInfo: fileInfo, afcClient: afcClient)
    }
    
    func uploadFiles(fileURLs: [URL], completion: @escaping CompletionHandler) throws {
        
        guard
            let afcClient = afc
            else { return }
        
        _ = children
        for fileUrl in fileURLs {
            
            defer {
                completion()
            }
            
            let uploadFilePath = (path as NSString).appendingPathComponent(fileUrl.lastPathComponent)
            var uploadFileModel = makeFileModel(filePath: uploadFilePath, afcClient: afcClient)
            
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: fileUrl.path, isDirectory: &isDirectory)
            else {
                print("⚠️ File not found :\(uploadFilePath)")
                continue
            }
            
            if isDirectory.boolValue {
                
                if !(uploadFileModel?.isDirectory ?? false) {
                    
                    try afcClient.makeDirectory(path: uploadFilePath)
                    uploadFileModel = makeFileModel(filePath: uploadFilePath, afcClient: afcClient)
                }
                
                guard let uploadFileModel = uploadFileModel
                else {
                    print("⚠️ Failed to create directory :\(uploadFilePath)")
                    continue
                }
                
                let subFileUrls = try FileManager.default.contentsOfDirectory(at: fileUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                children.insert(uploadFileModel, at: 0)
                try uploadFileModel.uploadFiles(fileURLs: subFileUrls, completion: completion)
            }else{
                
                guard uploadFileModel == nil
                else {
                    print("⚠️ File already exists :\(uploadFilePath)")
                    continue
                }
                
                let handle = try afcClient.fileOpen(filename: uploadFilePath, fileMode: .wrOnly)
                try afcClient.fileWrite(handle: handle, fileURL: fileUrl)
                try afcClient.fileClose(handle: handle)
                uploadFileModel = makeFileModel(filePath: uploadFilePath, afcClient: afcClient)
                if let uploadFileModel = uploadFileModel {
                    children.insert(uploadFileModel, at: 0)
                }
            }
        }
    }
}
