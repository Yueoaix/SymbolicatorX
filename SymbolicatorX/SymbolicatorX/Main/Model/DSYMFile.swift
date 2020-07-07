//
//  DSYMModel.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/7.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation

public struct DSYMFile {
    
    let path: URL
    let filename: String
    var uuids: [Architecture: BinaryUUID]
    var binaryPath: String {
        
        let dwarfPath = path.appendingPathComponent("Contents").appendingPathComponent("Resources").appendingPathComponent("DWARF")
        
        guard let binary = (try? FileManager.default.contentsOfDirectory(atPath: dwarfPath.path))?.first else {
            return path.path
        }
        
        return dwarfPath.appendingPathComponent(binary).path
    }

    public init(path: URL) {
    
        self.path = path
        self.filename = path.lastPathComponent

        let output = "dwarfdump --uuid '\(path.path)'".run().output?.trimmed
        var uuids = [Architecture: BinaryUUID]()

        output?.components(separatedBy: .newlines).forEach { line in
            guard
                let match = line.scan(pattern: "UUID: (.*) \\((.*)\\)").first, match.count == 2,
                let uuid = match.first.flatMap(BinaryUUID.init),
                let architecture = match.last.flatMap(Architecture.init)
            else { return }

            uuids[architecture] = uuid
        }

        self.uuids = uuids
    }

    func canSymbolicate(_ crashFile: CrashFile) -> Bool? {
        guard
            let crashUUID = crashFile.uuid,
            !uuids.values.isEmpty
        else { return nil }

        return uuids.values.contains(crashUUID)
    }
}
