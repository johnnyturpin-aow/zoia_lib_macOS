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
            .throttle(for: .milliseconds(200),
                      scheduler: DispatchQueue.main,
                      latest: true)
            .sink { event in
                print("scrollWheel moved by \(event?.deltaY ?? 0)")
                
                nodeCanvas.zoomScale += (CGFloat(event?.deltaY ?? 0) / 8)
                //self?.goBackOrForwardBy(delta: Int(event?.deltaY ?? 0))
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
                    .scaleEffect(nodeCanvas.zoomScale)
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
                        Image(systemName: LayoutAlgorithm.singleRow.image).tag(LayoutAlgorithm.singleRow)
                        Image(systemName: LayoutAlgorithm.simple.image).tag(LayoutAlgorithm.simple)
                        Image(systemName: LayoutAlgorithm.simpleRecursive.image).tag(LayoutAlgorithm.simpleRecursive)
                        Image(systemName: LayoutAlgorithm.moveChildNodes.image).tag(LayoutAlgorithm.moveChildNodes)
                        Image(systemName: LayoutAlgorithm.recurseOnFeedback.image).tag(LayoutAlgorithm.recurseOnFeedback)
                    }
                    .pickerStyle(.segmented)
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
                    Spacer()
                }

                HStack {
                    Divider()
                    Text("Hidden Modules:")
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
                        })
                        .help(module.description)
                    }
                    
                    Spacer()
                }
                HStack {
                    Divider()
                    Text("Scale:")
                    Slider(value: $nodeCanvas.zoomScale, in: 0.1...2.0)
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
        
        let scaledStartLocation = value.startLocation
        let scaledTranslation = value.translation
        nodeCanvas.selectionRect = CGRect(x: scaledStartLocation.x, y: scaledStartLocation.y, width: scaledTranslation.width, height: scaledTranslation.height)
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
        }
    }
}

