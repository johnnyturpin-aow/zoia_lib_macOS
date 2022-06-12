// GNU GENERAL PUBLIC LICENSE
//   Version 3, 29 June 2007
//
// Copyright (c) 2022 Johnny Turpin (github.com/johnnyturpin-aow)

import Foundation

typealias EdgeID = UUID

class NodeConnection: Identifiable {
    var id = UUID()
    
    var node: Node
    var port: Port

    init(node: Node, port: Port) {
        self.node = node
        self.port = port
    }
}

class Edge: ObservableObject, Identifiable {
    var id = EdgeID()
    
    var startConnection: NodeConnection
    var endConnection: NodeConnection
    var strength: Double = 100
    
    @Published var startPoint: CGPoint = .zero
    @Published var endPoint: CGPoint = .zero
    
    init(start: NodeConnection, end: NodeConnection, strength: Double) {
        self.startConnection = start
        self.endConnection = end
        self.strength = strength
        calculatePos()
    }
    
    func calculatePos() {
        let sx = startConnection.node.position.x + NodeView.nodeWidth + NodeView.ioStackOutputHoffset
        var sy = startConnection.node.position.y
        let dx = endConnection.node.position.x + NodeView.ioStackInputHoffset
        var dy = endConnection.node.position.y
        
        sy += NodeView.ioStackVoffset + (CGFloat(startConnection.port.portIndex) * (NodeView.portHeight + 8)) + NodeView.portDiameter
        dy += NodeView.ioStackVoffset + (CGFloat(endConnection.port.portIndex) * (NodeView.portHeight + 8)) + NodeView.portDiameter
        
        startPoint = CGPoint(x: sx, y: sy)
        endPoint = CGPoint(x: dx, y: dy)
    }
}




