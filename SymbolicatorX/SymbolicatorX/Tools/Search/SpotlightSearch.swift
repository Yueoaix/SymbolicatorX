//
//  SpotlightSearch.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/14.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa

class SpotlightSearch {
    
    typealias CompletionHandler = ([NSMetadataItem]?) -> Void
    
    static let shared  = SpotlightSearch()
    private init() {}
    
    private var query: NSMetadataQuery?
    private var completion: CompletionHandler?
    
    func search(forPredicate predicate: NSPredicate, completion: @escaping CompletionHandler) {
        query?.stop()

        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(SpotlightSearch.didFinishGathering),
            name: .NSMetadataQueryDidFinishGathering,
            object: nil
        )

        self.completion = completion
        
        query = NSMetadataQuery()
        query?.predicate = predicate

        if query?.start() == false {
            completion(nil)
        }
    }
    
    @objc private func didFinishGathering() {
        query?.stop()
        completion?(query?.results as? [NSMetadataItem])
    }
}
