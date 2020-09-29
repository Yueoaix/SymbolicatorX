//
//  libSymbolicatorX.swift
//  libSymbolicatorX
//
//  Created by Lory on 27/09/2020.
//  Copyright © 2020 lory. All rights reserved.
//

import Foundation

public class libSymbolicatorX {
    
    public typealias LibCrashFile = CrashFile
    public typealias LibDSYMFile = DSYMFile
    
    public typealias CompletionHandler = (String) -> Void
    public typealias ErrorHandler = (String) -> Void
    
    public static func symbolicate(crashFile: String, dsymFile: String, errorHandler: @escaping ErrorHandler, completion: @escaping CompletionHandler) {
        
        //打开文件
        let crashUrl = URL(fileURLWithPath: "file:/\(crashFile)")
        let dsymUrl = URL(fileURLWithPath: "file:/\(dsymFile)")
        
        guard let cf = LibCrashFile(path: crashUrl) else { return }
        let df = LibDSYMFile(path: dsymUrl)
        
        libSymbolicatorX.symbolicate(crashFile: cf, dsymFile: df, errorHandler: {  (error) in
            
            DispatchQueue.main.async {
                print(error)
                if let content = try? String(contentsOf: crashUrl) {
                    completion(content)
                }
            }
            
        }) { (content) in
            
            DispatchQueue.main.async {
                completion(content)
            }
        }
    }
    
    public static func symbolicate(crashFile: CrashFile, dsymFile: DSYMFile, errorHandler: @escaping ErrorHandler, completion: @escaping CompletionHandler) {
            DispatchQueue.global().async {
                
                guard let architecture = crashFile.architecture else {
                    errorHandler("Could not detect crash file architecture.")
                    return
                }
                
                guard let loadAddress = crashFile.loadAddress else {
                    errorHandler("Could not detect application load address from crash report. Application might have crashed during launch.")
                    return
                }
                
                guard let addresses = crashFile.addressArray[dsymFile.binaryName], addresses.count > 0 else {
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
            return "xcrun atos -o \"\(dsymPath)\" -arch \(architecture) -l \(loadAddress) \(addressesString)"
    }
}
