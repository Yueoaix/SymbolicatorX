//
//  CrashFile.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/8.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation

public struct CrashFile {
    
    enum CrashFileType {
        case mobile
        case crash
        case crashinfo
    }
    
    var crashFileType: CrashFileType
    var path: URL?
    let filename: String
    var processName: String?
    var responsible: String?
    var bundleIdentifier: String?
    var architecture: Architecture?
    var loadAddress: String?
    var addresses: [String]?
    var version: String?
    var buildVersion: String?
    var uuid: BinaryUUID?
    var content: String = ""
    var symbolicatedContent: String?
    var symbolicatedContentSaveURL: URL? {
        
        guard let path = path, crashFileType == .crash else { return nil }
        
        let originalPathExtension = path.pathExtension
        let extensionLessPath = path.deletingPathExtension()
        let newFilename = extensionLessPath.lastPathComponent.appending("_symbolicated")
        return extensionLessPath.deletingLastPathComponent().appendingPathComponent(newFilename).appendingPathExtension(originalPathExtension)
    }
    
    public init?(path: URL) {
        
        guard
            var content = try? String(contentsOf: path, encoding: .utf8),
            content.trimmingCharacters(in: .whitespacesAndNewlines) != ""
        else {
            return nil
        }
        
        if path.pathExtension == "ips" {
            content = CrashTranslator.convertFromJSON(jsonFile: content)
        }
        
        self.path = path
        self.filename = path.lastPathComponent
        if path.pathExtension == "crashinfo" {
            self.crashFileType = .crashinfo
            crashInfoConfig(content: content)
        }else{
            self.crashFileType = .crash
            config(content: content)
        }
    }
    
    init?(file: FileModel) {
        guard
            let data = file.data,
            var content = String(data: data, encoding: .utf8),
            content.trimmingCharacters(in: .whitespacesAndNewlines) != ""
        else {
            return nil
        }
        
        if file.pathExtension == "ips" {
            content = CrashTranslator.convertFromJSON(jsonFile: content)
        }
        
        self.path = URL(fileURLWithPath: file.path)
        self.filename = file.name
        self.crashFileType = .mobile
        config(content: content)
    }
    
    private mutating func crashInfoConfig(content: String) {
        self.content = content
        self.bundleIdentifier = content.scan(
            pattern: "Loaded modules:.*?0x.*? - 0x.*?\\s+(.*?)\\s+",
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).first?.first?.trimmed
        self.processName = self.bundleIdentifier
        self.architecture = content.scan(pattern: "^CPU: (.*?)(\\(.*\\))?$").first?.first?.trimmed.components(separatedBy: " ").first.flatMap(Architecture.init)
        
        self.loadAddress = content.scan(
            pattern: "Loaded modules:.*?(0x.*?)\\s",
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).first?.first?.trimmed
        
        let loadAddressHex = loadAddress?.hex() ?? 0
        self.addresses = content.scan(
            pattern: "^\\s?\\d+\\s+\(bundleIdentifier ?? "") \\+ (0x.*?)\\n",
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).compactMap({ (addresses) -> String in
            let address = addresses.last ?? ""
            let addressHex = address.hex() ?? 0
            let realAddress = String(format: "0x%lx", loadAddressHex + addressHex)
            self.content = self.content.replacingOccurrences(of: address, with: realAddress)
            return realAddress
        })
        
        self.uuid = (content.scan(
            pattern: "WARNING: No symbols, \(bundleIdentifier ?? ""), (.*?)0\\)",
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).first?.first?.trimmed).flatMap(BinaryUUID.init)
    }
    
    private mutating func config(content: String) {
        self.content = content
        self.processName = content.scan(pattern: "^Process:\\s+(.+?)\\[").first?.first?.trimmed
        self.bundleIdentifier = content.scan(pattern: "^Identifier:\\s+(.+?)$").first?.first?.trimmed
        self.architecture = content.scan(pattern: "^Code Type:(.*?)(\\(.*\\))?$").first?.first?.trimmed
            .components(separatedBy: " ").first.flatMap(Architecture.init)

        if self.architecture?.isIncomplete == true {
            self.architecture = (content.scan(
                pattern: "Binary Images:.*\\s+([^\\s]+)\\s+<",
                options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
            ).first?.first?.trimmed).flatMap(Architecture.init)
        }

        //pattern: "Binary Images:.*?(0x.*?)\\s",
        self.loadAddress = content.scan(
            pattern: "^\\s*(0x[0-9a-fA-F]+)\\s+-\\s+0x[0-9a-fA-F]+[^\\n]+(\(bundleIdentifier ?? "")|\(processName ?? ""))\\s+.*?\\n",
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).first?.first?.trimmed
        
        let crashReportAddresses = content.scan(
            pattern: "^\\d+\\s+(\(bundleIdentifier ?? "")|\(processName ?? "")).*?(0x.*?)\\s",
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).compactMap { $0.last }
        
        let sampleAddresses = content.scan(
            pattern: "\\?{3}\\s+\\(in\\s.*?\\)\\s+load\\saddress.*?\\[(0x.*?)\\]",
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).compactMap { $0.last }
        
        self.addresses = crashReportAddresses + sampleAddresses
        
        self.responsible = content.scan(pattern: "^Responsible:\\s+(.+?)\\[").first?.first?.trimmed
        self.version = content.scan(pattern: "^Version:\\s+(.+?)\\(").first?.first?.trimmed
        self.buildVersion = content.scan(pattern: "^Version:.+\\((.*?)\\)").first?.first?.trimmed
        
        self.uuid = (content.scan(
            pattern: "Binary Images:.*?<(.*?)>",
            options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators]
        ).first?.first?.trimmed).flatMap(BinaryUUID.init)
    }
    
}
