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
    
    var srcConnection: NodeConnection
    var dstConnection: NodeConnection
    var strength: Double = 100
    
    @Published var startPoint: CGPoint = .zero
    @Published var endPoint: CGPoint = .zero
    
    init(src: NodeConnection, dst: NodeConnection, strength: Double) {
        self.srcConnection = src
        self.dstConnection = dst
        self.strength = strength
        calculatePos()
    }
    
    func calculatePos() {
        let sx = srcConnection.node.position.x + NodeView.nodeWidth + NodeView.ioStackOutputHoffset
        var sy = srcConnection.node.position.y
        let dx = dstConnection.node.position.x + NodeView.ioStackInputHoffset
        var dy = dstConnection.node.position.y
        
        sy += NodeView.ioStackVoffset + (CGFloat(srcConnection.port.portIndex) * (NodeView.portHeight + 8)) + NodeView.portDiameter
        dy += NodeView.ioStackVoffset + (CGFloat(dstConnection.port.portIndex) * (NodeView.portHeight + 8)) + NodeView.portDiameter
        
        startPoint = CGPoint(x: sx, y: sy)
        endPoint = CGPoint(x: dx, y: dy)
    }
}




