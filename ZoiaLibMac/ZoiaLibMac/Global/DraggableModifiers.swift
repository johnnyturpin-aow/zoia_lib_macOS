//
//  DraggableModifiers.swift
//  ZLIB
//
//  Created by Johnny Turpin on 6/18/22.
//

import Foundation
import SwiftUI



class DropHandler {
    static func handleDropOfFile(fileUrl: URL, bank: Bank, completion: ((Bool)->Void)? = nil) {
        if fileUrl.isDirectory {
            print("user has dropped combo directory onto bank")
            bank.insertComboDirectoryAsPatch(directoryUrl: fileUrl, completion: completion)
        } else {
            let fileName = fileUrl.lastPathComponent
            let (isZoiaFile, _, _) = BankManager.parseZoiaFileName(filename: fileName)
            if isZoiaFile {
                BankManager.insertBinFileAsPatch(bank: bank, fileUrl: fileUrl, completion: completion)
            }
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
                                        dispatchGroup.enter()
                                        DropHandler.handleDropOfFile(fileUrl: fileUrl, bank: bank) {
                                            didSucceed in
                                            dispatchSemaphore.signal()
                                            dispatchGroup.leave()
                                        }
                                    }
                                    dispatchSemaphore.wait()
                                }
                            }
                        }
                    }
                    dispatchGroup.notify(queue: dispatchQueue) {
                        DispatchQueue.main.async {
                            print("all files have been dropped")
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
