//
//  LogMessage+CoreDataClass.swift
//  OpenTraceTogether

import Foundation
import CoreData

@objc(LogMessage)
public class LogMessage: NSManagedObject, Encodable {
    enum LogType: Int16 {
        case Trace = 0
        case Debug = 1
        case Info = 2
        case Warn = 3
        case Error = 4
        case Fatal = 5

        func toString() -> String {
            switch self {
            case .Trace: return "Trace"
            case .Debug: return "Debug"
            case .Info: return "Info"
            case .Warn: return "Warn"
            case .Error: return "Error"
            case .Fatal: return "Fatal"
            }
        }
    }

    var type: LogType {
        get { return LogType(rawValue: self.rawType) ?? .Trace }
        set { self.rawType = newValue.rawValue }
    }
}
