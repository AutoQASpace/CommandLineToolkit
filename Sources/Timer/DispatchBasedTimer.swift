import Dispatch
import Foundation

public final class DispatchBasedTimer {
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "DispatchBasedTimer.queue")
    private let deadline: DispatchTime
    private let repeating: DispatchTimeInterval
    private let leeway: DispatchTimeInterval

    public init(deadline: DispatchTime = .now(), repeating: DispatchTimeInterval, leeway: DispatchTimeInterval) {
        self.deadline = deadline
        self.repeating = repeating
        self.leeway = leeway
    }
    
    public static func startedTimer(
        deadline: DispatchTime = .now(),
        repeating: DispatchTimeInterval,
        leeway: DispatchTimeInterval,
        handler: @escaping (DispatchBasedTimer) -> ())
        -> DispatchBasedTimer
    {
        let timer = DispatchBasedTimer(deadline: deadline, repeating: repeating, leeway: leeway)
        timer.start(handler: handler)
        return timer
    }
    
    deinit {
        stop()
    }
    
    public func start(handler: @escaping (DispatchBasedTimer) -> ()) {
        stop()
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: deadline, repeating: repeating, leeway: leeway)
        timer.setEventHandler(handler: { handler(self) })
        timer.resume()
        self.timer = timer
    }
    
    public func stop() {
        timer?.cancel()
        timer?.setEventHandler(handler: nil)
    }
    
    public func pause() {
        timer?.suspend()
    }
    
    public func resume() {
        timer?.resume()
    }
}
