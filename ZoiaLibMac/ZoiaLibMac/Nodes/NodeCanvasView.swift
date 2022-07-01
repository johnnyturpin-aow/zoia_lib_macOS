// GNU GENERAL PUBLIC LICENSE
//   Version 3, 29 June 2007
//
// Copyright (c) 2022 Johnny Turpin (github.com/johnnyturpin-aow)

import Cocoa
import SwiftUI
import Combine

struct NodeCanvasView: View {
    
    @StateObject var nodeCanvas = NodeCanvas()
    @EnvironmentObject private var model: AppViewModel
    @State var subs = Set<AnyCancellable>() // Cancel onDisappear
    @State private var phase = 0.0
    
    var body: some View {
        contents
            .onOpenURL(perform:  {
                url in
                nodeCanvas.open(url: url, appModel: model)
            })
    }
    
    func trackScrollWheel() {
        NSApp.publisher(for: \.currentEvent)
            .filter { event in event?.type == .scrollWheel }
            .throttle(for: .milliseconds(25),
                      scheduler: DispatchQueue.main,
                      latest: true)
            .sink { event in
                // for now we have a minimum zoomScale but not a mazimum
                let targetZoomScale = nodeCanvas.zoomScale + (CGFloat(event?.deltaY ?? 0) / 16)
                nodeCanvas.zoomScale = max(targetZoomScale, NodeCanvas.minZoomScale)
                nodeCanvas.dragChange += 1
                nodeCanvas.throttledSaveCanvas()
            }
            .store(in: &subs)
    }

    private var contents: some View {
        
        GeometryReader {
            geometry in
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Color("nodeViewBackground"))
                DistributionView(nodeCanvas: nodeCanvas)
                    .padding(0)
                    .scaleEffect(nodeCanvas.zoomScale, anchor: .topLeading)
                    .offset(x: nodeCanvas.portalPosition.x + nodeCanvas.dragOffset.width, y: nodeCanvas.portalPosition.y + nodeCanvas.dragOffset.height)
                    .animation(.linear, value: nodeCanvas.dragChange)
                Rectangle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4], dashPhase: phase))
                    .foregroundColor(.white)
                    .offset(x: nodeCanvas.selectionRect.minX, y: nodeCanvas.selectionRect.minY)
                    .frame(width: nodeCanvas.selectionRect.width, height: nodeCanvas.selectionRect.height)
                    .opacity(nodeCanvas.isDraggingSelectionRect ? 0.6 : 0)
                    .onAppear {
                        withAnimation(.linear.repeatForever(autoreverses: false)) {
                            phase -= 10
                        }
                    }
            }
            .onAppear {
                nodeCanvas.viewSize = geometry.size
            }
            .onChange(of: geometry.size) {
                newSize in
                nodeCanvas.viewSize = newSize
            }
            .padding(0)
            .clipped()
            .onTapGesture(count: 1, perform: {
                nodeCanvas.selection.deselectAllNodes()
            })
            .gesture(DragGesture()
                .modifiers(.option)
                .onChanged {
                    value in
                    self.onDraggingStarted(value, containerSize: geometry.size, offset: CGPoint(x: 0, y: 0))
                    nodeCanvas.dragChange += 1
                }
                .onEnded {
                    value in
                    self.onDraggingEnded(value)
                    nodeCanvas.throttledSaveCanvas()
                })
            .gesture(DragGesture()
                .modifiers(.command)
                .onChanged {
                    value in
                    
                    // calculate which axis the user is trying to zoom with
                    let largestChange = max(value.translation.width, value.translation.height)
                    let targetZoomScale = nodeCanvas.zoomScale - largestChange / 1000
                    nodeCanvas.zoomScale = max(targetZoomScale, NodeCanvas.minZoomScale)
                    nodeCanvas.dragChange += 1
                    
                }
                .onEnded {
                    value in
                    let targetZoomScale = nodeCanvas.zoomScale - value.translation.height / 1000
                    nodeCanvas.zoomScale = max(targetZoomScale, NodeCanvas.minZoomScale)
                    nodeCanvas.dragChange += 1
                    nodeCanvas.throttledSaveCanvas()
                })
            .gesture(DragGesture()
                .onChanged {
                    value in
                    self.selectionRectStarted(value, containerSize: geometry.size, offset: CGPoint(x: 0, y: 0))
                }
                .onEnded {
                    value in
                    self.selectionRectEnded(value)
                })
        }
        .onAppear {
            trackScrollWheel()
        }
        .padding(0)
        .navigationTitle(nodeCanvas.patch?.parsedPatchFile?.name ?? "Node Editor")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                HStack {
                    Text("Layout Algorithm")
                    Picker("Layout Algorithm", selection: $nodeCanvas.layoutAlgorithm) {
                        HStack {
                            Text(LayoutAlgorithm.singleRow.rawValue)
                            Image(systemName: LayoutAlgorithm.singleRow.image)
                        }.tag(LayoutAlgorithm.singleRow)
                        HStack {
                            Text(LayoutAlgorithm.simple.rawValue)
                            Image(systemName: LayoutAlgorithm.simple.image)
                        }.tag(LayoutAlgorithm.simple)
                        HStack {
                            Text(LayoutAlgorithm.simpleRecursive.rawValue)
                            Image(systemName: LayoutAlgorithm.simpleRecursive.image)
                        }.tag(LayoutAlgorithm.simpleRecursive)
                        HStack {
                            Text(LayoutAlgorithm.moveChildNodes.rawValue)
                            Image(systemName: LayoutAlgorithm.moveChildNodes.image)
                        }.tag(LayoutAlgorithm.moveChildNodes)
                        HStack {
                            Text(LayoutAlgorithm.splitAudioCV.rawValue)
                            Image(systemName: LayoutAlgorithm.splitAudioCV.image)
                        }.tag(LayoutAlgorithm.splitAudioCV)
                    }
                    .onChange(of: nodeCanvas.layoutAlgorithm, perform: { newLayout in
                        nodeCanvas.updateLayout(newLayout: newLayout)
                    })
                    
                }
                HStack {
                    Divider()
                    Text("Connection Style:")
                    Picker("Connection Style", selection: $nodeCanvas.connectionStyle) {
                        Image(systemName: PipeType.straight.sysImage).tag(PipeType.straight)
                        Image(systemName: PipeType.right_angle.sysImage).tag(PipeType.right_angle)
                        Image(systemName: PipeType.curved.sysImage).tag(PipeType.curved)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: nodeCanvas.connectionStyle, perform: { newValue in
                        nodeCanvas.updateConnectionStyle(newStyle: newValue)
                    })
                    Spacer()
                }

                HStack {
                    Divider()
                    Text("Show/Hide:")
                    ForEach(HidableModules.allCases) {
                        module in
                        Toggle(isOn: Binding(get: { return nodeCanvas.hiddenModules.contains(module) }, set: {
                            isOn in
                            if isOn {
                                nodeCanvas.hiddenModules.insert(module)
                            } else {
                                nodeCanvas.hiddenModules.remove(module)
                            }
                            nodeCanvas.updateFilteredNodes()
                        }), label: {
                            Label(module.description, systemImage: module.image)
                                .foregroundColor(nodeCanvas.hiddenModules.contains(module) ? AppColors.ioActivated : AppColors.ioNormal)
                        })
                        .help(module.description)
                    }
                    Spacer()
                }
                HStack {
                    Divider()
                    Text("Scale:")
                    Slider(value: $nodeCanvas.zoomScale, in: 0.05...2.0)
                        .padding(.leading, 50)
                        .frame(width: 300)
                    Spacer()
                }
            }
        }
    }
    
    func selectionRectStarted(_ value: DragGesture.Value, containerSize: CGSize, offset: CGPoint) {
        if nodeCanvas.isDraggingNode { return }
        if !nodeCanvas.isDraggingSelectionRect {
            nodeCanvas.isDraggingSelectionRect = true
        }

        nodeCanvas.selectionRect = CGRect(x: value.startLocation.x, y: value.startLocation.y, width: value.translation.width, height: value.translation.height)
    }
    
    func selectionRectEnded(_ value: DragGesture.Value) {
        nodeCanvas.isDraggingSelectionRect = false
        nodeCanvas.selectionRect = .zero
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
            
            nodeCanvas.throttledSaveCanvas()
        }
    }
}

