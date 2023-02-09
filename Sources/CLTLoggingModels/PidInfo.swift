/*
 * Copyright (c) Avito Tech LLC
 */

import Foundation

public struct PidInfo: Hashable {
    public let pid: Int32
    public let name: String

    public init(pid: Int32, name: String) {
        self.pid = pid
        self.name = name
    }
}
