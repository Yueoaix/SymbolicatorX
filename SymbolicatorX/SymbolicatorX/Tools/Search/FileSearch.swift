//
//  FileSearch.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/14.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class FileSearch {
    
    static func search(fileExtension: String, directory: String, recursive: Bool) -> [String]? {
        
        let nonDottedExtension = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased()
        
        return enumerator(directory: directory, recursive: recursive)?.compactMap({ (url) -> String? in
            guard let url = url as? URL else { return nil }
            
            if url.pathExtension.lowercased() == nonDottedExtension {
                return url.path
            }
            
            return nil
        })
    }
    
    private static func enumerator(directory: String, recursive: Bool) -> FileManager.DirectoryEnumerator? {
        
        let enumerationURL = URL(fileURLWithPath: (directory as NSString).expandingTildeInPath)
        
        var enumerationOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        if !recursive {
            enumerationOptions.formUnion(.skipsSubdirectoryDescendants)
        }
        
        return FileManager.default.enumerator(at: enumerationURL, includingPropertiesForKeys: nil, options: enumerationOptions, errorHandler: nil)
    }

}
