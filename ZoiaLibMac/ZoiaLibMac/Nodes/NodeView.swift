// GNU GENERAL PUBLIC LICENSE
//   Version 3, 29 June 2007
//
// Copyright (c) 2022 Johnny Turpin (github.com/johnnyturpin-aow)

import SwiftUI

struct NodeView: View {
    
    @ObservedObject var node: Node
    @ObservedObject var nodeCanvas: NodeCanvas
    @ObservedObject var selection: SelectionHandler
    
    static let nodeWidth: CGFloat = 200
    static let titleHeight: CGFloat = 30
    static let ioStackVoffset: CGFloat = 50
    static let ioStackInputHoffset: CGFloat = -7
    static let ioStackOutputHoffset: CGFloat = 7
    static let portHeight: CGFloat = 30
    static let portDiameter: CGFloat = 15
    
    init(node: Node, nodeCanvas: NodeCanvas) {
        self.node = node
        self.nodeCanvas = nodeCanvas
        self.selection = nodeCanvas.selection
    }
    
    var nodeHeight: CGFloat {
        let maxIO = CGFloat(max(node.inputs.count, node.outputs.count))
        return (maxIO * 38) + 50 + 10
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 5)
                //.fill(node.color)
                .fill(Color(red: 0.3, green: 0.3, blue: 0.3))
                .overlay(RoundedRectangle(cornerRadius: 5)
                    .stroke(selection.isNodeSelected(node) ? Color.yellow : Color.black, lineWidth: selection.isNodeSelected(node) ? 5 : 3))
                .frame(width: NodeView.nodeWidth, height: nodeHeight)
            
            RoundedRectangle(cornerRadius: 5)
                //.fill(Color.black)
                .fill(node.color)
                .frame(width: NodeView.nodeWidth - 6, height: NodeView.titleHeight)
                .offset(x: 3, y: 4)
                .opacity(0.8)
                //.opacity(0.2)
            
            Text(node.name)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.white)
                .frame(width: NodeView.nodeWidth, height: NodeView.titleHeight, alignment: .center)
                .offset(x: 0, y: 4)
            
            VStack(alignment: .leading) {
                ForEach(node.inputs) { inputPort in
                    InputPortView(port: inputPort)
                }
                Spacer()
            }
            .offset(x: NodeView.ioStackInputHoffset, y: NodeView.ioStackVoffset)
            
            VStack(alignment: .trailing) {
                ForEach(node.outputs) { outputPort in
                    OutputPortView(port: outputPort)
                }
                Spacer()
            }
            .offset(x: NodeView.ioStackOutputHoffset, y: NodeView.ioStackVoffset)
            
        }
        .onTapGesture {
            if nodeCanvas.selection.isNodeSelected(node) {
                nodeCanvas.selection.deselectNode(node)
            } else {
                nodeCanvas.selection.selectNode(node)
            }
        }
        .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged {
                value in
                
                if !nodeCanvas.isDraggingNode {
                    
                    if !nodeCanvas.selection.isNodeSelected(node) {
                        nodeCanvas.selection.selectNode(node)
                    }
                    nodeCanvas.isDraggingNode = true
                    selection.startDragging(nodeCanvas)
                }
                
                let scaledTranslation = value.translation.scaledDownTo(nodeCanvas.zoomScale)
                nodeCanvas.processNodeTranslation(scaledTranslation, nodes: selection.draggingNodes)
                nodeCanvas.nodeDragChange += 1
            }
            .onEnded {
                value in
                if nodeCanvas.isDraggingNode {
                    nodeCanvas.isDraggingNode = false
                    let scaledTranslation = value.translation.scaledDownTo(nodeCanvas.zoomScale)
                    nodeCanvas.processNodeTranslation(scaledTranslation, nodes: selection.draggingNodes)
                    selection.stopDragging(nodeCanvas)
                }

            })
    }
}

struct InputPortView: View {
    let port: Port
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color("TagModulation"))
                .frame(width: NodeView.portDiameter, height: NodeView.portDiameter)
                .overlay(Circle()
                    .stroke(Color.green, lineWidth: 3))
                .padding(port.connection == nil ? 0 : -4)
                .overlay(Circle()
                    .fill(port.connection == nil ? .clear : .white))
                .padding(port.connection == nil ? 0 : 4)
                .opacity(0.9)
            Text(port.name)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color.white)
            Spacer()
        }
        .frame(width: NodeView.nodeWidth, height: NodeView.portHeight)
    }
}

struct OutputPortView: View {
    let port: Port
    
    var body: some View {
        HStack {
            Spacer()
            Text(port.name)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color.white)
            Circle()
                .fill(Color("TagModulation"))
                .frame(width: NodeView.portDiameter, height: NodeView.portDiameter)
                .overlay(Circle()
                    .stroke(Color.green, lineWidth: 3))
                .padding(port.connection == nil ? 0 : -4)
                .overlay(Circle()
                    .fill(port.connection == nil ? .clear : .white))
                .padding(port.connection == nil ? 0 : 4)
                .opacity(0.9)
        }
        .frame(width: NodeView.nodeWidth, height: NodeView.portHeight)
    }
}
