/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


import Foundation
import SwiftUI


class DropGroup {
    var dispatchGroup: DispatchGroup
    var dispatchSemaphore: DispatchSemaphore
    var dispatchQueue: DispatchQueue
    var groupCompletion: ()->Void
    
    var isFirstItem = true

    init(groupCompletion: @escaping ()->Void) {
        self.groupCompletion = groupCompletion
        self.dispatchGroup = DispatchGroup()
        self.dispatchSemaphore = DispatchSemaphore(value: 0)
        self.dispatchQueue = DispatchQueue(label: "bank-insertion")
        
        // hold off on our notify until we have processed our first file
        dispatchGroup.enter()
        
        self.dispatchGroup.notify(queue: self.dispatchQueue) {
            DispatchQueue.main.async {
                self.groupCompletion()
            }
        }
    }
    
    
    func handleDropOfFileUrl(fileUrl: URL, bank: Bank) {
        
        if !fileUrl.isDirectory {
            self.handleSingleFile(fileUrl: fileUrl, bank: bank)
        } else {
            if fileUrl.pathExtension.lowercased() == "zbundle" {
                dispatchGroup.enter()
                if isFirstItem {
                    dispatchGroup.leave()
                    isFirstItem = false
                }
                bank.insertComboDirectoryAsPatch(directoryUrl: fileUrl) {
                    didSucceed in
                    self.dispatchSemaphore.signal()
                    self.dispatchGroup.leave()
                }
                self.dispatchSemaphore.wait()
            } else {
                do {
                    let allFiles = try FileManager.default.contentsOfDirectory(at: fileUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                    for file in allFiles {
                        if file.pathExtension.lowercased() == "bin" {
                            self.handleSingleFile(fileUrl: file, bank: bank)
                        }
                    }
                } catch {
                    print("something went wrong processing a dropped folder of files")
                }
            }
        }
    }
    
    
    func handleSingleFile(fileUrl: URL, bank: Bank) {
        
        dispatchGroup.enter()
        // we submit an initial enter() to keep notify from firing...
        // once we have our first item, we can get rid of the first enter()
        if isFirstItem {
            dispatchGroup.leave()
            isFirstItem = false
        }
        if fileUrl.pathExtension.lowercased() == "bin" {
            BankManager.insertBinFileAsPatch(bank: bank, fileUrl: fileUrl) {
                didSucceed in
                self.dispatchSemaphore.signal()
                self.dispatchGroup.leave()
            }
            dispatchSemaphore.wait()
        }
    }
}

struct BankDropTarget: ViewModifier {
    let bank: Bank

    func body(content: Content) -> some View {
        
        if bank.name.lowercased() == "factory" {
            content
        } else  {
            content
                .onDrop(of: ["public.file-url"], isTargeted: Binding(get: { return bank.isTargetedForDrop }, set: {
                    newValue in
                    bank.isTargetedForDrop = newValue
                }), perform: {
                    itemProviders in
                    
                    if itemProviders.isEmpty { return true }
                    let dropGroup = DropGroup(groupCompletion: {
                        print("all files have been processed")
                    })
                    dropGroup.dispatchQueue.async {
                        for item in itemProviders {
                            _ = item.loadDataRepresentation(forTypeIdentifier: "public.file-url") {
                                itemData, error in
                                if let error = error {
                                    print("error parsing dropped item")
                                    print(error)
                                } else {
                                    if let data = itemData, let str = NSString(data: data, encoding: 4), let fileUrl = URL(string: str as String) {
                                        dropGroup.handleDropOfFileUrl(fileUrl: fileUrl, bank: bank)
                                    }
                                }
                            }
                        }
                    }
                    return true
                })
        }
    }
}

extension View {
    func bankDropTarget(bank: Bank) -> some View {
        modifier(BankDropTarget(bank: bank))
    }
}


struct DraggablePatch: ViewModifier {
    let patch: PatchFile
    func body(content: Content) -> some View {
        if patch.patchType == .empty {
            content
        } else {
            content
                .onDrag {
                    var patchPath: URL?
                    switch patch.patchType {
                    case .user(let filePath):
                        patchPath = URL(fileURLWithPath: filePath)
                    default:
                        break
                    }
                    
                    if let path = patchPath {
                        return NSItemProvider(item: path as NSURL, typeIdentifier: "public.file-url")
                    } else {
                        return NSItemProvider(item: URL(fileURLWithPath: "") as NSURL, typeIdentifier: "public.file-url")
                    }
                }
        }
    }
}

extension View {
    func draggablePatch(patch: PatchFile) -> some View {
        modifier(DraggablePatch(patch: patch))
    }
}




//class DropHandler {
//    static func handleDropOfFile(fileUrl: URL, bank: Bank, dropGroup: DropGroup, completion: ((Bool)->Void)? = nil) {
//        if fileUrl.isDirectory {
//            print("user has dropped combo directory onto bank")
//            if fileUrl.pathExtension.lowercased() == "zbundle" {
//                bank.insertComboDirectoryAsPatch(directoryUrl: fileUrl, completion: completion)
//            }
//
//        } else {
//            let fileName = fileUrl.lastPathComponent
//            let (isZoiaFile, _, _) = BankManager.parseZoiaFileName(filename: fileName)
//            if isZoiaFile {
//                BankManager.insertBinFileAsPatch(bank: bank, fileUrl: fileUrl, completion: completion)
//            }
//        }
//    }
//}


/*
 let dispatchGroup = DispatchGroup()
 let dispatchSemaphore = DispatchSemaphore(value: 0)
 let dispatchQueue = DispatchQueue(label: "bank-insertion")
 
 dispatchQueue.async {
     for item in itemProviders {
         _ = item.loadDataRepresentation(forTypeIdentifier: "public.file-url") {
             itemData, error in
             if let error = error {
                 print("error parsing dropped file data")
                 print(error)
             } else {
                 if let data = itemData, let str = NSString(data: data, encoding: 4), let fileUrl = URL(string: str as String) {
                     
                     if fileUrl.isDirectory {
                         if fileUrl.pathExtension.lowercased() == "zbundle" {
                             dispatchGroup.enter()
                             DropHandler.handleDropOfFile(fileUrl: fileUrl, bank: bank) {
                                 didSucceed in
                                 dispatchSemaphore.signal()
                                 dispatchGroup.leave()
                             }
                             dispatchSemaphore.wait()
                         } else {
                             
                         }
                     } else {
                         
                         dispatchGroup.enter()
                         DropHandler.handleDropOfFile(fileUrl: fileUrl, bank: bank) {
                             didSucceed in
                             dispatchSemaphore.signal()
                             dispatchGroup.leave()
                         }
                         dispatchSemaphore.wait()
                     }

                 }
                 
             }
         }
     }
 }
 dispatchGroup.notify(queue: dispatchQueue) {
     DispatchQueue.main.async {
         print("all files have been dropped")
     }
 }
 */
