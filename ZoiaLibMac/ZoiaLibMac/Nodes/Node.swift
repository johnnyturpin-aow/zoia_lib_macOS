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

class Node: ObservableObject, Identifiable, Equatable {
    
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
    var color: Color {
        //return Color("Color-11")
        let colorName = "Color-" + colorId.description
        return Color.init(colorName)
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
    var connection: Port?
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
        connection = port
        return true
    }
}


