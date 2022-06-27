// GNU GENERAL PUBLIC LICENSE
//   Version 3, 29 June 2007
//
// Copyright (c) 2022 Johnny Turpin (github.com/johnnyturpin-aow)

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
    var mod_idx: Int
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
    }
    
    init(name: String, mod_idx: Int, pos: CGPoint) {
        self.name = name
        self.position = pos
        self.mod_idx = mod_idx
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
    
    
//    // can't use recursion if we have feedback loops
//    static func getHeightOfNodeLeft(node: Node?) -> Int {
//        var conns: [Node] = []
//        var maxHeight = 0
//        guard let node = node else { return maxHeight }
//
//        for port in node.inputs {
//            if let conn = port.connections {
//                conns.append(conn.parentNode)
//            }
//        }
//
//        if conns.isEmpty { return 0 }
//
//        for leftNode in conns {
//            let nodeHeight = Node.getHeightOfNodeLeft(node: leftNode)
//            maxHeight = max(maxHeight, nodeHeight)
//        }
//
//        return maxHeight + 1
//    }
    
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
    
    func connectTo(_ port: Port) -> Bool {
        guard portType != port.portType else { return false }
        connections.append(port)
        return true
    }
}


