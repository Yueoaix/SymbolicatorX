//
//  String+Text.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/17.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation

extension String {
    
    func findRange(pattern: String, options: NSRegularExpression.Options = [.caseInsensitive, .anchorsMatchLines]) -> NSRange? {
        
        let rawRange = NSRange(self.startIndex..<self.endIndex, in: self)
        let regularExpression = try! NSRegularExpression(pattern: pattern, options: options)
        let range = regularExpression.rangeOfFirstMatch(in: self, options: [], range: rawRange)
        if range.location >= rawRange.location + rawRange.length {
            return nil
        }
        
        return range
    }
}

