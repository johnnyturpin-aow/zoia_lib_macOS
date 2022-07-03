/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


import SwiftUI

typealias NodeID = UUID

struct CanvasPosition: Codable {
    let x: Double
    let y: Double
}

struct NodeCodable: Codable {
    let mod_idx: Int
    let position: CanvasPosition
    let color: CodableColor
}

class Node: ObservableObject, Identifiable, Equatable, Hashable {
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.id == rhs.id
    }

    var id: UUID = NodeID()
    @Published var position: CGPoint = .zero
    var name: String = ""
    var inputs: [Port] = []
    var outputs: [Port] = []
    var colorId: Int = 1
    var mod_idx: Int        // mod_idx is the index into the module list
    var ref_mod_idx: Int    // ref_mod_idx is the index into the list of reference modules (i.e. what type of module this is)
    var depth: Int = 0      // depth in tree traversal from output to input
    var allChildNodes: Set<Node> = []
    var row_num: Int = 0
    var color: Color {
        //return Color("Color-11")
        let colorName = "Color-" + colorId.description
        return Color.init(colorName)
    }
    
    var nodeLabelColor: Color {
        switch self.colorId {
        case 1, 2, 3, 6, 8, 11, 12, 13, 16: return Color.white
        default: return Color.black
        }
    }

    var height: CGFloat {
        let maxIO = CGFloat(max(inputs.count, outputs.count))
        return (maxIO * 38) + 50 + 10
    }
    
    init() {
        self.mod_idx = 0
        self.ref_mod_idx = 0
    }
    
    init(name: String, mod_idx: Int, ref_mod_idx: Int, pos: CGPoint) {
        self.name = name
        self.position = pos
        self.mod_idx = mod_idx
        self.ref_mod_idx = ref_mod_idx
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(mod_idx)
        hasher.combine(name)
    }
    
    func createAndInsertPort(portType: PortType, name: String) {
        let port = Port(parent: self, portType: portType)
        port.name = name
        switch portType {
        case .input:
            inputs.insert(port, at: 0)
            for (index, p) in inputs.enumerated() {
                p.portIndex = index
            }
        case .output:
            outputs.insert(port, at: 0)
            for (index, p) in outputs.enumerated() {
                p.portIndex = index
            }
        }
    }

    
    func createAndAppendPort(portType: PortType, name: String) {
        let port = Port(parent: self, portType: portType)
        port.name = name
        switch portType {
        case .input:
            inputs.append(port)
            for (index, p) in inputs.enumerated() {
                p.portIndex = index
            }
        case .output:
            outputs.append(port)
            for (index, p) in outputs.enumerated() {
                p.portIndex = index
            }
        }
    }
    
    static func audioInputNode() -> Node {
        let node = Node()
        node.name = "Audio Through"
        
        node.createAndAppendPort(portType: .input, name: "Left")
        node.createAndAppendPort(portType: .input, name: "Right")
       
        node.createAndAppendPort(portType: .output, name: "Left")
        node.createAndAppendPort(portType: .output, name: "Right")
        return node
    }
}


enum PortType {
    case input
    case output
}

class Port: Identifiable {
    var id: UUID = UUID()
    var parentNode: Node
    var name: String = ""
    var connections: [Port] = []
    var portType: PortType
    var portIndex: Int = 0
    
    init(parent: Node, portType: PortType) {
        self.parentNode = parent
        self.portType = portType
    }
    
    init(parent: Node, portType: PortType, name: String) {
        self.parentNode = parent
        self.portType = portType
        self.name = name
    }
    
    func removeConnection(_ node: Node) {
        let portIndex = connections.firstIndex(where: { $0.parentNode == node })
        if let foundIndex = portIndex {
            connections.remove(at: foundIndex)
        }
    }
    
    func connectTo(_ port: Port) -> Bool {
        guard portType != port.portType else { return false }
        connections.append(port)
        return true
    }
    
    var isAudioPort: Bool {
        //isAudio = srcConnection.port.name.contains("audio") || dstConnection.port.name.contains("audio") || srcConnection.port.name == "output_L" || srcConnection.port.name == "output_R" || dstConnection.port.name == "input_L" || dstConnection.port.name == "input_R"
        return name.contains("audio") || name == "output_L" || name == "output_R" || name == "input_L" || name == "input_R"
    }
}


