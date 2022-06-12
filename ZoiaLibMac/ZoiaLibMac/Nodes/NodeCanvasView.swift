// GNU GENERAL PUBLIC LICENSE
//   Version 3, 29 June 2007
//
// Copyright (c) 2022 Johnny Turpin (github.com/johnnyturpin-aow)

import SwiftUI

struct NodeCanvasView: View {
    
    @StateObject var nodeCanvas = NodeCanvas()
    @EnvironmentObject private var model: AppViewModel
    
    var body: some View {
        contents
            .onOpenURL(perform:  {
                url in
                nodeCanvas.open(url: url, appModel: model)
            })
    }
    
    private var contents: some View {
        GeometryReader {
            geometry in
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Color("nodeViewBackground"))
                DistributionView(nodeCanvas: nodeCanvas)
                    .padding(0)
                    .scaleEffect(nodeCanvas.zoomScale)
                    .offset(x: nodeCanvas.portalPosition.x + nodeCanvas.dragOffset.width, y: nodeCanvas.portalPosition.y + nodeCanvas.dragOffset.height)
                    .animation(.linear, value: nodeCanvas.dragChange)
            }
            .padding(0)
            .clipped()
            .onTapGesture(count: 1, perform: {
                nodeCanvas.selection.deselectAllNodes()
            })
            .gesture(DragGesture()
                .onChanged {
                    value in
                    self.onDraggingStarted(value, containerSize: geometry.size, offset: CGPoint(x: 0, y: 0))
                    nodeCanvas.dragChange += 1
                }
                .onEnded {
                    value in
                    self.onDraggingEnded(value)
                })
            
        }
        .padding(0)
        .navigationTitle(nodeCanvas.patch?.parsedPatchFile?.name ?? "Node Editor")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Text("Connection Style:")
                Picker("Connection Style", selection: $nodeCanvas.connectionStyle) {
                    Image(systemName: PipeType.straight.sysImage).tag(PipeType.straight)
                    Image(systemName: PipeType.right_angle.sysImage).tag(PipeType.right_angle)
                    Image(systemName: PipeType.curved.sysImage).tag(PipeType.curved)
                }
                .pickerStyle(.segmented)
                Spacer()
                Text("Scale:")
                Slider(value: $nodeCanvas.zoomScale, in: 0.1...2.0)
                    .padding(.leading, 50)
                    .frame(width: 300)
            }
        }
    }

    func onDraggingStarted(_ value: DragGesture.Value, containerSize: CGSize, offset: CGPoint) {
        if nodeCanvas.isDraggingNode { return }
        if !nodeCanvas.isDraggingCanvas {
            nodeCanvas.isDraggingCanvas = true
        }
        nodeCanvas.dragOffset = value.translation
    }
    
    func onDraggingEnded(_ value: DragGesture.Value) {
        if nodeCanvas.isDraggingCanvas {
            nodeCanvas.isDraggingCanvas = false
            nodeCanvas.portalPosition = CGPoint(x: nodeCanvas.portalPosition.x + value.translation.width,
                                                y: nodeCanvas.portalPosition.y + value.translation.height)
            nodeCanvas.dragOffset = .zero
        }
    }
}

