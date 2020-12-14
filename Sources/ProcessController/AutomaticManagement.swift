import Foundation
import SignalHandling

public enum AutomaticManagementItem: CustomStringConvertible, Equatable {
    case signalWhenSilent(Signal, TimeInterval)
    case signalAfter(Signal, TimeInterval)
    
    var signal: Signal {
        switch self {
        case .signalAfter(let signal, _):
            return signal
        case .signalWhenSilent(let signal, _):
            return signal
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .signalAfter(_, let interval):
            return interval
        case .signalWhenSilent(_, let interval):
            return interval
        }
    }
    
    public var description: String {
        switch self {
        case let .signalWhenSilent(signal, interval):
            return "send \(signal) when silent for \(interval) sec"
        case let .signalAfter(signal, interval):
            return "send \(signal) after running for \(interval) sec"
        }
    }
}

public struct AutomaticManagement: CustomStringConvertible, Equatable {
    public let items: [AutomaticManagementItem]
    
    public init(items: [AutomaticManagementItem]) {
        self.items = items
    }
    
    public var description: String {
        var elements: [String] = ["\(type(of: self))"]
        if items.isEmpty {
            elements.append("no automatic management")
        } else {
            elements.append("items: \(items)")
        }
        return "<" + elements.joined(separator: " ") + ">"
    }
    
    public static let noManagement = AutomaticManagement(items: [])
    
    public static func multiple(_ items: [AutomaticManagementItem]) -> AutomaticManagement {
        AutomaticManagement(items: items)
    }
    
    public static func sigintThenKillIfSilent(interval: TimeInterval, killAfter: TimeInterval = 15) -> AutomaticManagement {
        AutomaticManagement(
            items: [
                .signalWhenSilent(.int, interval),
                .signalWhenSilent(.kill, interval + killAfter),
            ]
        )
    }
    
    public static func sigtermThenKillIfSilent(interval: TimeInterval, killAfter: TimeInterval = 15) -> AutomaticManagement {
        AutomaticManagement(
            items: [
                .signalWhenSilent(.term, interval),
                .signalWhenSilent(.kill, interval + killAfter),
            ]
        )
    }
    
    public static func sigintThenKillAfterRunningFor(interval: TimeInterval, killAfter: TimeInterval = 15) -> AutomaticManagement {
        AutomaticManagement(
            items: [
                .signalAfter(.int, interval),
                .signalAfter(.kill, interval + killAfter),
            ]
        )
    }
    
    public static func sigtermThenKillAfterRunningFor(interval: TimeInterval, killAfter: TimeInterval = 15) -> AutomaticManagement {
        AutomaticManagement(
            items: [
                .signalAfter(.term, interval),
                .signalAfter(.kill, interval + killAfter),
            ]
        )
    }
}
