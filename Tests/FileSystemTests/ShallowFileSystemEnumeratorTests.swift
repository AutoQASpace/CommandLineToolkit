import FileSystem
import PathLib
import TestHelpers
import Tmp
import XCTest

final class ShallowFileSystemEnumeratorTests: XCTestCase {
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder(deleteOnDealloc: true) }
    
    func test___enumerating___complete() throws {
        let expectedPaths = try createTestDataForEnumeration(tempFolder: tempFolder).filter {
            $0.components.count == tempFolder.absolutePath.components.count + 1
        }
        
        let enumerator = ShallowFileSystemEnumerator(
            path: tempFolder.absolutePath
        )
        
        var paths = Set<AbsolutePath>()
        try enumerator.each { (path: AbsolutePath) in
            paths.insert(path)
        }
        
        XCTAssertEqual(expectedPaths, paths)
    }
}
