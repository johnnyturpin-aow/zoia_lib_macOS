/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

// Note: Much of this code is based on the implemention here: github.com/meanmedianmoge/zoia_lib/blob/master/zoia_lib/backend/patch_binary.py

import Foundation
import SwiftUI
import Combine

extension Data {
    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = Array<T>(repeating: 0, count: self.count/MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
        return array
    }
}

final class PatchFile: Codable {

    var id: String {
        return name ?? UUID().description
    }
    var name: String?
    var numPages: Int = 0
    var patchType: PatchType = .empty
    var isEuroBoro: Bool {
        return patch_io.has_cv || patch_io.has_headphone
    }
    var patch_io: ParsedBinaryPatch.IO = ParsedBinaryPatch.IO()
    var targetSlot: Int = 0
    var patchNameFromFile: String?
    var parsedPatch: ParsedBinaryPatch?
    
    
    var patchFilePath: String? {
        switch patchType {
        case .user(let filePath):
            return filePath
        case .blank:
            return nil
        case .empty:
            return nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case numPages
        case patchType
        case patch_io
        case targetSlot
        case patchNameFromFile
    }
    
    init(patchType: PatchType) {
        self.patchType = patchType
    }
    
    var isFactoryPatch: Bool {
        switch patchType {
        case .user(let filePath):
            let path = URL(fileURLWithPath: filePath)
            let filename = path.lastPathComponent
            let (isZoia, index, shortName) = BankManager.parseZoiaFileName(filename: filename)
            return EmpressReference.shared.factoryReference.contains(shortName ?? "")
        case .blank:
            return false
        case .empty:
            return false
        }
    }
    
    // Needs to be refactored if ever called on main thread - currently only called on background threads
    static func createFromBinFile(fileUrl: URL) -> PatchFile? {

        do {
            let fullFileName = fileUrl.lastPathComponent
            let (isZoiaFile, _, namePart) = BankManager.parseZoiaFileName(filename: fullFileName)
            
            
            if isZoiaFile {
                let rawData = try Data(contentsOf: fileUrl)
                if let parsedPatch = ParsedBinaryPatch.parseBinaryPatchData(raw: rawData) {
                    
                    let isEmpty = namePart?.lowercased() == ".bin"
                    let patchFile = PatchFile(patchType: isEmpty ? .blank : .user(filePath: fileUrl.path))
                    patchFile.parsedPatch = parsedPatch
                    patchFile.name = parsedPatch.name.isEmpty ? "Blank" : parsedPatch.name
                    patchFile.numPages = parsedPatch.pages.count
                    patchFile.patch_io = parsedPatch.patch_io
                    patchFile.patchNameFromFile = namePart
                    return patchFile
                }
            } else if fullFileName.suffix(3).lowercased() == "bin" {
                let rawData = try Data(contentsOf: fileUrl)
                if let parsedPatch = ParsedBinaryPatch.parseBinaryPatchData(raw: rawData) {
                    let patchFile = PatchFile(patchType: .user(filePath: fileUrl.path))
                    patchFile.parsedPatch = parsedPatch
                    patchFile.name = parsedPatch.name
                    patchFile.numPages = parsedPatch.pages.count
                    patchFile.patch_io = parsedPatch.patch_io
                    patchFile.patchNameFromFile = String(fullFileName.suffix(3))
                    return patchFile
                }
            }

        } catch {
            return nil
        }
        return nil
    }
    
    var patchTypeDescription: String {
        switch self.patchType {
            
        case .blank: return "Blank"
        case .empty: return "Nothing Assigned"
        case .user: return "User"
        }
    }

    enum PatchType: Equatable, Codable {
        case user(filePath: String)
        case blank              // A blank patch is a valid Zoia Patch with no modules and no pages = _zoia_.bin
        case empty              // An empty patch is a slot for a patch but with no data - will not overwrite patch on Zoia
        
        var iconName: String {
            switch self {
            case .blank: return "waveform"
            case .empty: return "minus"
            case .user: return "person.crop.square"
            }
        }
        
        var iconOpacity: CGFloat {
            switch self {
            case .blank: return 1.0
            case .empty: return 0.5
            case .user: return 1.0
            }
        }
    }
    static let testPatch1: PatchFile = PatchFile(patchType: .empty)
    static let testPatch2: PatchFile = PatchFile(patchType: .empty)
    static let testPatch3: PatchFile = PatchFile(patchType: .empty)
}

class ObservableBinaryPatch: Identifiable, ObservableObject {
    
    let id = UUID()
    let patchFile: PatchFile
    
    @Published var parsedJson: PatchStorage.Patch?
    @Published var parsedPatchFile: ParsedBinaryPatch?
    
    init(patchFile: PatchFile) {
        self.patchFile = patchFile
    }
    
    init(patchFile: PatchFile, parsedPatchFile: ParsedBinaryPatch?) {
        self.patchFile = patchFile
        self.parsedPatchFile = parsedPatchFile
    }
}

struct ParsedBinaryPatch: Identifiable {
    
    var id = UUID()
    var size: UInt32 = 0
    var name: String = ""
    var modules: [Module] = []
    var connections: [ConnectionRaw] = []
    var pages: [Page] = []
    var colors: [Int] = []
    
    var estimated_cpu: Double = 0
    var estimated_cpu_str: String = ""
    var patch_io: IO = IO()
    
    struct Page: Identifiable {
        let id = UUID()
        
        let index: Int
        var name: String?
        var buttons: [PatchButton] = []
        
        init(name: String?, index: Int) {
            self.name = name
            self.index = index
            for _ in 0..<40 {
                let button = PatchButton(buttonColorId: 16)
                self.buttons.append(button)
            }
        }
        
        init(name: String?, index: Int, buttons: [PatchButton]) {
            self.name = name
            self.index = index
            self.buttons = buttons
        }
    }
    
    struct ConnectionRaw {
        // format of source & destination is: source[0] = module_idx, source[1] = block_idx
        let source: [Int]
        let destination: [Int]
        let strength: Double
    }
    
    struct BlockConnection {
        let source_module_idx: Int?
        let source_block_name: String?
        let source_block_idx: Int?
        let dest_module_idx: Int?
        let dest_block_name: String?
        let dest_block_idx: Int?
    }
    
    var blockConnections: [BlockConnection] = []
    
    struct Module {
        var name: String?
        var refName: String?
        var number: Int = 0
        var category: String?
        var ref_mod_idx: Int = 0
        var version: Int?
        var estimatedCPU: Double?
        var pageNumber: Int = 0
        var old_color: Int = 1
        var new_color: Int = 1
        var color: Int = 1
        var position: [Int] = []
        var options_list: [Int] = []
        var option_binary: [String: Int] = [:]
        var options: [String: IntOrString] = [:]
        var referenceOptions: [ModuleOption] = []
        var num_params: Int = 0
        var paramters: [String: Double] = [:]
        var blocks: [ModuleBlock] = []
        var input_blocks: [ModuleBlock] = []
        var output_blocks: [ModuleBlock] = []
    }
    
    class IO: Codable {
        var audio_input_str: String {
            return ""
        }
        var audio_ouput_str: String {
            return ""
        }
        

        var audio_output_list: [Int: Bool] =  [1:false, 2:false]
        var audio_input_list: [Int: Bool] = [1:false, 2:false]
        
        // MIDI IN Mapping:     1 = MIDI notes IN,  2 = MIDI clock IN,  3 = MIDI CC IN,     4 = MIDI Pressure IN, 5 = MIDI PitchBend IN
        // MIDI OUT Mapping:    1 = MIDI notes OUT, 2 = MIDI clock OUT, 3 = MIDI CC OUT,    4 = MIDI PC OUT
        var midi_input_list: [Int: Bool] = [1:false, 2:false, 3:false, 4:false, 5:false]
        var midi_output_list: [Int: Bool] = [1:false, 2:false, 3:false, 4:false]
        var stomp_switch: [Int: Bool] = [1:false, 2:false, 3:false]
        var cv_in: [Int: Bool] = [1:false, 2:false, 3:false, 4:false]
        var cv_out: [Int: Bool] = [1:false, 2:false, 3:false, 4:false]
        var has_cv = false
        var has_stomp = false
        var has_headphone = false
        var has_midi_in: Bool {
            for (_,val) in midi_input_list {
                if val == true { return true }
            }
            return false
        }
        var has_midi_out: Bool {
            for (_,val) in midi_output_list {
                if val == true { return true }
            }
            return false
        }
        var estimated_cpu: String = ""
        
        var midi_input_description: String {
            var items: [String] = []
            if self.midi_input_list[1] == true { items.append("NOTE") }
            if self.midi_input_list[2] == true { items.append("CLK") }
            if self.midi_input_list[3] == true { items.append("CC") }
            if self.midi_input_list[4] == true { items.append("PRS") }
            if self.midi_input_list[5] == true { items.append("PB") }
            
            if items.isEmpty {
                return "NO MIDI IN"
            } else {
                return items.joined(separator: ", ")
            }
            
        }
        var midi_output_description: String {
            var items: [String] = []
            if self.midi_output_list[1] == true { items.append("NOTE") }
            if self.midi_output_list[2] == true { items.append("CLK") }
            if self.midi_output_list[3] == true { items.append("CC") }
            if self.midi_output_list[4] == true { items.append("PC") }
            if items.isEmpty {
                return "NO MIDI OUT"
            } else {
                return items.joined(separator: ", ")
            }
        }
    }
    
    static let color_mapping: [Int: String] = [1:"blue", 2:"green", 3:"red", 4:"yellow", 5:"aqua", 6:"magenta", 7:"white", 8:"orange", 9:"lima", 10:"surf", 11:"sky", 12:"purple", 13:"pink", 14:"peach", 15: "mango"]

    static func parseNullTerminatedString(data: [UInt8]) -> String? {
        guard let nilIndex =  data.firstIndex(where: {$0==0}) else { return nil }
        let stringArray = data.prefix(nilIndex)
        return String(bytes: stringArray, encoding: .utf8)
    }
    
    static func parseBinaryPatchData(raw: Data) -> ParsedBinaryPatch? {
        
        var patch = ParsedBinaryPatch()
        
        let referenceModules = EmpressReference.shared.moduleList
        
        let bytes = [UInt8](raw)
        
        // since there is no easy way to determine if this is indeed a zoia patch
        // sanity check #1
        if bytes.count != 32768 { return nil }
        
        //# Extract the string name of the patch.
        let name = ParsedBinaryPatch.parseNullTerminatedString(data: Array(bytes.dropFirst(4)))
        patch.name = name ?? ""
        

        //# Unpack the binary data.
        // data = struct.unpack("i" * int(len(byt) / 4), byt)
        let data = raw.withUnsafeBytes{ Array($0.bindMemory(to: UInt32.self))}  // alternate using extension: let data = raw.toArray(type: UInt32.self)
        // pch_size = data[0]
        let pch_size = data[0]
        
        patch.size = pch_size


        //# Get a list of colors for the modules
        //# (appears at the end of the binary)
        // temp = [i for i, e in enumerate(data) if e != 0]
        let temp = data.enumerated().filter( { i,e in e != 0 }).map({ i,e in i } )
                
        let last_color = (temp.last ?? 0) + 1
        let first_color = last_color - Int(data[5])
        
        var colors: [Int] = []
        var skip_real = false
        
        // defines the color for each module in a color table?
        for j in first_color..<last_color {
            if data[j] > 15 {
                skip_real = true
                colors = []
                break
            }
            colors.append(Int(data[j]))
        }
        
        patch.colors = colors
        let num_modules = data[5]
        
        // process basic module metadata
        var curr_step = 6
        for i in 0..<num_modules {
            let size = data[curr_step]
            var module = ParsedBinaryPatch.Module()
            module.number = Int(i)
            let mod_idx = Int(data[curr_step + 1])
            let refModule = referenceModules[mod_idx.description]
            module.ref_mod_idx = mod_idx
            module.category = refModule?.category
            module.refName = refModule?.name
            module.version = Int(data[curr_step + 2])
            module.pageNumber = Int(data[curr_step + 3])

            let name_start_index = (curr_step + (Int(size) - 4)) * 4
            let name_end_index = (curr_step + (Int(size) - 4)) * 4 + 16
            let name_range = name_start_index..<name_end_index
            module.name = ParsedBinaryPatch.parseNullTerminatedString(data: Array(bytes[name_range]))
            module.estimatedCPU = refModule?.cpu
            
            if module.name == nil || module.name?.isEmpty == true {
                module.name = EmpressReference.shared.moduleList[module.ref_mod_idx.description]?.name ?? ""
            }

            
            let pos_start = Int(data[curr_step + 5])
            let pos_end = pos_start + (refModule?.min_blocks ?? 0)
            
            // this will eventually be updated when we process the modules & options
            module.position = Array(pos_start..<pos_end)
            
            // still confused about old vs new color
            module.old_color = Int(data[curr_step + 4])
            if skip_real {
                module.new_color = 0
            } else {
                module.new_color = colors.item(at: Int(i)) ?? 1
            }
            
            let ops1 = Array(bytes[((curr_step + 8) * 4)..<((curr_step + 8) * 4 + 4)])
            let ops2 = Array(bytes[((curr_step + 9) * 4)..<((curr_step + 9) * 4 + 4)])
            
            let ops = ops1 + ops2
            module.options_list = ops.map { Int($0) }
            module.referenceOptions = referenceModules[mod_idx.description]?.options ?? []
            module.num_params = Int(data[curr_step + 6])
            
            for i in 0..<module.num_params {
                let key = "param_\(i)"
                let int_val = Int(data[curr_step + i + 10])
                let value: Double = Double(int_val) / Double(65536)
                module.paramters[key] = value
            }

            // will be updated after parsing raw data
            module.blocks = []
            
            curr_step += Int(size)
            // # options_list is an array of options referenced by index
            // # options_copy -> referenceOptions
            // # options_binary ->
            
            for (v, opt) in module.referenceOptions.enumerated() {
                let option_index = module.options_list[v]
                let option_name = opt.keys.first ?? ""
                if let value_list = opt.values.first {
                    if let value = value_list.item(at: option_index) {
                        module.options[option_name] = value
                        module.option_binary[option_name] = option_index
                    }
                }
            }
            module.color = module.new_color == 0 ? module.old_color : module.new_color
            patch.modules.append(module)
        }

        patch.connections = []
        //# Extract the connection data for each connection in the patch.
        let num_connections = Int(data[curr_step])
        for j in 0..<num_connections {
            let s1 = Int(data[curr_step + 1])
            let s2 = Int(data[curr_step + 2])
            let d1 = Int(data[curr_step + 3])
            let d2 = Int(data[curr_step + 4])
            let strength = Double(Int(data[curr_step + 5]) / 100)
            let connection = ParsedBinaryPatch.ConnectionRaw(source: [s1,s2], destination: [d1,d2], strength: strength)
            patch.connections.append(connection)
            curr_step += 5
        }
        
        patch.pages = []
        curr_step += 1
        let num_pages = Int(data[curr_step])
        for i in 0..<num_pages {
            let page_name_start = (curr_step + 1) * 4
            let page_name_end = ((curr_step + 1) * 4 ) + 16
            let page_name_range = page_name_start..<page_name_end
            let page_name = ParsedBinaryPatch.parseNullTerminatedString(data: Array(bytes[page_name_range]))
            // creates a page with 40 buttons using color 16 (empty color)
            let page = ParsedBinaryPatch.Page(name: page_name, index: i)
            patch.pages.append(page)
            curr_step += 4
        }
        
        // this is not right... there is something buggy with the pageNumber for some of these modules
        // reporting a page# of 127 while num_pages = 9
        
        // now figre out if there are unnamed pages, and insert into pages array with empty name
        //let last_referenced_page = patch.modules.count > 0 ? (patch.modules.last?.pageNumber ?? 0) + 1 : 1
        
//        let n_pages = patch.modules.count > 0 ? (patch.modules.last?.pageNumber ?? 0) + 1 : 1
//        while patch.pages.count < n_pages {
//            let page = BinaryPatchData.Page(name: "", buttons: empty_buttons)
//            patch.pages.append(page)
//        }

        curr_step += 1
        let num_starred = Int(data[curr_step])
        
        for _ in 0..<num_starred {
            curr_step += 1
        }
        
        
        //# Extract the colors of each module in the patch.
        // clear out colors list previously built? why?
        patch.colors = []
        for _ in 0..<patch.modules.count {
            let curr_color = Int(data[curr_step + 1])
            patch.colors.append(curr_color)
            curr_step += 1
        }
        
        var updated_modules: [ParsedBinaryPatch.Module] = []
        
        patch.patch_io = ParsedBinaryPatch.IO()
        
        var i: Int = 0
        for var module in patch.modules {
            
            let module_enum = ZoiaModuleProcessor(rawValue: module.ref_mod_idx)
            module.blocks = module_enum?.calculate_blocks_in_module(module: module) ?? []
            
            let start_pos = module.position.first ?? 0
            let end_pos = start_pos + module.blocks.count
            module.position = Array(start_pos..<end_pos)
            updated_modules.append(module)

            ParsedBinaryPatch.calculate_io(patch_io: patch.patch_io, module: module)
            i += 1
        }
        patch.modules = updated_modules
        
        patch.estimated_cpu = patch.modules.reduce(0, { $0 + ($1.estimatedCPU ?? 0)})
        patch.estimated_cpu_str = String(format: "%.2f %%", patch.estimated_cpu)

        // TODO: need to clean this up - not necessary to repeat in multiple places
        patch.patch_io.estimated_cpu = patch.estimated_cpu_str

        
        patch.modules = ParsedBinaryPatch.create_io_blocks(patch: patch)
        patch.blockConnections = ParsedBinaryPatch.make_block_connections(patch: patch)
        
        for module in patch.modules {
            // only update buttons for modules in actual pages - some patches have modules in page 127??? - see Spectre
            if module.pageNumber < patch.pages.count {
                var page = patch.pages[module.pageNumber]
                
                let skipButton = false
                // is it a UI button with a value 0? lets not show it as button in the UI
                if !skipButton {
                    if module.position.last ?? 0 < 40 {
                        for pos in module.position {
                            page.buttons[pos].buttonColorId = module.color
                        }
                    }
                    // zoia modules wrap - but for presentation of labels, lets not wrap
                    let firstPos = module.position.first ?? 0
                    let lastPos = min(module.position.last ?? 0, 39)
                    let row = Int(floor(Double(firstPos) / Double(8)))
                    let row_start_pos = row * 8
                    let row_end_pos = row_start_pos + 7
                    let last_label_pos = min( lastPos, row_end_pos)
                    if let name = module.name, name.isEmpty == false {
                        page.buttons[last_label_pos].label = name
                        page.buttons[last_label_pos].labelWidth = (last_label_pos + 1) - firstPos
                    }
                }
                patch.pages[module.pageNumber] = page
            }
        }
        return patch
    }
    
    static func make_block_connections(patch: ParsedBinaryPatch) -> [BlockConnection] {
        
        var conns: [BlockConnection] = []
        
        // pass 2 - loop through again creating indexed based connections
        for (_, connection) in patch.connections.enumerated() {
            guard let source_module_idx = connection.source.item(at: 0) else { continue }
            guard let dest_module_idx = connection.destination.item(at: 0) else { continue }
            // block index is index of reference data / not parsed data
            guard let source_ref_block_idx = connection.source.item(at: 1) else { continue }
            guard let dest_ref_block_idx = connection.destination.item(at: 1) else { continue }
            
            let source_module = patch.modules.item(at: source_module_idx)
            let source_block = EmpressReference.shared.moduleList[source_module?.ref_mod_idx.description ?? ""]?.blocks.first(where: { $0.values.first?.position == source_ref_block_idx })
            let dest_module = patch.modules.item(at: dest_module_idx)
            let dest_block = EmpressReference.shared.moduleList[dest_module?.ref_mod_idx.description ?? ""]?.blocks.first(where: { $0.values.first?.position == dest_ref_block_idx })
            
            let source_block_conn_idx = source_module?.output_blocks.firstIndex(where: { $0.keys.first == source_block?.keys.first })
            let dest_block_conn_idx = dest_module?.input_blocks.firstIndex(where: { $0.keys.first == dest_block?.keys.first })
            
            let block_connection = BlockConnection(source_module_idx: source_module_idx, source_block_name: source_block?.keys.first, source_block_idx: source_block_conn_idx, dest_module_idx: dest_module_idx, dest_block_name: dest_block?.keys.first, dest_block_idx: dest_block_conn_idx)
            conns.append(block_connection)
        }
        
        return conns
    }
    
    static func create_io_blocks(patch: ParsedBinaryPatch) -> [Module] {
        
        var updatedModules: [Module] = patch.modules
        // first pass - loop through connections to and separate input blocks from output blocks
        for (_, connection) in patch.connections.enumerated() {
            guard let source_module_idx = connection.source.item(at: 0) else { continue }
            guard let source_block_idx = connection.source.item(at: 1) else { continue }
            guard let dest_module_idx = connection.destination.item(at: 0) else { continue }
            
            // block index is index of reference data / not parsed data
            guard let dest_block_idx = connection.destination.item(at: 1) else { continue }
            
            var source_module = updatedModules.item(at: source_module_idx)
            let source_block = EmpressReference.shared.moduleList[source_module?.ref_mod_idx.description ?? ""]?.blocks.first(where: { $0.values.first?.position == source_block_idx })
            var dest_module = updatedModules.item(at: dest_module_idx)
            let dest_block = EmpressReference.shared.moduleList[dest_module?.ref_mod_idx.description ?? ""]?.blocks.first(where: { $0.values.first?.position == dest_block_idx })
            
            if source_module == nil || dest_module == nil {
                print("this is bad")
            }
            
            if source_block == nil || dest_block == nil {
                print("this is also bad")
            }
            
            if source_module?.output_blocks.contains(where: { $0.keys.first == source_block?.keys.first }) == false {
                source_module?.output_blocks.append(source_block!)
                let newName = (source_module?.name == nil || source_module?.name?.isEmpty == true) ? source_module?.refName : source_module?.name
                source_module?.name = newName ?? ""
                updatedModules[source_module_idx] = source_module!
            }
            if dest_module?.input_blocks.contains(where: { $0.keys.first == dest_block?.keys.first }) == false {
                dest_module?.input_blocks.append(dest_block!)
                let newName = (dest_module?.name == nil || dest_module?.name?.isEmpty == true) ? dest_module?.refName : dest_module?.name
                dest_module?.name = newName
                updatedModules[dest_module_idx] = dest_module!
            }
        }
        
        var completedModules = updatedModules
        
        // second pass - loop through module blocks and assign any unconnected block to either input or output
        for (index, var module) in updatedModules.enumerated() {
            var used_blocks: [ModuleBlock] = []
            var unused_blocks: [ModuleBlock] = []
            for block in module.input_blocks {
                used_blocks.append(block)
            }
            for block in module.output_blocks {
                used_blocks.append(block)
            }
            
            for block in module.blocks {
                if used_blocks.contains(where: { $0.keys.first == block.keys.first }) == false {
                    unused_blocks.append(block)
                }
            }
            
            for block in unused_blocks {
                if block.values.first?.isParam == true {
                    module.input_blocks.append(block)
                } else {
                    module.output_blocks.append(block)
                }
            }
            
            completedModules[index] = module
        }
        return completedModules
    }
    

    // TODO: Possible area of improvement with generic solution
    static func calculate_io(patch_io: ParsedBinaryPatch.IO,  module: ParsedBinaryPatch.Module)  {
        
        if module.ref_mod_idx == 1 {
            switch module.options.first?.value.asString {
            case "stereo":
                //patch.patch_io.audio_input = "[L + R]"
                patch_io.audio_input_list[1] = true
                patch_io.audio_input_list[2] = true
            case "left":
                
                patch_io.audio_input_list[1] = true
            case "right":
                patch_io.audio_input_list[2] = true
            default:
                break
            }
        }
        
        if module.ref_mod_idx == 2 {
            
            switch module.options.first(where: { $0.key == "channels"})?.value.asString {
            case "stereo":
                patch_io.audio_output_list[1] = true
                patch_io.audio_output_list[2] = true
            case "left":
                patch_io.audio_output_list[1] = true
            case "right":
                patch_io.audio_output_list[2] = true
            default:
                break
            }
        }
        
        if module.ref_mod_idx == 92 {
            patch_io.has_cv = true
            patch_io.has_headphone = true
        }
        if module.ref_mod_idx == 93 {
            patch_io.audio_input_list[1] = true
            patch_io.has_cv = true
        }
        if module.ref_mod_idx == 94 {
            patch_io.audio_input_list[2] = true
            patch_io.has_cv = true
        }
        if module.ref_mod_idx == 95 {
            patch_io.audio_output_list[1] = true
            patch_io.has_cv = true
        }
        if module.ref_mod_idx == 96 {
            patch_io.audio_output_list[2] = true
            patch_io.has_cv = true
        }
        
        if module.ref_mod_idx == 87 {
            patch_io.cv_out[4] = true
            patch_io.has_cv = true
        }
        if module.ref_mod_idx == 88 {
            patch_io.cv_in[1] = true
            patch_io.has_cv = true
        }
        if module.ref_mod_idx == 89 {
            patch_io.cv_in[2] = true
            patch_io.has_cv = true
        }
        if module.ref_mod_idx == 90 {
            patch_io.cv_in[3] = true
            patch_io.has_cv = true
        }
        if module.ref_mod_idx == 91 {
            patch_io.cv_in[4] = true
            patch_io.has_cv = true
        }
        if module.ref_mod_idx == 99 {
            patch_io.cv_out[1] = true
            patch_io.has_cv = true
        }
        if module.ref_mod_idx == 100 {
            patch_io.cv_out[2] = true
            patch_io.has_cv = true
        }
        if module.ref_mod_idx == 101 {
            patch_io.cv_out[3] = true
            patch_io.has_cv = true
        }
        if module.ref_mod_idx == 20 {
            patch_io.midi_input_list[1] = true
        }
        if module.ref_mod_idx == 21 {
            patch_io.midi_input_list[3] = true
        }
        if module.ref_mod_idx == 35 {
            patch_io.midi_input_list[4] = true
        }
        if module.ref_mod_idx == 82 {
            patch_io.midi_input_list[2] = true
        }
        if module.ref_mod_idx == 86 {
            patch_io.midi_input_list[5] = true
        }
        if module.ref_mod_idx == 60 {
            patch_io.midi_output_list[1] = true
        }
        if module.ref_mod_idx == 61 {
            patch_io.midi_output_list[3] = true
        }
        if module.ref_mod_idx == 62 {
            patch_io.midi_output_list[4] = true
        }
        if module.ref_mod_idx == 84 {
            patch_io.midi_output_list[2] = true
        }
        
        patch_io.has_stomp = !patch_io.has_cv
        
        if module.ref_mod_idx == 44 {
            if module.options.first(where: { $0.key == "stompswitch" })?.value.asString == "left" {
                patch_io.stomp_switch[1] = true
                patch_io.has_stomp = true
            }
            if module.options.first(where: { $0.key == "stompswitch" })?.value.asString == "middle" {
                patch_io.stomp_switch[2] = true
                patch_io.has_stomp = true
            }
            if module.options.first(where: { $0.key == "stompswitch" })?.value.asString == "right" {
                patch_io.stomp_switch[3] = true
                patch_io.has_stomp = true
            }
        }
        
    }
}


struct PatchButton: Identifiable, Hashable {
    let id: UUID = UUID()
    var buttonColorId: Int
    var buttonColor: Color {
        let colorName = "Color-" + buttonColorId.description
        return Color.init(colorName)
    }
    var label: String?
    var labelWidth: Int = 0 // width in # of buttons
    
    init(buttonColorId: Int, label: String? = nil, labelWidth: Int = 0) {
        self.buttonColorId = buttonColorId
        self.label = label
        self.labelWidth = labelWidth
    }
}

struct ByteParser {
    
    private var bytes: [UInt8] = []
    private var data: Data

    init(data: Data) {
        self.data = data
        self.bytes = [UInt8](data)
        
    }
    
    init(bytes: [UInt8]) {
        self.bytes = bytes
        self.data = Data(bytes)
    }
    
    private mutating func parseLEUIntX<Result>(_: Result.Type) -> Result?
            where Result: UnsignedInteger
    {
            let expected = MemoryLayout<Result>.size
            guard data.count >= expected else { return nil }
            defer { self.data = self.data.dropFirst(expected) }
            return data
                    .prefix(expected)
                    .reversed()
                    .reduce(0, { soFar, new in
                            (soFar << 8) | Result(new)
                    })
    }
    mutating func parseLEUInt8() -> UInt8? {
            parseLEUIntX(UInt8.self)
    }
    mutating func parseLEUInt16() -> UInt16? {
            parseLEUIntX(UInt16.self)
    }
    mutating func parseLEUInt32() -> UInt32? {
            parseLEUIntX(UInt32.self)
    }
    mutating func parseLEUInt64() -> UInt64? {
            parseLEUIntX(UInt64.self)
    }
}

