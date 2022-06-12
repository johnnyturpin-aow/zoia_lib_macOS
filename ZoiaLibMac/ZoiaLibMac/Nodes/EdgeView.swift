// GNU GENERAL PUBLIC LICENSE
//   Version 3, 29 June 2007
//
// Copyright (c) 2022 Johnny Turpin (github.com/johnnyturpin-aow)

import SwiftUI

typealias AnimatablePoint = AnimatablePair<CGFloat, CGFloat>
typealias AnimatableHorizPair = AnimatablePair<AnimatablePoint, AnimatablePoint>


struct EdgeView: Shape {
    
    var edge: Edge
    @ObservedObject var nodeCanvas: NodeCanvas
    
    static let quadFactor: CGFloat = 1.3
    
    var sx: CGFloat = 0
    var sy: CGFloat = 0
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    
    init(edge: Edge, nodeCanvas: NodeCanvas) {
        self.edge = edge
        self.nodeCanvas = nodeCanvas
        sx = edge.startPoint.x
        sy = edge.startPoint.y
        dx = edge.endPoint.x
        dy = edge.endPoint.y
    }
    
    func path(in rect: CGRect) -> Path {
        
        let midx = ((dx - sx) / 2) + sx
        
        var path = Path()
        path.move(to: CGPoint(x: sx, y: sy))
        switch nodeCanvas.connectionStyle {
        case .curved:
            let ctrl_pt_horiz_offset = abs(dx - sx) / EdgeView.quadFactor * (dx < sx ? 1.0 : -1.0)
            
            path.addCurve(to: CGPoint(x: dx, y: dy), control1: CGPoint(x: sx - ctrl_pt_horiz_offset, y: sy), control2: CGPoint(x: dx + ctrl_pt_horiz_offset, y: dy))

        case .right_angle:
            path.addLine(to: CGPoint(x: midx, y: sy))
            path.addLine(to: CGPoint(x: midx, y: dy))
            path.addLine(to: CGPoint(x: dx, y: dy))
        case .straight:
            path.addLine(to: CGPoint(x: dx, y: dy))
        }
        
        return path
    }
    
    var animatableData: AnimatableHorizPair {
        get {
            return AnimatablePair(AnimatablePair(edge.startPoint.x, edge.startPoint.y),
                                  AnimatablePair(edge.endPoint.x, edge.endPoint.y))
        }
        set {
            sx = newValue.first.first
            sy = newValue.first.second
            dx = newValue.second.first
            dy = newValue.second.second
        }
    }
}


