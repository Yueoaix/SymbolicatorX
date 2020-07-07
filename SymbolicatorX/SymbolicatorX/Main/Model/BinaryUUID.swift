//
//  BinaryUUID.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/7.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Foundation

struct BinaryUUID: Equatable {
    
    let raw: String

    var pretty: String {
        
        let distribution = [8, 4, 4, 4]
        var characters = raw.map { String($0) }
        var pointer = 0
        distribution.enumerated().forEach { offset, dashPosition in
            pointer += dashPosition
            characters.insert("-", at: pointer + offset)
        }
        return characters.joined().uppercased()
    }

    init?(_ string: String) {

        let value = string.lowercased()

        let dashless = value.replacingOccurrences(of: "-", with: "")
        
        if value.count == 36, dashless.count == 32 {
            
            let components = value.components(separatedBy: "-")
            let distribution = [8, 4, 4, 4, 12]
            let isValid = distribution.enumerated().allSatisfy { offset, expectedCount in
                components[offset].count == expectedCount
            }

            guard isValid else { return nil }
        } else if value.count == 32, dashless.count == 32 {
            
        } else {
            return nil
        }

        guard dashless.trimmingCharacters(in: .init(charactersIn: "0123456789abcdef")).isEmpty else {
            return nil
        }

        raw = dashless
    }
}
