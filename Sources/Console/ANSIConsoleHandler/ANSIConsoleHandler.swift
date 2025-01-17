import Foundation
import Logging

private final actor ANSIConsoleHandlerStateHolder {
    private var isInInteractiveMode: Bool = false

    /// Tries to switch mode, returns success or failure
    @discardableResult
    private func switchInteractive(on: Bool) -> Bool {
        switch (isInInteractiveMode, on) {
        case (true, true):
            return false
        case (_, false):
            isInInteractiveMode = false
            return true
        case (false, true):
            isInInteractiveMode = true
            return true
        }
    }

    func performInInteractiveMode<Value>(
        file: StaticString,
        line: UInt,
        operation: () async throws -> Value
    ) async rethrows -> Value {
        guard switchInteractive(on: true) else {
            fatalError(
                    """
                    Some interactive component is already running.

                    This could happen if you tried to launch several interactive console components concurrently.
                    It's allowed only inside of `Console.task`.
                    """,
                    file: file,
                    line: line
            )
        }
        defer { switchInteractive(on: false) }

        return try await operation()
    }
}

extension ConsoleContext {
    private enum StateHolderKey: ConsoleContextKey {
        static let defaultValue: ANSIConsoleHandlerStateHolder = .init()
    }

    fileprivate var stateHolder: ANSIConsoleHandlerStateHolder {
        get { self[StateHolderKey.self] }
        set { self[StateHolderKey.self] = newValue }
    }
}

/// Default ``ConsoleHandler`` used in console library
public struct ANSIConsoleHandler: ConsoleHandler {
    /// Frames per second which interactive console will try to perform
    static let targetFps: UInt64 = 30
    /// Tick delay in milliseconds
    static let tickDelayMs: UInt64 = UInt64((1.0 / Double(targetFps)) * 1000)
    /// Tick delay in nanoseconds
    static let tickDelayNs: UInt64 = tickDelayMs * 1_000_000

    let terminal: ANSITerminal

    public var isAtTTY: Bool {
        return isatty(STDOUT_FILENO) > 0
    }

    public var isInteractive: Bool {
        #if Xcode
        return false
        #else
        return isAtTTY
        #endif
    }

    public var logLevel: Logger.Level

    public init(terminal: ANSITerminal = .shared, logLevel: Logger.Level = .info) {
        self.terminal = terminal
        self.logLevel = logLevel
    }

    enum ConsoleHandlerError: Error {
        case eventStreamFinished
        case componentFinishedWithoutResult
        case notAtTTY
        case noActiveTrace
    }

    struct RenderingState {
        var lastRender: ConsoleRender
        var lastRenderedLines: Int
        var fullRender: Bool = true
        var terminalSize: Size {
            willSet {
                fullRender = newValue != terminalSize
            }
        }
        var lastRenderCursorPos: Position
    }

    func run<Value, Component: ConsoleComponent<Value>>(
        _ component: Component,
        file: StaticString,
        line: UInt
    ) async throws -> Value {
        if let activeContainer = ConsoleContext.current.activeContainer {
            await activeContainer.add(child: component)
            while await component.isUnfinished {
                try await Task.sleep(nanoseconds: ANSIConsoleHandler.tickDelayNs)
            }
            guard let result = await component.result else {
                throw ConsoleHandlerError.componentFinishedWithoutResult
            }
            return try result.get()
        }

        return try await ConsoleContext.current.stateHolder.performInInteractiveMode(file: file, line: line) {
            var state: RenderingState = .init(
                lastRender: .empty,
                lastRenderedLines: 0,
                terminalSize: terminal.size,
                lastRenderCursorPos: terminal.readCursorPos()
            )

            if isInteractive {
                defer { terminal.disableNonBlockingTerminal() }

                do {
                    repeat {
                        guard let event = getControlEvent(state: &state) else {
                            continue
                        }

                        await component.handle(event: event)

                        let renderer = await component.renderer()

                        state.terminalSize = terminal.size
                        render(component: renderer.render(preferredSize: state.terminalSize), state: &state)

                        if case .tick = event {
                            try await Task.sleep(nanoseconds: ANSIConsoleHandler.tickDelayNs)
                        }
                    } while await component.isUnfinished

                    cleanLastRender(state: state)
                } catch let error as CancellationError {
                    await finalize(component: component, state: state)
                    throw error
                }
            }

            await finalize(component: component, state: state)

            guard let result = await component.result else {
                throw ConsoleHandlerError.componentFinishedWithoutResult
            }

            return try result.get()
        }
    }

    private func finalize<Value, Component: ConsoleComponent<Value>>(
        component: Component,
        state: RenderingState
    ) async {
        let renderer = await component.renderer()
        renderNonInteractive(component: renderer.render(preferredSize: state.terminalSize))
    }

    private func cleanLastRender(state: RenderingState) {
        moveToRenderStart(state: state)
        terminal.clearBelow()
    }

    private func moveToRenderStart(state: RenderingState) {
        let linesToMoveUp: Int
        if let position = state.lastRender.cursorPosition {
            linesToMoveUp = position.row
        } else {
            linesToMoveUp = state.lastRenderedLines
        }

        if linesToMoveUp > 0 {
            terminal.moveUp(linesToMoveUp)
        }
        terminal.moveToColumn(1)
    }

    private func getControlEvent(state: inout RenderingState) -> ConsoleControlEvent? {
        let event: ConsoleControlEvent
        if terminal.keyPressed() {
            let char = terminal.readChar()
            switch char {
            case .escape:
                let sequence = terminal.readEscapeSequence()
                switch sequence {
                case let .key(code, meta):
                    event = .inputEscapeSequence(code: code, meta: meta)
                case .cursor:
                    return nil
                case let .screen(size):
                    if size != state.terminalSize {
                        state.terminalSize = size
                        state.fullRender = true
                    }
                    return nil
                case let .unknown(raw):
                    fatalError("Unknown command \(raw.replacingOccurrences(of: String.ESC, with: "^"))")
                }
            default:
                event = .inputChar(char)
            }
        } else {
            event = .tick
        }

        return event
    }

    private func render(component: ConsoleRender, state: inout RenderingState) {
        terminal.cursorOff()
        moveToRenderStart(state: state)

        let newActualLines = component.lines.count
        let linesToRender = min(state.terminalSize.rows - 1, newActualLines)
        let firstLineToRender = newActualLines - linesToRender

        for line in firstLineToRender ..< newActualLines {
            let lineToRender = component.lines[line]
            let oldLine = state.lastRenderedLines - state.lastRender.lines.count + line
            if state.lastRender.lines.indices.contains(oldLine) && lineToRender == state.lastRender.lines[oldLine] && !state.fullRender {
                terminal.moveDown()
            } else {
                terminal.write(lineToRender.trimmed(to: state.terminalSize.cols).terminalStylize())
                terminal.clearToEndOfLine()
                terminal.writeln()
            }
        }
        terminal.write("AI")
        terminal.clearBelow()

        state.lastRenderCursorPos.row += -state.lastRenderedLines + linesToRender
        state.lastRenderCursorPos.row = min(state.terminalSize.rows, state.lastRenderCursorPos.row)
        state.lastRender = component
        state.lastRenderedLines = linesToRender
        state.fullRender = false

        if let position = component.cursorPosition {
            terminal.moveUp(linesToRender - position.row + (newActualLines - linesToRender))
            terminal.moveToColumn(position.col)
            terminal.cursorOn()
        }
    }

    func renderNonInteractive(component: ConsoleRender) {
        for line in component.lines {
            if isInteractive {
                terminal.writeln(line.terminalStylize())
            } else {
                terminal.writeln(line.description)
            }
        }
        if isInteractive {
            terminal.cursorOn()
        }
    }
}

enum ConsoleControlEvent {
    case tick
    case inputChar(Character)
    case inputEscapeSequence(code: ANSIKeyCode, meta: [ANSIMetaCode])
}

protocol ConsoleComponent<Value> {
    associatedtype Value = Void
    associatedtype ComponentRenderer: Renderer<Void>

    var result: Result<Value, Error>? { get async }
    var canBeCollapsed: Bool { get async }

    func handle(event: ConsoleControlEvent) async
    func renderer() async -> ComponentRenderer
}

extension ConsoleComponent {
    func typeErasedRenderer() async -> AnyRenderer<Void> {
        await renderer().asAnyRenderer
    }
}

protocol Renderer<State> {
    associatedtype State
    func render(state: State, preferredSize: Size?) -> ConsoleRender
}

extension Renderer where State == Void {
    func render(preferredSize: Size?) -> ConsoleRender {
        render(state: (), preferredSize: preferredSize)
    }
}

struct AnyRenderer<State>: Renderer {
    let renderUpstream: (State, Size?) -> ConsoleRender

    init<Upstream: Renderer>(upstream: Upstream) where Upstream.State == State {
        renderUpstream = { state, preferredSize in
            upstream.render(state: state, preferredSize: preferredSize)
        }
    }

    func render(state: State, preferredSize: Size?) -> ConsoleRender {
        renderUpstream(state, preferredSize)
    }
}

extension Renderer {
    var asAnyRenderer: AnyRenderer<State> {
        AnyRenderer(upstream: self)
    }
}

struct LRUCache<Key: Hashable, Value> {
    private let size: Int
    private var values: [Key: Value] = [:]
    private var keyQueue: [Key] = []
    private var keyIndex: [Key: Int] = [:]

    init(size: Int) {
        self.size = size
    }

    mutating func refer(to key: Key, value valueFactory: () -> Value) -> Value {
        if let keyCacheIndex = keyIndex[key], let value = values[key] {
            keyQueue.remove(at: keyCacheIndex)
            keyQueue.insert(key, at: 0)
            keyIndex[key] = 0
            return value
        }

        if keyQueue.count >= size {
            let lastKey = keyQueue.removeLast()
            keyIndex.removeValue(forKey: lastKey)
            values.removeValue(forKey: lastKey)
        }

        let value = valueFactory()

        keyQueue.insert(key, at: 0)
        keyIndex[key] = 0
        values[key] = value

        return value
    }
}

enum RenderCache {
    struct Key: Hashable {
        let state: AnyHashable
        let preferredSize: Size?

        init<State: Hashable>(state: State, preferredSize: Size?) {
            self.state = AnyHashable(state)
            self.preferredSize = preferredSize
        }
    }
    static var cache: LRUCache<Key, ConsoleRender> = .init(size: 500)
}

struct CachedRenderer<Upstream: Renderer>: Renderer where Upstream.State: Hashable {
    let upstream: Upstream

    func render(state: Upstream.State, preferredSize: Size?) -> ConsoleRender {
        RenderCache.cache.refer(to: .init(state: state, preferredSize: preferredSize)) {
            upstream.render(state: state, preferredSize: preferredSize)
        }
    }
}

extension Renderer where State: Hashable {
    func withCache() -> some Renderer<State> {
        CachedRenderer(upstream: self)
    }
}

struct BakedStateRenderer<Upstream: Renderer>: Renderer  {
    let upstream: Upstream
    let bakedState: Upstream.State

    func render(state: Void, preferredSize: Size?) -> ConsoleRender {
        upstream.render(state: bakedState, preferredSize: preferredSize)
    }
}

extension Renderer {
    func withState(state: State) -> some Renderer<Void> {
        BakedStateRenderer(upstream: self, bakedState: state)
    }
}

extension ConsoleComponent {
    var isFinished: Bool {
        get async {
            return await result != nil
        }
    }

    var isUnfinished: Bool {
        get async {
            return await result == nil
        }
    }
}

protocol ContainerConsoleComponent: AnyObject {
    var parent: ContainerConsoleComponent? { get }
    var children: [any ConsoleComponent] { get async }

    func add(child: any ConsoleComponent) async
}

struct ConsoleRender {
    /// Component textual layout
    var lines: [ConsoleText]

    var cursorPosition: Position?

    var actualLineCount: Int {
        lines.lazy
            .map { $0.fragments.map(\.string).joined() }
            .flatMap { $0.components(separatedBy: .newlines) }
            .count
    }

    static let empty: Self = .init(lines: [])
}
