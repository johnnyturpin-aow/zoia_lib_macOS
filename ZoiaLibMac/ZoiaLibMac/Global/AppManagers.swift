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

final class AppFileManager {
    
    let fileManager = FileManager.default
    private static let appFolderName = "ZoiaLib"
    private static let patchFileFolderName = "Library"
    private static let tempFileFolderName = "temp"
    private static let banksFolderName = "Banks"
    private static let factoryBankFolderName = "Factory"
    private static let factoryZebuBankFolderName = "Factory Euroburo"
    private static let editorFolderName = "Editor"
	static let factoryBlankPatchName = "063_zoia_"
    
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
    
    static func zipExtractionUrl() throws -> URL {
        try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(AppFileManager.appFolderName)
            .appendingPathComponent(AppFileManager.tempFileFolderName)
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
    static func factoryZebuBankUrl() throws -> URL {
        try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(AppFileManager.appFolderName)
            .appendingPathComponent(AppFileManager.banksFolderName)
            .appendingPathComponent(AppFileManager.factoryZebuBankFolderName)
    }
//	static func factoryBlankPatch() throws -> URL {
//		try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
//			.appendingPathComponent(AppFileManager.appFolderName)
//			.appendingPathComponent(AppFileManager.banksFolderName)
//			.appendingPathComponent(AppFileManager.factoryZebuBankFolderName)
//			.appendingPathComponent(AppFileManager.factoryBlankPatchName)
//	}
}

