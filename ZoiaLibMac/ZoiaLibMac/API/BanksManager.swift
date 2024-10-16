/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import Foundation
import SwiftUI

struct FactoryList: Codable {
    let factoryList: [String]
}

class BankManager {
    
    
    static func saveFactoryBank(isZebu: Bool, completion: @escaping ()->Void) {
        do {
            let factoryBankUrl = try isZebu ? AppFileManager.factoryZebuBankUrl() : AppFileManager.factoryBankUrl()
            if FileManager.default.fileExists(atPath: factoryBankUrl.path) {
                completion()
                return
            }

            try FileManager.default.createDirectory(at: factoryBankUrl, withIntermediateDirectories: true, attributes: nil)

            var bundlePath: String?
            // quick way to get path of bundle directory
            if isZebu {
                bundlePath = Bundle.main.path(forResource: "000_zoia_slightlyrandom", ofType: "bin", inDirectory: "Factory Euroburo")
            } else {
                bundlePath = Bundle.main.path(forResource: "000_zoia_Duck_Friends", ofType: "bin", inDirectory: "Factory")
            }
            guard let tempPath = bundlePath else { completion(); return }
            let url = URL(fileURLWithPath: tempPath)
            let bundledFactoryPath = url.deletingLastPathComponent()

            // load all zoia patches in memory
            let fileList = try FileManager.default.contentsOfDirectory(at: bundledFactoryPath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            for file in fileList {
                let fileName = file.lastPathComponent
                let (isZoiaFile, _, _) = BankManager.parseZoiaFileName(filename: fileName)
                if isZoiaFile {
                    let data = try Data(contentsOf: file)
                    //loadedPatches[patchName ?? ""] = data
                    let destFile = factoryBankUrl.appendingPathComponent(fileName)
                    try data.write(to: destFile)
                }
            }
            
            var bankMetadata = BankMetadata()
            bankMetadata.name = isZebu ? "Factory Euroburo" : "Factory"
            bankMetadata.description = "Default Facotry Bank that ships with the \(isZebu ? "ZOIA Euroburo" : "ZOIA")"
            bankMetadata.image_type = .icon
            bankMetadata.icon = .waveform
            bankMetadata.fg_color = CodableColor(color: .white)
            bankMetadata.bg_color = CodableColor(color: Color("Color-11"))
            bankMetadata.bankType = isZebu ? .euroburo : .zoia
            bankMetadata.id = UUID().description
            
            let jsonData = try JSONEncoder().encode(bankMetadata)
            let bankMetadataFile = factoryBankUrl.appendingPathComponent(bankMetadata.id! + ".json")
            try jsonData.write(to: bankMetadataFile)
            completion()
          
        } catch {
            print("error occured")
            completion()
        }
    }
    
    // Note: Completion is called on background thread
    static func initFactoryBankIfNeeded(completion: @escaping ()->Void) {
        DispatchQueue.global(qos: .background).async {
            saveFactoryBank(isZebu: false) {
                saveFactoryBank(isZebu: true) {
                    completion()
                }
            }
        }
    }
    
    // Note: Completion is called on UI thread
    static func updateBankName(bank: Bank, newName: String, completion: (()->Void)? = nil) {
        
        bank.name = newName
        DispatchQueue.global(qos: .background).async {
            
            if let currentPath = bank.directoryPath {
                let parentPath = currentPath.deletingLastPathComponent()
                let newPath = parentPath.appendingPathComponent(newName.convertToValidFileName())
                do {
                    try FileManager.default.moveItem(at: currentPath, to: newPath)
                    bank.directoryPath = newPath
                    
                    DispatchQueue.main.async {
                        BankManager.saveBank(bank: bank) {
                            _ in
                            DispatchQueue.main.async {
                                completion?()
                            }
                        }
                    }
                } catch {
                    print(error)
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
            }
        }
    }
    
    // (isZoiaFile: Bool, bankIndex: Int?, patchName: String?)
    static func parseZoiaFileName(filename: String) -> (Bool, Int?, String?) {
        let indexPart = filename.prefix(9)
        
        guard indexPart.count == 9 else { return (false, nil, nil) }
        let zoiaTag = indexPart.suffix(6)
        let namePart = filename.dropFirst(9)
        
        guard zoiaTag.lowercased() == "_zoia_" else { return (false, nil, nil) }
        guard namePart.count > 0 else { return (false, nil, nil) }
        
        guard let index = Int(indexPart.prefix(3)) else { return (false, nil, nil) }
        
        return (true, index, String(namePart))
    }
    
    // Note: Completion is called on UI thread
    static func saveImageFileToBank(bank: Bank, imageUrl: URL, completion: ((NSImage?)->Void)? = nil) {
        
        DispatchQueue.global(qos: .background).async {
            do {
                let imageData = try Data(contentsOf: imageUrl)
                let filename = imageUrl.lastPathComponent
                let image = NSImage(contentsOf: imageUrl)
                
                let banksDirectory = try AppFileManager.banksUrl()
                let bankDirectory = banksDirectory.appendingPathComponent(bank.name)
                
                let savedFileUrl = bankDirectory.appendingPathComponent(filename)
                try imageData.write(to: savedFileUrl)
                
                DispatchQueue.main.async {
                    
                    var newBankImage = Bank.BankImage()
                    
                    newBankImage.imageType = .image
                    newBankImage.imagePath = savedFileUrl
                    bank.nsImage = image
                    bank.image = newBankImage
                    BankManager.updateBankMetadata(bank: bank)
                    completion?(image)
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(nil)
                }
            }
        }
    }
    

    // Does not update any patch files, only updates metadata
    // Note: Completion is called on background thread
    static func updateBankMetadata(bank: Bank, completion: ((Bool)->Void)? = nil) {
        
        DispatchQueue.global(qos: .background).async {
            do {
                let banksDirectory = try AppFileManager.banksUrl()
                let bankDirectory = banksDirectory.appendingPathComponent(bank.name)
                bank.directoryPath = bankDirectory
                try FileManager.default.createDirectory(at: bankDirectory, withIntermediateDirectories: true, attributes: nil)
                let bankMetadataFile = bankDirectory.appendingPathComponent(bank.id + ".json")
                guard let bankMetadata = bank.toBankMetadata() else { completion?(false); return }
                let jsonData = try JSONEncoder().encode(bankMetadata)
                try jsonData.write(to: bankMetadataFile)
                completion?(true)
            }
            catch {
                completion?(false)
            }
        }
    }
    
	// Note: Completion is called on UI thread
	static func insertBlankFileAsPatch(bank: Bank, index: Int, completion: ((Bool)->Void)? = nil) {
		DispatchQueue.global(qos: .background).async {
			var bundlePath: String?
			
			if bank.bankType == .euroburo {
				bundlePath = Bundle.main.path(forResource: AppFileManager.factoryBlankPatchName, ofType: "bin", inDirectory: "Factory Euroburo")
			} else {
				bundlePath = Bundle.main.path(forResource: AppFileManager.factoryBlankPatchName, ofType: "bin", inDirectory: "Factory")
			}
			
			guard let fileURlString = bundlePath else {
				DispatchQueue.main.async {
					completion?(false);
				}
				return
			}
			print("fileURlString = \(fileURlString)")
			let fileUrl = URL(fileURLWithPath: fileURlString)
			if let patchFile = PatchFile.createFromBinFile(fileUrl: fileUrl) {
				do {
					let banksDirectory = try AppFileManager.banksUrl()
					guard let bankDirectory = bank.directoryPath else { return }
					
					// first, delete any blank file in that slot
					let allFiles = try FileManager.default.contentsOfDirectory(at: bankDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
					for file in allFiles {
						let fileName = file.lastPathComponent
						let (isZoiaFile, index, patchFileName) = BankManager.parseZoiaFileName(filename: fileName)
						if index == index {
							if fileName.lowercased().contains("_zoia_.bin") {
								try FileManager.default.removeItem(at: file)
							}
						}
					}
					
					let data = try Data(contentsOf: fileUrl)
					let fileName = fileUrl.lastPathComponent
					//let (isZoiaFile, _, patchFileName) = BankManager.parseZoiaFileName(filename: fileName)
					
					let newFileName = String(format: "%03d_zoia_", index) + ".bin"
					let destFile = bankDirectory.appendingPathComponent(newFileName)
					try data.write(to: destFile)
					
					DispatchQueue.main.async {
						patchFile.targetSlot = index
						// we have to update this on main thread as it triggers refresh of list
						bank.orderedPatches[index] = patchFile
						completion?(true)
					}
					
				} catch {
					print("something went wrong inserting new binary file into bank")
					DispatchQueue.main.async {
						completion?(false)
					}
				}
			} else {
				DispatchQueue.main.async {
					completion?(false)
				}
			}

		}
	}
	
    // Note: Completion is called on UI thread
    static func insertBinFileAsPatch(bank: Bank, fileUrl: URL, completion: ((Bool)->Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            if let patchFile = PatchFile.createFromBinFile(fileUrl: fileUrl) {
                
                // first try to find an available index that is empty
                // if none then find first index that is blank
                var foundIndex: Int?
               // foundIndex = bank.orderedPatches.firstIndex(where: { $0.patchType == PatchFile.PatchType.empty || $0.patchType == PatchFile.PatchType.blank })
				foundIndex = bank.orderedPatches.firstIndex(where: { $0.patchType == PatchFile.PatchType.empty })
				if foundIndex == nil {
					foundIndex = bank.orderedPatches.firstIndex(where: { $0.patchType == PatchFile.PatchType.blank })
				}

                if let foundIndex = foundIndex, foundIndex < 64 {
                    // copy file to bank folder
                    do {
                        let banksDirectory = try AppFileManager.banksUrl()
                        guard let bankDirectory = bank.directoryPath else { return }
                        
                        // first, delete any blank file in that slot
                        let allFiles = try FileManager.default.contentsOfDirectory(at: bankDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                        for file in allFiles {
                            let fileName = file.lastPathComponent
                            let (isZoiaFile, index, patchFileName) = BankManager.parseZoiaFileName(filename: fileName)
                            if index == foundIndex {
                                if fileName.lowercased().contains("_zoia_.bin") {
                                    try FileManager.default.removeItem(at: file)
                                }
                            }
                        }
                        
                        let data = try Data(contentsOf: fileUrl)
                        let fileName = fileUrl.lastPathComponent
                        let (isZoiaFile, index, patchFileName) = BankManager.parseZoiaFileName(filename: fileName)
                        
                        let newFileName = String(format: "%03d_zoia_", foundIndex) + (patchFileName ?? "")
                        let destFile = bankDirectory.appendingPathComponent(newFileName)
                        try data.write(to: destFile)
                        
                        DispatchQueue.main.async {
                            patchFile.targetSlot = foundIndex
                            // we have to update this on main thread as it triggers refresh of list
                            bank.orderedPatches[foundIndex] = patchFile
                            completion?(true)
                        }
                        
                    } catch {
                        print("something went wrong inserting new binary file into bank")
                        DispatchQueue.main.async {
                            completion?(false)
                        }
                    }
                }
            }
        }
    }
    
    static func duplicateBank(srcBank: Bank, dstBankName: String, completion: @escaping (Bank?)->Void) {
        
        let newBank = Bank(bankName: dstBankName)
        newBank.description = srcBank.description
        newBank.image = srcBank.image
        newBank.nsImage = srcBank.nsImage
        newBank.orderedPatches = srcBank.orderedPatches

        BankManager.saveBank(bank: newBank) {
            didSucceed in
            
            if didSucceed {
                completion(newBank)
            } else {
                completion(nil)
            }
        }
    }
    
    // Note: Completion is called on Background thread
    static func deleteBank(bank: Bank, completion: ((Bool)->Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            do {
                guard let bankDirectory = bank.directoryPath else { completion?(false); return }
                try FileManager.default.removeItem(at: bankDirectory)
                completion?(true)
                
            } catch {
                completion?(false)
            }
        }
    }
    
    // Note: Completion is called on Background thread
    static func exportBank(bank: Bank, exportFolder: URL, completion: ((Bool)->Void)? = nil) {
        
        DispatchQueue.global(qos: .background).async {
            do {
                let srcBanksDirectory = try AppFileManager.banksUrl()
                let srcBankDirectory = srcBanksDirectory.appendingPathComponent(bank.name)
                let targetBankDirectory = exportFolder.appendingPathComponent(bank.name)
                
                try FileManager.default.createDirectory(at: targetBankDirectory, withIntermediateDirectories: true, attributes: nil)
                
                var loadedPatches: [String:Data] = [:]
                let fileList = try FileManager.default.contentsOfDirectory(at: srcBankDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                // load all patches into dictionary first
                for file in fileList {
                    let fileName = file.lastPathComponent
                    let (isZoiaFile, _, patchName) = BankManager.parseZoiaFileName(filename: fileName)
                    if isZoiaFile {
                        let data = try Data(contentsOf: file)
                        loadedPatches[patchName ?? ""] = data
                    }
                }
                var patchUrl: URL?
                
                for patch in bank.orderedPatches {
                    
                    var data: Data?
                    switch patch.patchType {
                        // for now we are not going to turn empty patches into blank patches
                    case .empty:
                        continue
                    case .blank:
						if let key = patch.patchNameFromFile {
							data = loadedPatches[key]
						}
						if let data = data {
							let newFileName = String(format: "%03d_zoia_", patch.targetSlot) + ".bin"
							let destFile = targetBankDirectory.appendingPathComponent(newFileName)
							try data.write(to: destFile)
						}
                    case .user:
                        if let key = patch.patchNameFromFile {
                            data = loadedPatches[key]
                        }
						// we only support files of the format: XXX_zoia_PatchName.bin
						if let data = data {
							let newFileName = String(format: "%03d_zoia_", patch.targetSlot) + (patch.patchNameFromFile ?? ".bin")
							let destFile = targetBankDirectory.appendingPathComponent(newFileName)
							try data.write(to: destFile)
						}
                    }

                }
                completion?(true)
            }
            catch {
                completion?(false)
            }
        }
    }
    
    
    // Note: completion is called on background thread
    static func saveBank(bank: Bank, completion: ((Bool)->Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            do {
                let banksDirectory = try AppFileManager.banksUrl()
                let bankDirectory = banksDirectory.appendingPathComponent(bank.name)
                bank.directoryPath = bankDirectory
                
                try FileManager.default.createDirectory(at: bankDirectory, withIntermediateDirectories: true, attributes: nil)
                
                let bankMetadataFile = bankDirectory.appendingPathComponent(bank.id + ".json")
                guard let bankMetadata = bank.toBankMetadata() else { completion?(false); return }
                
                let jsonData = try JSONEncoder().encode(bankMetadata)
                try jsonData.write(to: bankMetadataFile)
                
                var patchUrl: URL?
                
                
                // load all zoia patches in memory
                var loadedPatches: [String:Data] = [:]
                let fileList = try FileManager.default.contentsOfDirectory(at: bankDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

                // load all patches into dictionary first
                for file in fileList {
                    let fileName = file.lastPathComponent
                    let (isZoiaFile, _, patchName) = BankManager.parseZoiaFileName(filename: fileName)
                    if isZoiaFile {
                        let data = try Data(contentsOf: file)
                        loadedPatches[patchName ?? ""] = data
                    }
                }
                
                // delete all current patch files
                for file in fileList {
                    let fileName = file.lastPathComponent
                    let (isZoiaFile, _, _) = BankManager.parseZoiaFileName(filename: fileName)
                    if isZoiaFile {
                        try FileManager.default.removeItem(at: file)
                    }
                }
                
                for patch in bank.orderedPatches {
                    
                    var data: Data?
					switch patch.patchType {
						// for now we are not going to turn empty patches into blank patches
					case .empty:
						continue
					case .blank:
						if let key = patch.patchNameFromFile {
							data = loadedPatches[key]
						}
						if let data = data {
							let newFileName = String(format: "%03d_zoia_", patch.targetSlot) + ".bin"
							let destFile = bankDirectory.appendingPathComponent(newFileName)
							try data.write(to: destFile)
						}
//                        patchUrl = try AppFileManager.appSupportUrl().appendingPathComponent("_zoia_.bin")
//                        guard let sourceFile = patchUrl else { continue }
//                        guard sourceFile.pathExtension.lowercased() == "bin" else { continue }
//                        data = try Data(contentsOf: sourceFile)
                    case .user:
                        
                        //patchUrl = URL(fileURLWithPath: filePath)
                        if let key = patch.patchNameFromFile {
                            data = loadedPatches[key]
                        }
						// we only support files of the format: XXX_zoia_PatchName.bin
						if let data = data {
							let newFileName = String(format: "%03d_zoia_", patch.targetSlot) + (patch.patchNameFromFile ?? ".bin")
							let destFile = bankDirectory.appendingPathComponent(newFileName)
							try data.write(to: destFile)
						}
                    }

                }
                completion?(true)
            } catch {
                completion?(false)
            }
        }
    }
    
    // Note: completion is called on background thread
    static func loadAllBanks(completion: @escaping ([Bank])->Void) -> Progress? {
        
        let progress = Progress(totalUnitCount: 100)
        DispatchQueue.global(qos: .background).async {
            
            let dispatchGroup = DispatchGroup()
            var bankList: [Bank] = []

            do {
                let banksDirectory = try AppFileManager.banksUrl()
                let directoryList = try FileManager.default.contentsOfDirectory(at: banksDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

                progress.totalUnitCount = Int64(directoryList.count)
                for item in directoryList {
                    if item.isDirectory {
                        dispatchGroup.enter()
                        let _ = BankManager.loadBank(bankUrl: item, parentProgress: progress) {
                            bank in
                            
                            if let bank = bank {
                                bankList.append(bank)
                            }
                            dispatchGroup.leave()
                            progress.completedUnitCount += 1
                        }
                    }
                }
            } catch {
                completion(bankList)
            }
            dispatchGroup.notify(queue: .main) {
                completion(bankList)
                progress.completedUnitCount = progress.totalUnitCount
            }
        }
        return progress
    }
    
    // Note: completion is called on background thread
    static func loadBank(bankUrl: URL, parentProgress: Progress?, completion: @escaping (Bank?)->Void) -> Progress? {
        
        var progress = Progress()
        if let parent = parentProgress {
            progress = Progress(totalUnitCount: 100, parent: parent, pendingUnitCount: 0)
        }
        do {
                let jsonDecoder = JSONDecoder()
                let fileList = try FileManager.default.contentsOfDirectory(at: bankUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                
                if let metadataPath = fileList.first(where: { $0.pathExtension.lowercased() == "json" }) {
                    let jsonData = try Data(contentsOf: metadataPath)
                    let bankMetadata = try jsonDecoder.decode(BankMetadata.self, from: jsonData)
                    let newBank = Bank(metadata: bankMetadata, path: bankUrl.path)
                    
                    // check to see if we need to load a custom image
                    if bankMetadata.image_type == .image {
                        let imagePath = URL(fileURLWithPath: bankMetadata.image_path ?? "")
                        DispatchQueue.main.async {
                            newBank.nsImage = NSImage(contentsOf: imagePath)
                        }
                    }

                    let attrs = try FileManager.default.attributesOfItem(atPath: bankUrl.path)
                    if let createDate = attrs[FileAttributeKey.creationDate] as? Date {
                        newBank.dateCreated = createDate
                    }
                    
                    if let modifiedDate = attrs[FileAttributeKey.modificationDate] as? Date {
                        newBank.dateModified = modifiedDate
                    }
                    
                    progress.totalUnitCount = Int64(fileList.count)
                    progress.completedUnitCount = 0
                    for file in fileList {
                        let fileName = file.lastPathComponent
                        let (isZoiaFile, index, patchFileName) = BankManager.parseZoiaFileName(filename: fileName)
                        
                        if isZoiaFile, let index = index {
                            if let patch = PatchFile.createFromBinFile(fileUrl: file) {
                                patch.targetSlot = index
                                newBank.orderedPatches[index] = patch
                            }
                        }

                        progress.completedUnitCount += 1
                    }
                    completion(newBank)
                }
            } catch {
                progress.completedUnitCount = progress.totalUnitCount
                completion(nil)
            }
        
        return progress
    }
}



