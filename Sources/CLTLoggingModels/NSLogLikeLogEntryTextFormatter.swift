/*
 * Copyright (c) Avito Tech LLC
 */

import Foundation

public final class NSLogLikeLogEntryTextFormatter: LogEntryTextFormatter {
    
    // 2018-03-29 19:05:01.994
    public static let logDateFormatter: DateFormatter = {
        let logFormatter = DateFormatter()
        logFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        logFormatter.timeZone = TimeZone.autoupdatingCurrent
        return logFormatter
    }()
    
    private let logLocation: Bool
    private let logCoordinates: Bool
    
    public init(
        logLocation: Bool,
        logCoordinates: Bool
    ) {
        self.logLocation = logLocation
        self.logCoordinates = logCoordinates
    }
    
    public func format(logEntry: LogEntry) -> String {
        let timeStamp = NSLogLikeLogEntryTextFormatter.logDateFormatter.string(from: logEntry.timestamp)
        
        let filename = (logEntry.file as NSString).lastPathComponent
        
        // [LEVEL] 2018-03-29 19:05:01.994 <file:line> <coordinate1> [<coordinate2> [...]]: <mesage>
        var result = "[\(logEntry.verbosity.stringCode)] \(timeStamp)"
        
        if logLocation {
            result = result + " \(filename):\(logEntry.line)"
        }
        
        if logCoordinates, !logEntry.coordinates.isEmpty {
            result += " " + logEntry.coordinates.map { "\($0.stringValue)" }.joined(separator: " ")
        }
        result += ": " + logEntry.message
        return result
    }
}

extension LogEntryCoordinate {
    public var stringValue: String {
        var result = name
        if let value = value {
            result += ":\(value)"
        }
        return result
    }
}
