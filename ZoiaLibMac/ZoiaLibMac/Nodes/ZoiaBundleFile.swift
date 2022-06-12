/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import Foundation

final class ZoiaBundle {
    
    
    static func saveNodeList(bundleUrl: URL, nodeList: NodeCanvasCodable, completion: (()->Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            do {
                let nodeFile = bundleUrl.appendingPathComponent("nodes.json")
                if FileManager.default.fileExists(atPath: nodeFile.path) {
                    try FileManager.default.removeItem(at: nodeFile)
                }
                let jsonData = try JSONEncoder().encode(nodeList)
                try jsonData.write(to: nodeFile)
                completion?()
                return
            }
            catch {
                completion?()
            }
        }
    }
    
    static func loadNodeList(bundleUrl: URL, completion: @escaping ((NodeCanvasCodable?)->Void)) {
        DispatchQueue.global(qos: .background).async {
            do {
                let nodeFile = bundleUrl.appendingPathComponent("nodes.json")
                let jsonData = try Data(contentsOf: nodeFile)
                let nodeList = try JSONDecoder().decode(NodeCanvasCodable.self, from: jsonData)
                completion(nodeList)
                return
            }
            catch {
                completion(nil)
            }
        }
    }
    
    static func openZoiaBundle(filePath: URL, completion: @escaping ((ObservableBinaryPatch?)->Void)) {
        DispatchQueue.global(qos: .background).async {
            do {
                if FileManager.default.fileExists(atPath: filePath.path) {
                    let fileList = try FileManager.default.contentsOfDirectory(at: filePath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                    
                    if let zbinFile = fileList.first(where: { $0.pathExtension == "bin" }) {
                        if let patchFile = PatchFile.createFromBinFile(fileUrl: zbinFile) {
                            let observable = ObservableBinaryPatch(patchFile: patchFile, parsedPatchFile: patchFile.parsedPatch)
                            
                            DispatchQueue.main.async {
                                completion(observable)
                            }
                            return
                        }
                    }
                }
            } catch {
                print("something went wrong loading zoia bundle")
            }
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    static func copyBinFileAsZoiaBundle(filePath: URL, completion: @escaping ((URL?)->Void)) {
        
        DispatchQueue.global(qos: .background).async {
            do {
                let editorFolder = try AppFileManager.editorFolderUrl()
                try FileManager.default.createDirectory(at: editorFolder, withIntermediateDirectories: true, attributes: nil)
                let zoiaFileName = filePath.lastPathComponent
                let fileNameParts = BankManager.parseZoiaFileName(filename: zoiaFileName)
                if fileNameParts.0 == true, let patchName = fileNameParts.2 {
                    
                    let justName = patchName.dropLast(4)
                    let zoiaEditorFile = editorFolder.appendingPathComponent(justName + ".zbundle")
                    if FileManager.default.fileExists(atPath: zoiaEditorFile.path) {
                        
                        DispatchQueue.main.async {
                            completion(zoiaEditorFile)
                        }
                        return
                    } else {
                        try FileManager.default.createDirectory(at: zoiaEditorFile, withIntermediateDirectories: true, attributes: nil)
                        let zoiaBinFile = zoiaEditorFile.appendingPathComponent(justName + ".bin")
                        let data = try Data(contentsOf: filePath)
                        try data.write(to: zoiaBinFile)
                        DispatchQueue.main.async {
                            completion(zoiaEditorFile)
                        }
                        return
                    }
                }
            } catch {

            }
            DispatchQueue.main.async {
                completion(nil)
            }
        }
        
    }
}
