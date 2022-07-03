/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


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
                .fill(node.color)
                .frame(width: NodeView.nodeWidth - 6, height: NodeView.titleHeight)
                .offset(x: 3, y: 4)
                .opacity(0.8)
            
            Text("\(node.name)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(node.nodeLabelColor)
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
        .gesture(TapGesture().modifiers(.shift).onEnded {
            if nodeCanvas.selection.isNodeSelected(node) {
                nodeCanvas.selection.deselectNode(node)
            } else {
                nodeCanvas.selection.selectNode(node)
            }
        })
        .onTapGesture {
            if nodeCanvas.selection.isNodeSelected(node) {
                nodeCanvas.selection.deselectNode(node)
            } else {
                nodeCanvas.selection.deselectAllNodes()
                nodeCanvas.selection.selectNode(node)
            }
        }
        .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged {
                value in
                if !nodeCanvas.isDraggingNode {
                    // if we are starting a new drag, and the current node is not selected
                    // then we assume this should be the only node that is dragged
                    if !nodeCanvas.selection.isNodeSelected(node) {
                        nodeCanvas.selection.deselectAllNodes()
                        nodeCanvas.selection.selectNode(node)
                    }
                    nodeCanvas.isDraggingNode = true
                    selection.startDragging(nodeCanvas)
                }
                
                let scaledTranslation = value.translation.unscaleBy(nodeCanvas.zoomScale)
                nodeCanvas.processNodeTranslation(scaledTranslation, nodes: selection.draggingNodes)
                nodeCanvas.nodeDragChange += 1
            }
            .onEnded {
                value in
                if nodeCanvas.isDraggingNode {
                    nodeCanvas.isDraggingNode = false
                    let scaledTranslation = value.translation.unscaleBy(nodeCanvas.zoomScale)
                    nodeCanvas.processNodeTranslation(scaledTranslation, nodes: selection.draggingNodes)
                    selection.stopDragging(nodeCanvas)
                    nodeCanvas.throttledSaveCanvas()
                }
            })
    }
}


// .stroke(edge.isAudio ? Color("edgeStrokeColor") : Color("Color-15") , lineWidth: edge.isAudio ? 3 : 1)
struct InputPortView: View {
    let port: Port
    
    var body: some View {
        HStack {
            Circle()
            // Color-16 = gray
            // Color-11 = navy blue
            // Color-5 = turqoise
            
                .fill( port.connections.isEmpty ? Color("Color-16") : (port.isAudioPort ? Color("Color-11") : Color("TagDistortion")))
                .frame(width: NodeView.portDiameter, height: NodeView.portDiameter)
                .overlay(Circle()
                    .stroke( port.connections.isEmpty ? Color(red: 0.8, green: 0.8, blue: 0.8) : (port.isAudioPort ? Color("Color-5") : Color("Color-15")), lineWidth: 3))
                .padding(port.connections.isEmpty ? 0 : -4)
                .overlay(Circle()
                    .fill(port.connections.isEmpty ? .clear : .white))
                .padding(port.connections.isEmpty ? 0 : 4)
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
                //.fill( port.connections.isEmpty ? Color("Color-16") : Color("Color-11"))
                .fill( port.connections.isEmpty ? Color("Color-16") : (port.isAudioPort ? Color("Color-11") : Color("TagDistortion")))
                .frame(width: NodeView.portDiameter, height: NodeView.portDiameter)
                .overlay(Circle()
                    //.stroke( port.connections.isEmpty ? Color(red: 0.8, green: 0.8, blue: 0.8) : Color("Color-5"), lineWidth: 3))
                    .stroke( port.connections.isEmpty ? Color(red: 0.8, green: 0.8, blue: 0.8) : (port.isAudioPort ? Color("Color-5") : Color("Color-15")), lineWidth: 3))
                .padding(port.connections.isEmpty ? 0 : -4)
                .overlay(Circle()
                    .fill(port.connections.isEmpty ? .clear : .white))
                .padding(port.connections.isEmpty ? 0 : 4)
                .opacity(0.9)
        }
        .frame(width: NodeView.nodeWidth, height: NodeView.portHeight)
    }
}

