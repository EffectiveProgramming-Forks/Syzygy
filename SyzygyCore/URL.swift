//
//  URL.swift
//  SyzygyCore
//
//  Created by Dave DeLong on 12/31/17.
//  Copyright © 2017 Dave DeLong. All rights reserved.
//

import Foundation
import Darwin

public extension URL {
    
    public init?(bookmarkData: Data) {
        var stale: Bool = false
        try? self.init(resolvingBookmarkData: bookmarkData, options: [.withoutUI, .withoutMounting], relativeTo: nil, bookmarkDataIsStale: &stale)
    }
    
    public var bookmarkData: Data? {
        return try? self.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
    }
    
    public var parent: URL? { return self.deletingLastPathComponent() }
    
    public func relationship(to other: URL) -> FileManager.URLRelationship {
        var relationship: FileManager.URLRelationship = .other
        _ = try? FileManager.default.getRelationship(&relationship, ofDirectoryAt: self, toItemAt: other)
        return relationship
    }
    
    public func contains(_ other: URL) -> Bool {
        let r = relationship(to: other)
        return (r == .contains || r == .same)
    }
    
    public func removing(pathComponents: String...) -> URL {
        return removing(pathComponents: pathComponents)
    }
    
    public func removing(pathComponents: Array<String>) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return self }
        
        var finalPath = (components.path as NSString).pathComponents
        var toDelete = pathComponents
        
        while finalPath.isEmpty == false && toDelete.isEmpty == false && finalPath.last == toDelete.last {
            _ = finalPath.popLast()
            _ = toDelete.popLast()
        }
        
        components.path = NSString.path(withComponents: finalPath)
        return components.url ?? self
    }
}
