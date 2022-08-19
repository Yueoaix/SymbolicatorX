//
//  Symbolicator.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/15.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class Symbolicator {

    typealias CompletionHandler = (String) -> Void
    typealias ErrorHandler = (String) -> Void
    
    static func symbolicate(crashFile: CrashFile, dsymFile: DSYMFile, errorHandler: @escaping ErrorHandler, completion: @escaping CompletionHandler) {
        
        DispatchQueue.global().async {
            
            guard let architecture = crashFile.architecture else {
                errorHandler("Could not detect crash file architecture.")
                return
            }
            
            guard let loadAddress = crashFile.loadAddress else {
                errorHandler("Could not detect application load address from crash report. Application might have crashed during launch.")
                return
            }
            
            guard let addresses = crashFile.addresses, addresses.count > 0 else {
                completion(crashFile.content)
                return
            }
            
            let command = symbolicationCommand(dsymPath: dsymFile.binaryPath,architecture: architecture.atosString!,loadAddress: loadAddress,addresses: addresses)
            let result = command.run()
            
            if let error = result.error?.trimmed, error != "" { errorHandler(error)
                return
            }
            
            guard
                let output = result.output?.trimmed,
                output.components(separatedBy: .newlines).count > 0
            else {
                errorHandler("atos command gave no output")
                return
            }
            
            let outputLines = output.components(separatedBy: .newlines)
            guard addresses.count == outputLines.count else {
                errorHandler("Unexpected result from atos command:\n\(output)")
                return
            }
            
            var replacedContent = crashFile.content
            for index in 0..<outputLines.count {
                
                let address = addresses[index]
                let replacement = outputLines[index]

                if crashFile.crashFileType == .crashinfo {
                    replacedContent = replacedContent.replacingOccurrences(of: address, with: replacement)
                } else {
                    let sampleOccurences = replacedContent.scan(pattern: "\\?{3}.*?\\[\(address)\\]").flatMap { $0 }
                    sampleOccurences.forEach {
                        replacedContent = replacedContent.replacingOccurrences(of: $0, with: "\(replacement) [\(address)]")
                    }

                    let crashOccurences = replacedContent.scan(pattern: "\(address)\\s.*?$").flatMap { $0 }
                    crashOccurences.forEach {
                        replacedContent = replacedContent.replacingOccurrences(of: $0, with: "\(address) \(replacement)")
                    }
                }
            }
            
            completion(replacedContent)
        }
    }
    
    private static func symbolicationCommand(dsymPath: String, architecture: String, loadAddress: String, addresses: [String]) -> String {
        
        let addressesString = addresses.joined(separator: " ")
        let dsymPath = dsymPath.replacingOccurrences(of: " ", with: "\\ ")
        return "xcrun atos -o \(dsymPath) -arch \(architecture) -l \(loadAddress) \(addressesString)"
    }
}
