/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import Foundation
import SwiftUI


struct BankMetadata: Codable {
    
    var name: String?
    var description: String?
    var image_path: String?
    var image_type: Bank.BankImage.ImageType?
    var icon: Bank.BankImage.Icon?
    var fg_color: CodableColor?
    var bg_color: CodableColor?
    var is_factory: Bool?
    var id: String?

}

class Bank: Identifiable, Hashable, ObservableObject {
    
    static let bankSize: Int = 64

    var id: String = UUID().description
    var directoryPath: URL?

    @Published var orderedPatches: [PatchFile] = []

    @Published var image: BankImage = BankImage()
    @Published var name: String
    @Published var description: String?
    @Published var dateCreated: Date = Date()
    @Published var dateModified: Date = Date()
    @Published var nsImage: NSImage?
    @Published var isTargetedForDrop: Bool = false
    
    var numItems: Int {
        return orderedPatches.reduce(0, { $0 + ($1.patchType == PatchFile.PatchType.empty ? 0 : 1) })
    }
    
    var isFactoryBank = false

    static func == (lhs: Bank, rhs: Bank) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    init(bankName: String) {
        self.name = bankName
        self.description = "Enter description here"
        orderedPatches = Array(repeating: PatchFile(patchType: .empty), count: Bank.bankSize)
    }
    
    init(metadata: BankMetadata, path: String) {
        self.name = metadata.name ?? ""
        if let ipath = metadata.image_path {
            self.image.imagePath = URL(fileURLWithPath: ipath)
        }
        self.directoryPath = URL(fileURLWithPath: path)
        self.description = metadata.description
        self.image.imageType = metadata.image_type ?? .icon
        self.image.icon = metadata.icon ?? .waveformAndMic
        self.image.iconColor = metadata.fg_color?.color ?? .white
        self.image.backgroundColor = metadata.bg_color?.color ?? .blue
        self.isFactoryBank = metadata.is_factory ?? false
        self.id = metadata.id ?? self.id
        orderedPatches = Array(repeating: PatchFile(patchType: .empty), count: Bank.bankSize)
        
    }
    
    func insertComboDirectoryAsPatch(directoryUrl: URL, completion: ((Bool)->Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            do {
                let allFiles = try FileManager.default.contentsOfDirectory(at: directoryUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                    
                guard let patchFile = allFiles.first(where:  { $0.pathExtension.lowercased().contains("bin") }) else {
                    print("could not find .bin file in combo directory")
                    completion?(false)
                    return
                }
                BankManager.insertBinFileAsPatch(bank: self, fileUrl: patchFile, completion: completion)
                
            } catch {
                print("error parsing combo directory")
                completion?(false)
            }
        }
    }
    
    func movePatch(from source: Int, to destination: Int) {
        orderedPatches.move(fromOffsets: IndexSet([source]), toOffset: destination)
        updatePatchSlots()
        BankManager.saveBank(bank: self)
    }
    
    
    // deletePatch removes the patch at the index (deletes local bank file too if patch is empty, factory, or user)
    func deletePatch(at index: Int) {

        let newPatch = PatchFile(patchType: .empty)
        newPatch.targetSlot = index
        self.orderedPatches[index] = newPatch
        BankManager.saveBank(bank: self)
    }
    
    func replacePatchWithBlankPatch(at index: Int) {
        
        if orderedPatches.item(at: index)?.patchType == .blank { return }
        let newPatch = PatchFile(patchType: .blank)
        newPatch.targetSlot = index
        self.orderedPatches[index] = newPatch
        BankManager.saveBank(bank: self)
        
    }
    
    private func ensurePatchAtSlotIsDeleted(index: Int, completion: @escaping ()->Void) {
        guard let patch = orderedPatches.item(at: index) else { completion(); return }
        switch patch.patchType {
            
        case .blank, .user:
            break
            
        // empty means there is no file to delete
        case .empty:
            completion()
            return
        }
        
        guard let directory = self.directoryPath else { completion(); return }
        
        DispatchQueue.global(qos: .background).async {
            do {
                let fileList = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                for file in fileList {
                    let fileName = file.lastPathComponent
                    
                    let (isZoiaFile, fileIndex, _) = BankManager.parseZoiaFileName(filename: fileName)
                    if isZoiaFile && index == fileIndex {
                        try FileManager.default.removeItem(at: file)
                        break
                    }
                }
                completion()

            } catch {
                completion()
            }
        }
    }
    
    func updatePatchSlots() {
        for (i, patch) in orderedPatches.enumerated() {
            patch.targetSlot = i
        }
    }
    
    static func testBank() -> Bank {
        let bank = Bank(bankName: "TestBank")
        
        bank.orderedPatches[0] = PatchFile.testPatch1
        bank.orderedPatches[1] = PatchFile.testPatch2
        bank.orderedPatches[3] = PatchFile.testPatch3
        bank.orderedPatches[5] = PatchFile.testPatch2
        bank.orderedPatches[6] = PatchFile.testPatch1
        return bank
    }
    
    struct BankImage {

        enum Icon: String, CaseIterable, Codable {
            case mic = "Mic"
            case waveformAndMic = "Looper"
            case waveform = "Effects"
            case amplifier = "Amp"
            case synthesizer = "Synth"
            case guitars = "Guitar"
            case utility = "Utility"
            case filters = "Filter"
            case performance = "Performance"

            var sysImageName: String {
                switch self {
                case .amplifier: return "amplifier"
                case .filters: return "camera.filters"
                case .guitars: return "guitars"
                case .mic: return "music.mic"
                case .performance: return "theatermasks"
                case .synthesizer: return "pianokeys"
                case .utility: return "wrench.and.screwdriver"
                case .waveform: return "waveform"
                case .waveformAndMic: return "waveform.and.mic"
                }
            }
        }

        enum ImageType: String, Codable {
            case image
            case icon
        }
        var imagePath: URL?
        var icon: Icon = .waveform
        var backgroundColor: Color =  Color("Color-11")
        var iconColor: Color = .white
        var imageType: ImageType = .icon
    }
}

extension Bank.BankImage.Icon: Identifiable {
    var id: RawValue { rawValue }
}


extension Bank {
    
    func toBankMetadata() -> BankMetadata? {
        let bankMetadata = BankMetadata(name: self.name,
                                        description: self.description,
                                        image_path: self.image.imagePath?.path,
                                        image_type: self.image.imageType,
                                        icon: self.image.icon,
                                        fg_color: CodableColor(color: self.image.iconColor),
                                        bg_color: CodableColor(color: self.image.backgroundColor),
                                        is_factory: self.isFactoryBank,
                                        id: self.id)
        return bankMetadata
    }
}

