//
//  String+Extension.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/7.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation

extension String {
    
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func run() -> (output: String?, error: String?) {
        let pipe = Pipe()
        let errorPipe = Pipe()

        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", self]
        process.standardOutput = pipe
        process.standardError = errorPipe

        let outFileHandle = pipe.fileHandleForReading
        let errFileHandle = errorPipe.fileHandleForReading
        process.launch()

        return (
            String(data: outFileHandle.readDataToEndOfFile(), encoding: .utf8),
            String(data: errFileHandle.readDataToEndOfFile(), encoding: .utf8)
        )
    }

    func scan(pattern: String, options: NSRegularExpression.Options = [.caseInsensitive, .anchorsMatchLines]) -> [[String]] {
        
        let regularExpression = try! NSRegularExpression(pattern: pattern, options: options)
        let matches = regularExpression.matches(in: self, options: [], range: NSRange(self.startIndex..., in: self))
        return matches.map {
            var match = [String]()
            let startIndex = $0.numberOfRanges == 1 ? 0 : 1
            for rangeIndex in startIndex...($0.numberOfRanges - 1) {
                let range = $0.range(at: rangeIndex)
                if let newRange = Range<Index>(range, in: self) {
                    match.append(String(self[newRange]))
                }
            }
            return match
        }
    }
    
    func hex() -> Int? {
        
        if hasPrefix("0x") {
            let str = self[self.index(self.startIndex, offsetBy: 2)..<self.endIndex]
            return Int(str, radix: 16) ?? 0
        }
        
        return Int(self, radix: 16)
    }
}
