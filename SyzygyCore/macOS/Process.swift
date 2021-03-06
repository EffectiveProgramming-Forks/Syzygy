//
//  Process.swift
//  SyzygyCore
//
//  Created by Dave DeLong on 12/31/17.
//  Copyright © 2017 Dave DeLong. All rights reserved.
//

import Foundation

public extension Process {
    
    public struct ProcessError: Error {
        public let exitCode: Int32
        public let reason: Process.TerminationReason
    }
    
    public struct ApplescriptError: Error {
        public let errorDictionary: NSDictionary
    }
    
    public class func runSynchronously(_ path: AbsolutePath, arguments: Array<String> = []) -> Result<Data> {
        return runAsUser(path, arguments: arguments)
    }
    
    public class func run(process path: AbsolutePath, arguments: Array<String> = [], asAdministrator: Bool = false, completion: @escaping (Result<Data>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result: Result<Data>
            
            if asAdministrator == true {
                result = runAsAdmin(path, arguments: arguments)
            } else {
                result = runAsUser(path, arguments: arguments)
            }
            
            DispatchQueue.main.async { completion(result) }
        }
    }
    
    private class func runAsAdmin(_ path: AbsolutePath, arguments: Array<String>) -> Result<Data> {
        let allArguments = arguments.map { "'\($0)'" }.joined(separator: " ")
        let fullScript = "\(path.fileSystemPath) \(allArguments)"
        
        // may God have mercy on my soul
        let applescriptSource = "do shell script \"\(fullScript)\" with administrator privileges"
        let applescript = NSAppleScript(source: applescriptSource)
        
        var errorInfo: NSDictionary?
        if let eventResult = applescript?.executeAndReturnError(&errorInfo) {
            let string = eventResult.stringValue ?? ""
            return .success(Data(string.utf8))
        } else {
            let error = ApplescriptError(errorDictionary: errorInfo ?? [:])
            return .error(error)
        }
    }
    
    private class func runAsUser(_ path: AbsolutePath, arguments: Array<String>) -> Result<Data> {
        let task = Process()
        task.launchPath = path.fileSystemPath
        task.arguments = arguments
        task.qualityOfService = .userInitiated
        
        let output = TemporaryPath(extension: "txt")
        let handle = output.fileHandle
        defer { handle?.closeFile() }
        
        task.standardOutput = handle
        task.launch()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            let error = ProcessError(exitCode: task.terminationStatus, reason: task.terminationReason)
            return .error(error)
        } else {
            handle?.seek(toFileOffset: 0)
            let data = handle?.readDataToEndOfFile()
            
            return .success(data ?? Data())
        }
    }
}
