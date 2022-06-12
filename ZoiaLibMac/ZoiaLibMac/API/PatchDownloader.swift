/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import Foundation
import SwiftUI
import Combine

class PatchWrapper: ObservableObject, Identifiable, Equatable, Hashable, Comparable {
    
    static func < (lhs: PatchWrapper, rhs: PatchWrapper) -> Bool {
        lhs.patch.updated_at ?? Date() < rhs.patch.updated_at ?? Date()
    }
    
    static func == (lhs: PatchWrapper, rhs: PatchWrapper) -> Bool {
        lhs.patch.id == rhs.patch.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(patch.id.description)
        hasher.combine(patch.slug ?? "")
    }
    
    let id: Int
    @Published var patch: PatchStorage.Patch
    @Published var patchDetail: PatchStorage.Patch?
    @Published var patchDownloader: PatchDownloader
    
    init(patch: PatchStorage.Patch) {
        self.patch = patch
        self.id = patch.id
        self.patchDownloader = PatchDownloader(patchId: patch.id.description, modifiedDate: patch.updated_at ?? Date())
    }
}


enum DownloadingState: String, Equatable {
    case invalidFile
    case noLocalCopy
    case versionUpdateAvailable
    case downloadingPatchJson
    case downloadingBinary
    case completed
    case error
}


class LocalPatchCombo: Identifiable, Equatable, Hashable, Comparable, ObservableObject {
    
    var id: Int { patchJson.id }
    
   
    private(set) var patchData: Data
    @Published var patchJson: PatchStorage.Patch
    @Published var parsedPatch: ParsedBinaryPatch?
    var folderPath: URL
    var patchFilePath: URL
    
    init(patchJson: PatchStorage.Patch, patchData: Data, folderPath: URL, filePath: URL) {
        self.patchJson = patchJson
        self.patchData = patchData
        self.folderPath = folderPath
        self.patchFilePath = filePath
    }
    
    static func < (lhs: LocalPatchCombo, rhs: LocalPatchCombo) -> Bool {
        lhs.patchJson.updated_at ?? Date() < rhs.patchJson.updated_at ?? Date()
    }
    
    static func == (lhs: LocalPatchCombo, rhs: LocalPatchCombo) -> Bool {
        lhs.patchJson.id == rhs.patchJson.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(patchJson.id.description)
        hasher.combine(patchJson.slug ?? "")
    }

    func parseBinaryData() {
        self.parsedPatch = ParsedBinaryPatch.parseBinaryPatchData(raw: self.patchData)
    }
}

class PatchDownloader: Identifiable, ObservableObject {
    
    @Published var state: DownloadingState = .noLocalCopy {
        didSet {
            print("state set to: \(self.state.rawValue)")
            if self.state == .error {
                print("check here")
            }
        }
    }
    private var patchId: String
    private var modifiedDate: Date
    
    var id: String {
        return patchId
    }
    
    init(patchId: String, modifiedDate: Date) {
        self.patchId = patchId
        self.modifiedDate = modifiedDate
    }
    
    private var cancellable: Cancellable?
        
    func prepareDownloadRequest(urlStr: String) -> URLRequest? {
        guard let requestUrl = URL(string: urlStr) else { return nil }
        var request = URLRequest(url: requestUrl)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.addValue("*/*", forHTTPHeaderField: "Accept")
        request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("ZoiaLibMac/1.0.0", forHTTPHeaderField: "User-Agent")
        request.httpMethod = "GET"
        return request
    }
    
    
    func setStateOnMain(newState: DownloadingState) {
        DispatchQueue.main.async { self.state = newState }
    }
    
    func updatePatchId(newId: String) {
        self.patchId = newId
        self.state = .noLocalCopy
    }

    func cancel() {
        cancellable?.cancel()
        self.state = .noLocalCopy
    }
    
    // Creates a .zbundle folder (App specific package type)
    // Downloads the patch from patchstorage.com
    // Downloads the first binary file found in the patch.json which matches ".bin"
    // Saves the patch json in the bundle
    // Saves the binary patch ".bin" file in the bundle
    func download(completion:  ((DownloadingState)->Void)? = nil) {

        cancellable?.cancel()
        self.state = .downloadingBinary
        
        guard let patchIdInt = Int(self.patchId) else { completion?(.error); return }
        cancellable = PatchStorageAPI.shared.getZoiaPatch(patchId: patchIdInt)
            .sink(receiveCompletion: {
                completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("error downloading patch = \(error)")
                    self.state = .error
                }
            }, receiveValue: {
                [weak self] patch in
                

                // TODO: Handle .zip files
                guard let binaryFile = patch.files?.first(where: { $0.filename?.suffix(4).lowercased() == ".bin" }) else { self?.state = .error; completion?(.error); return }
                guard let binaryUrlStr = binaryFile.url else {  self?.state = .error; completion?(.error); return }
                guard let request = self?.prepareDownloadRequest(urlStr: binaryUrlStr) else {  self?.state = .error; completion?(.error); return }
                
                let dataTask = URLSession.shared.dataTask(with: request) {
                    data, response, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            print("error downloading file = \(error.localizedDescription)")
                            self?.state = .error
                            completion?(.error)
                        }
                        return
                    }
                    guard let response = response as? HTTPURLResponse else {  self?.state = .error; completion?(.error); return }
                    if response.statusCode != 200 {
                        DispatchQueue.main.async {
                            print("httpStatusCode != 200 - error = \(error.debugDescription)")
                            self?.state = .error
                            completion?(.error)
                        }
                        
                        return
                    }
                    guard let data = data else {
                        DispatchQueue.main.async {
                            self?.state = .error
                            completion?(.error)
                        }
                        return
                    }
                    
                    var fileDirectory: URL?
                    
                    DispatchQueue.global(qos: .background).async {
                        do {
                            fileDirectory = try AppFileManager.patchLibraryUrl().appendingPathComponent(patch.id.description + AppFileManager.bundleExtension, isDirectory: true)
                            guard let fileDirectory = fileDirectory else {
                                DispatchQueue.main.async {
                                    self?.state = .error
                                    completion?(.error)
                                }
                                return
                            }
                            // TODO: Handle .zip files
                            guard patch.fileName?.suffix(4) == ".bin" else {
                                DispatchQueue.main.async {
                                    self?.state = .error
                                    completion?(.error)
                                }
                                return
                            }

                            try FileManager.default.createDirectory(at: fileDirectory, withIntermediateDirectories: true, attributes: nil)
                            
                            // let's make all binary patches use the format XXX_zoia_name.bin
                            // use slot 000 but maintain other parts of name
                            // this is because sometimes when authors update patches they change slot numbers of the patch
                            var updatedPatchName: String?
                            
                            if patch.fileName?.first?.isNumber == true {
                                if let patchFileName = patch.fileName {
                                    let (isZoiaFile, _, patchName) = BankManager.parseZoiaFileName(filename: patchFileName)
                                    guard isZoiaFile else {
                                        try FileManager.default.removeItem(at: fileDirectory)
                                        DispatchQueue.main.async {
                                            self?.state = .error
                                            completion?(.error)
                                        }
                                        return
                                        
                                    }
                                    updatedPatchName = "000_zoia_" + String(patchName ?? "undefined")
                                } else {
                                    updatedPatchName = "000_zoia_.bin"
                                }
                            } else {
                                guard patch.fileName?.isEmpty == false else {
                                    try FileManager.default.removeItem(at: fileDirectory)
                                    DispatchQueue.main.async {
                                        self?.state = .error
                                        completion?(.error)
                                    }
                                    return
                                    
                                }
                                updatedPatchName = "000_zoia_" + (patch.fileName ?? "patch" ) + ".bin"
                            }
                            

                            let binaryFileName = fileDirectory.appendingPathComponent(updatedPatchName!)
                            let jsonFileName = fileDirectory.appendingPathComponent(patch.id.description + ".json")
                            
                            if FileManager.default.fileExists(atPath: binaryFileName.path) {
                                try FileManager.default.removeItem(at: binaryFileName)
                            }
                            if FileManager.default.fileExists(atPath: jsonFileName.path) {
                                try FileManager.default.removeItem(at: jsonFileName)
                            }
                            let jsonData = try PatchStorageAPI.shared.jsonEncoder.encode(patch)
                            try jsonData.write(to: jsonFileName)
                            try data.write(to: binaryFileName)
                            
                            self?.setStateOnMain(newState: .completed)
                            completion?(.completed)
                            
                        } catch {
                            self?.setStateOnMain(newState: .error)
                            completion?(.error)
                            print("error writing files to library directory")
                        }
                    }
                }
                dataTask.resume()
                
            })
    }
}

