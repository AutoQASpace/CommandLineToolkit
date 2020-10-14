import DateProvider
import FileSystem
import Foundation
import PathLib
import TestHelpers
import Tmp
import XCTest

final class LocalFileSystemTest: XCTestCase {
    private lazy var dateProvider = SystemDateProvider()
    private lazy var fileManager = FileManager()
    private lazy var fileSystem = LocalFileSystem()
    private lazy var tempFolder = createTempFolder()
    
    func test__enumeration() throws {
        let expectedPaths = try createTestDataForEnumeration(tempFolder: tempFolder)
        let enumerator = fileSystem.contentEnumerator(forPath: tempFolder.absolutePath, style: .deep)
        
        var paths = Set<AbsolutePath>()
        try enumerator.each { (path: AbsolutePath) in
            paths.insert(path)
        }
        
        XCTAssertEqual(expectedPaths, paths)
    }
    
    func test___creating_directory() throws {
        let path = tempFolder.pathWith(components: ["new_folder"])
        
        XCTAssertFalse(fileManager.fileExists(atPath: path.pathString))
        try fileSystem.createDirectory(atPath: path, withIntermediateDirectories: true)

        var isDir: ObjCBool = false
        XCTAssertTrue(fileManager.fileExists(atPath: path.pathString, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }
    
    func test___deleting_file() throws {
        let path = try tempFolder.createFile(filename: "file")
        
        try fileSystem.delete(fileAtPath: path)
        XCTAssertFalse(fileManager.fileExists(atPath: path.pathString))
    }
    
    func test___properties() throws {
        let path = try tempFolder.createFile(filename: "file")
        
        let properties = fileSystem.properties(forFileAtPath: path)
        
        XCTAssertEqual(
            try properties.modificationDate(),
            try fileManager.attributesOfItem(atPath: path.pathString)[.modificationDate] as? Date
        )
    }
    
    func test___commonly_used_paths() throws {
        XCTAssertTrue(fileSystem.commonlyUsedPathsProvider is DefaultCommonlyUsedPathsProvider)
    }
}
