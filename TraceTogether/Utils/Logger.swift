//
//  Logger.swift
//  OpenTraceTogether

import Foundation

class Logger {

    static func DLog(_ message: String, file: NSString = #file, line: Int = #line, functionName: String = #function) {
        NSLog("[\(file.lastPathComponent):\(line)][\(functionName)]: \(message)")
    }
}
