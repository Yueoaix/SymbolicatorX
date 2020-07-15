//
//  DSYMSearch.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/14.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class DSYMSearch {
    
    typealias CompletionHandler = (String?) -> Void
    typealias ErrorHandler = ([String]) -> Void
    
    static func search(forUUID uuid: String, crashFileDirectory: String, errorHandler: @escaping ErrorHandler, completion: @escaping CompletionHandler) {
        
        let predicate = NSPredicate(format: "com_apple_xcode_dsym_uuids == %@", uuid)
        SpotlightSearch.shared.search(forPredicate: predicate) { (results) in
            
            let foundItem = results?.first(where: { (metadataItem) -> Bool in
                guard let dsymPath = dsymPath(from: metadataItem, withUUID: uuid) else { return false }
                
                completion(dsymPath)
                return true
            })
            
            guard foundItem == nil else { return }
            
            if let results = FileSearch.search(fileExtension: "dsym", directory: crashFileDirectory, recursive: false), let foundUUID = firstMatching(paths: results, uuid: uuid, errorHandler: errorHandler) {
                
                completion(foundUUID)
            } else if let results = FileSearch.search(fileExtension: "dsym", directory: "~/Library/Developer/Xcode/Archives/", recursive: true), let foundUUID = firstMatching(paths: results, uuid: uuid, errorHandler: errorHandler) {
                
                completion(foundUUID)
            } else {
                
                completion(nil)
            }
        }
    }
    
    private static func firstMatching(paths: [String], uuid: String, errorHandler: @escaping ErrorHandler) -> String? {
        
        return paths.first { file in
            let command = "dwarfdump --uuid \"\(file)\""
            let (output, error) = command.run()

            if let errorOutput = error?.trimmed, !errorOutput.isEmpty {
                errorHandler(["\(command):\n\(errorOutput)"])
            }

            guard
                let dwarfDumpOutput = output?.trimmed,
                let foundUUID = dwarfDumpOutput.scan(pattern: "UUID: (.*) \\(").first?.first
            else {
                return false
            }

            return foundUUID == uuid
        }
    }
    
    private static func dsymPath(from metadataItem: NSMetadataItem, withUUID uuid: String) -> String? {
        
        guard
            let filename = metadataItem.value(forAttribute: kMDItemFSName as String) as? String,
            let itemPath = metadataItem.value(forAttribute: NSMetadataItemPathKey as String) as? String
        else { return nil }
        
        if isDSYMFilename(filename) {
            
            return itemPath
        } else if isXCArchiveFilename(filename) {
            
            guard
                let uuids = metadataItem.value(forAttribute: "com_apple_xcode_dsym_uuids") as? [String],
                let paths = metadataItem.value(forAttribute: "com_apple_xcode_dsym_paths") as? [String]
            else { return nil }
            
            if let index = uuids.firstIndex(of: uuid) {
                
                let path: String?
                if paths.count > index {
                    path = paths[index]
                } else {
                    path = paths.first
                }

                guard
                    let foundPath = path,
                    let relativeDSYMPath = foundPath.components(separatedBy: "/Contents/").first
                else { return nil }

                return [itemPath, relativeDSYMPath].joined(separator: "/")
            }
        }
        
        return nil
    }
    
    private static func isDSYMFilename(_ filename: String) -> Bool {
        NSPredicate(format: "SELF ENDSWITH[c] %@", ".dSYM").evaluate(with: filename)
    }

    private static func isXCArchiveFilename(_ filename: String) -> Bool {
        NSPredicate(format: "SELF ENDSWITH[c] %@", ".xcarchive").evaluate(with: filename)
    }
}
