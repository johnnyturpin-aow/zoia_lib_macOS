/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


import Foundation
import AppKit



final class AppRouter {
    static let shared = AppRouter()
    
    func openPatchFileInEditor(filePath: URL) {
        
        ZoiaBundle.copyBinFileAsZoiaBundle(filePath: filePath) {
            zEditorFile in
            guard let zEditorFile = zEditorFile else { return }
            NSWorkspace.shared.open(zEditorFile)
        }
    }
}
/*
final class AppRouter {
    
    enum Path: String {
        case nodeView = "/node-view"
    }
    
    static let shared = AppRouter()
    
    static let scheme = "zoialib"
    static let host = "com.polymorphicranch.zoia-lib-mac"
    
    // Unfortunately, a binary patch has no real uniquely identifying information
    // So we use a combination of the patch name and the number of modules in the patch as its uniqueID
    func openNodeView(patch: ParsedBinaryPatch) {
        var components = URLComponents()
        components.scheme = AppRouter.scheme
        components.host = AppRouter.host
        components.path = AppRouter.Path.nodeView.rawValue
        components.queryItems = [
            URLQueryItem(name: "name", value: patch.name),
            URLQueryItem(name: "modules", value: patch.modules.count.description)
        ]
        
        guard let url = components.url else { return }
        NSWorkspace.shared.open(url)
    }
    
}
 */

final class AppFileManager {
    
    let fileManager = FileManager.default
    private static let appFolderName = "ZoiaLib"
    private static let patchFileFolderName = "Library"
    private static let banksFolderName = "Banks"
    private static let factoryBankFolderName = "Factory"
    private static let editorFolderName = "Editor"
    
    static let bundleExtension = ".zbundle"
    //var patchLibraryUrl: URL?
    //var appSupportUrl: URL?
    // makes sure we have our ~/Application Support/ZoiLib/ folder
    
    static func appSupportUrl() throws -> URL {
        try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(AppFileManager.appFolderName)
    }
    
    static func patchLibraryUrl() throws -> URL {
        try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(AppFileManager.appFolderName)
            .appendingPathComponent(AppFileManager.patchFileFolderName)
    }
    
    static func editorFolderUrl() throws -> URL {
        try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(AppFileManager.appFolderName)
            .appendingPathComponent(AppFileManager.editorFolderName)
    }
    
    static func banksUrl() throws -> URL {
        try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(AppFileManager.appFolderName)
            .appendingPathComponent(AppFileManager.banksFolderName)
    }
    
    static func factoryBankUrl() throws -> URL {
        try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(AppFileManager.appFolderName)
            .appendingPathComponent(AppFileManager.banksFolderName)
            .appendingPathComponent(AppFileManager.factoryBankFolderName)
    }
}

