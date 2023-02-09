/*
 * Copyright (c) Avito Tech LLC
 */

import CLTLoggingModels
import Foundation

public extension ContextualLogger {
    func debug(
        _ message: String, subprocessPidInfo: PidInfo? = nil, source: String? = nil, file: String = #fileID, function: String = #function, line: UInt = #line
    ) {
        log(.debug, message, subprocessPidInfo: subprocessPidInfo, source: source, file: file, function: function, line: line)
    }
    
    func trace(
        _ message: String, subprocessPidInfo: PidInfo? = nil, source: String? = nil, file: String = #fileID, function: String = #function, line: UInt = #line
    ) {
        log(.trace, message, subprocessPidInfo: subprocessPidInfo, source: source, file: file, function: function, line: line)
    }
    
    func error(
        _ message: String, subprocessPidInfo: PidInfo? = nil, source: String? = nil, file: String = #fileID, function: String = #function, line: UInt = #line
    ) {
        log(.error, message, subprocessPidInfo: subprocessPidInfo, source: source, file: file, function: function, line: line)
    }
    
    func info(
        _ message: String, subprocessPidInfo: PidInfo? = nil, persistentMetricsJobId: String? = nil, source: String? = nil, file: String = #fileID, function: String = #function, line: UInt = #line
    ) {
        log(.info, message, subprocessPidInfo: subprocessPidInfo, source: source, file: file, function: function, line: line)
    }
    
    func warning(
        _ message: String, subprocessPidInfo: PidInfo? = nil, persistentMetricsJobId: String? = nil, source: String? = nil, file: String = #fileID, function: String = #function, line: UInt = #line
    ) {
        log(.warning, message, subprocessPidInfo: subprocessPidInfo, source: source, file: file, function: function, line: line)
    }
}
