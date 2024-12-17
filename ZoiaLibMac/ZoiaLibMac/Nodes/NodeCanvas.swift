/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


import SwiftUI

// This is the main class used for parsing and layout of a ZOIA patch based on the connections between modules
// Includes several options for the user to choose from in an attempt to handle different patch types
// as well as different ways of handling feedback loops, which is extremely prevelant in audio type modular patches
class NodeCanvas: ObservableObject {
    
    var appModel: AppViewModel?
    // these are all the displayed nodes and edges
    @Published var nodes: [Node] = []
    @Published var edges: [Edge] = []
    
    func nodeWithID(_ id: NodeID) -> Node? {
        return nodes.first(where: { $0.id == id })
    }
    
    @Published var patch: ObservableBinaryPatch?
    var bundlePath: URL?

    static let row0_y: CGFloat = 0
    static let col0_x: CGFloat = 0
    static let col5_x: CGFloat = (300 + 30) * 6
    static let minZoomScale: CGFloat = 0.05
    static let lastColIndex: Int = 5000
    static let column_spacing: CGFloat = 300
    
    @Published var nodesMinX: CGFloat = 0
    @Published var nodesMinY: CGFloat = 0
    @Published var nodesMaxX: CGFloat = 0
    @Published var nodesMaxY: CGFloat = 0

    @Published var selection: SelectionHandler
    
    @Published var zoomScale: CGFloat = 1.0 {
        didSet {
            let bounds = calculateBounds()
            if bounds.width.isFinite && bounds.height.isFinite {
                let xZoomOffset = ((bounds.width * oldValue) - (bounds.width * zoomScale)) / 2.0
                let yZoomOffset = ((bounds.height * oldValue) - (bounds.height * zoomScale)) / 2.0
                scrollOffset.x += xZoomOffset
                scrollOffset.y += yZoomOffset
            }
        }
    }

    @Published var scrollOffset: CGPoint = .zero
    @Published var dragOffset: CGSize = .zero
    var viewSize: CGSize = .zero
    @Published var isDraggingNode: Bool = false
    @Published var isDraggingCanvas: Bool = false
    @Published var isDraggingSelectionRect: Bool = false
    @Published var selectionRect: CGRect = .zero {
        didSet {
            if isDraggingSelectionRect {
                selectAllNodesInSelectionRect()
            }
        }
    }

    @Published var dragChange: Int = 0
    @Published var nodeDragChange: Int = 0
    
    @Published var connectionStyle: PipeType = .curved
    @Published var layoutAlgorithm: LayoutAlgorithm = .splitAudioCV
    var hiddenModules: Set<HidableModules> = []
    
    
    var ignoreLayoutChangeOnLoad: Bool = false
    var splitModeLayoutState: SplitModeLayoutState = .audio
    
    // collections used for layout algorithms
    var cvNodeTable: [Int: [Node]] = [:]
    var audioNodeTable: [Int:[Node]] = [:]
    var allNodesTable: [Int:[Node]] = [:]
    var nodeProcessingState: NodeProcessingState = .initialColumn(nextYOffset: NodeCanvas.row0_y)
    var modulesToPlace: [ParsedBinaryPatch.Module] = []
    var moduleTable: [Int: [ParsedBinaryPatch.Module]] = [:]


    var maxDepth: Int = 0
    var feedbackDetector: Int = 0
    var nodeListThrottleTimer: Timer?
    
    var loadedNodeCodableList: [NodeCodable] = []
    
    // used during testing various layout algorithms
    let dontSave = false
    
    enum NodeProcessingState {
        case initialColumn(nextYOffset: CGFloat)
        case arbitraryColumn(column: Int, nextYOffset: CGFloat)
    }
    
    init() {
        selection = SelectionHandler()
    }

    
    // MARK: - Node Selection
    func selectAllNodesInSelectionRect() {
        for node in nodes {
            let scaledSelectionRect = CGRect(x: (selectionRect.minX - scrollOffset.x) / zoomScale , y: (selectionRect.minY - scrollOffset.y) / zoomScale , width: selectionRect.width / zoomScale, height: selectionRect.height / zoomScale )
            let nodeRect = CGRect(x: (node.position.x) , y: (node.position.y) , width: NodeView.nodeWidth , height: node.height )
            if scaledSelectionRect.contains(nodeRect) || scaledSelectionRect.intersects(nodeRect)  {
                self.selection.selectNode(node)
            } else {
                if self.selection.selectedNodeIDs.contains(node.id) {
                    self.selection.deselectNode(node)
                }
            }
        }
    }

    // MARK: - Node Dragging
    func positionNode(_ node: Node, position: CGPoint) {
        node.position = position
        
        for edge in edges {
            if edge.srcConnection.node == node {
                edge.calculatePos()
            }
            if edge.dstConnection.node == node {
                edge.calculatePos()
            }
        }
    }
    
    // current strategy is to save nodes after 2 secs of inactivity after a drag
    func processNodeTranslation(_ translation: CGSize, nodes: [DragInfo]) {
        nodes.forEach { draginfo in
            if let node = nodeWithID(draginfo.id) {
                let nextPosition = draginfo.originalPosition.translatedBy(x: translation.width, y: translation.height)
                self.positionNode(node, position: nextPosition)
            }
        }
    }

    
    // MARK: - Serialization of NodeCanvas
    func open(url: URL, appModel: AppViewModel) {
        self.appModel = appModel
        
        ZoiaBundle.openZoiaBundle(filePath: url) {
            observablePatch in
            
            self.bundlePath = url
            self.patch = observablePatch
            
            if let patchName = self.patch?.parsedPatchFile?.name {
                // this is used by the global menu items... might remove
                self.appModel?.addLayoutChangeListener(nodeCanvasId: patchName, handler: {
                    algorithm in
                    if algorithm != self.layoutAlgorithm {
                        self.layoutAlgorithm = algorithm
                    }
                })
            }
            self.loadCanvas {
                _ in
                self.placeNodes(useSavedNodes: true)
                self.saveCanvas()
            }
        }
    }

    func throttledSaveCanvas() {
        nodeListThrottleTimer?.invalidate()
        nodeListThrottleTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {
            [weak self] timer in
            self?.saveCanvas()
            self?.nodeListThrottleTimer = nil
        }
    }

    private func saveCanvas(completion: (()->Void)? = nil) {
        guard dontSave == false else { completion?(); return }
        guard let bundleUrl = self.bundlePath else { completion?(); return }
        let nodeCanvasCodable = NodeCanvasCodable(nodeCanvas: self)
        self.loadedNodeCodableList = nodeCanvasCodable.nodeList
        print("saving canvas")
        ZoiaBundle.saveNodeCanvasCodable(bundleUrl: bundleUrl, nodeList: nodeCanvasCodable) {
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func loadCanvas(completion: @escaping (Bool)->Void) {
        guard let bundleUrl = self.bundlePath else { completion(false); return }
        ZoiaBundle.loadNodeCanvasCodable(bundleUrl: bundleUrl) {
            loadedNodeCanvas in
            
            DispatchQueue.main.async {
                
                if loadedNodeCanvas == nil { print("no saved canvas was found... we should be doing a full layout pass...") }
                guard loadedNodeCanvas != nil else { completion(false); return }
                //self.lastSavedNodeCanvas = loadedNodeCanvas
                self.loadedNodeCodableList = loadedNodeCanvas?.nodeList ?? []
                self.hiddenModules = Set(loadedNodeCanvas?.hiddenModules ?? [])
                self.connectionStyle = loadedNodeCanvas?.connectionStyle ?? .curved
                
                if self.layoutAlgorithm != loadedNodeCanvas?.algorithm {
                    self.ignoreLayoutChangeOnLoad = true
                }
                self.layoutAlgorithm = loadedNodeCanvas?.algorithm ?? .splitAudioCV
                self.scrollOffset = CGPoint(x: loadedNodeCanvas?.portalPosition?.x ?? 0, y: loadedNodeCanvas?.portalPosition?.y ?? 0)
                self.zoomScale = loadedNodeCanvas?.zoomScale ?? 0.99
                completion(true)
            }
        }
    }

    func updateLayout(newLayout: LayoutAlgorithm) {
        self.layoutAlgorithm = newLayout
        // TODO: find a better way to manage this
        // We want a change of layoutAlgorithm to always trigger a full layout pass
        // except for when the changing after loading a canvas - in that case we just want to load the saved positions
        if ignoreLayoutChangeOnLoad {
            ignoreLayoutChangeOnLoad = false
            return
        }
        if self.patch != nil {
            self.placeNodes(useSavedNodes: false)
            self.throttledSaveCanvas()
        }
    }
    
    func updateConnectionStyle(newStyle: PipeType) {
        self.connectionStyle = newStyle
        self.edges = []
        
        if !hiddenModules.contains(.audioConnections) || !hiddenModules.contains(.cvConnections) {
            self.placeConnections()
        }
        self.throttledSaveCanvas()
    }

    func updateFilteredNodes() {
        nodeListThrottleTimer?.invalidate()
        saveCanvas() {
            [weak self] in
            self?.placeNodes(useSavedNodes: true)
            self?.saveCanvas()
        }
    }
    
    // MARK: - Node Layout

    // main entry for layouting out nodes
    func placeNodes(useSavedNodes: Bool) {
        
        nodes = []
        edges = []
        allNodesTable = [:]
        moduleTable = [:]
        maxDepth = 0
        cvNodeTable = [:]
        audioNodeTable = [:]
        
        if useSavedNodes && !loadedNodeCodableList.isEmpty {
            placeNodesUsingSavedPos()
            // placing connections is always last
            if !hiddenModules.contains(.audioConnections) || !hiddenModules.contains(.cvConnections) {
                placeConnections()
            }
            _ = calculateBounds()
        } else {
            switch layoutAlgorithm {
            case .compact:
                layoutNodesInputToOutput()
            case .simpleRecursive:
                layoutNodesRecursive()
            case .splitAudioCV:
                layoutNodesSplitAudioCV()
            case .singleRow:
                layoutNodesInSingleRow()
            }
            // placing connections is always last
            if !hiddenModules.contains(.audioConnections) || !hiddenModules.contains(.cvConnections) {
                placeConnections()
            }
            fitNodesInView()
        }
    }

    // if no save, will simply place nodes in a single row
    func placeNodesUsingSavedPos() {
        
        var placedNodes: [Node] = []
        var curX: CGFloat = 0
        modulesToPlace = patch?.parsedPatchFile?.modules ?? []
        for module in modulesToPlace {
            if isModuleVisible(module: module) {
                let savedNode = loadedNodeCodableList.first(where: { $0.mod_idx == module.number })
                let nodePos = CGPoint(x: savedNode?.position.x ?? curX, y: savedNode?.position.y ?? 0)
                let node = Node(name: module.name ?? "", mod_idx: module.number, ref_mod_idx: module.ref_mod_idx, pos: nodePos)
                node.colorId = module.color
                for block in module.input_blocks {
                    node.createAndAppendPort(portType: .input, name: block.keys.first ?? "")
                }
                for block in module.output_blocks {
                    node.createAndAppendPort(portType: .output, name: block.keys.first ?? "")
                }
                curX += NodeView.nodeWidth + NodeCanvas.column_spacing
                placedNodes.append(node)
            }
        }
        nodes = placedNodes
    }
    
    func layoutNodesInSingleRow() {

        for node in nodes {
            node.depth = 0
            node.position.x = 0
            node.position.y = 0
            node.allChildNodes = []
            node.row_num = 0
        }
        var placedNodes: [Node] = []
        var curX: CGFloat = 0
        modulesToPlace = patch?.parsedPatchFile?.modules ?? []
        for module in modulesToPlace {
            if isModuleVisible(module: module) {
                let nodePos = CGPoint(x: curX, y: 0)
                let node = Node(name: module.name ?? "", mod_idx: module.number, ref_mod_idx: module.ref_mod_idx, pos: nodePos)
                node.colorId = module.color
                for block in module.input_blocks {
                    node.createAndAppendPort(portType: .input, name: block.keys.first ?? "")
                }
                for block in module.output_blocks {
                    node.createAndAppendPort(portType: .output, name: block.keys.first ?? "")
                }
                curX += NodeView.nodeWidth + 10
                placedNodes.append(node)
            }
        }
        nodes = placedNodes
    }
    
    // A layout algorithm that tries to split the layout into two horizontal "rows"
    // the top horizontal collection are all of the cv modules
    // the bottom horizontal collection are all of the audio modules
    func layoutNodesSplitAudioCV() {

        layoutNodesInSingleRow()
        placeConnections()
        
        // these nodes are the known output modules - always try to place them in last column of layout
        let output_node = nodes.first(where: { patch?.parsedPatchFile?.modules.item(at: $0.mod_idx)?.ref_mod_idx == 2 }) ??
        nodes.first(where: { patch?.parsedPatchFile?.modules.item(at: $0.mod_idx)?.ref_mod_idx == 95 }) ??
        nodes.first(where: { patch?.parsedPatchFile?.modules.item(at: $0.mod_idx)?.ref_mod_idx == 96 }) ??
        nodes.first(where: { patch?.parsedPatchFile?.modules.item(at: $0.mod_idx)?.ref_mod_idx == 60 })
        
        guard let output_node = output_node else { return }
                
        // score audio nodes first
        splitModeLayoutState = .audio
        scoreNodes(rootNode: output_node)
        
        // cv node layout pass
        splitModeLayoutState = .cv

        // now place cv nodes releative to each audio node
        for (_,depthList) in audioNodeTable {
            for node in depthList {
                node.allChildNodes = []
                for input in node.inputs {
                    for port in input.connections.filter({ $0.isAudioPort == false }) {
                        let leftNode = port.parentNode
                        if !node.allChildNodes.contains(leftNode) {
                            node.allChildNodes.insert(leftNode)
                            node.allChildNodes = node.allChildNodes.union(scoreLeft(node: leftNode, depth: node.depth + 1))
                        }
                    }
                }
            }
        }
        // step 3 - place all unconnected nodes
        let unplacedNodes = nodes.filter({ $0.depth == 0})
        if !unplacedNodes.isEmpty {
            maxDepth += 1
            cvNodeTable[maxDepth] = unplacedNodes
        }
        
        // now position all nodes
        var curX: CGFloat = NodeCanvas.col0_x
        var curY: CGFloat = NodeCanvas.row0_y

        // cv Nodes are placed up from 0 (negative Y)
        for depth in (1...maxDepth).reversed() {
            curY = NodeCanvas.row0_y
            for node in cvNodeTable[depth] ?? [] {
                curY -= (node.height + 50)
                node.position.x = curX
                node.position.y = curY
            }
            curX += (NodeView.nodeWidth + NodeCanvas.column_spacing)
        }

        // audio nodes are placed down from 0 (positive y)
        curY = NodeCanvas.row0_y
        curX = NodeCanvas.col0_x
        
        for depth in (1...maxDepth).reversed() {
            curY = NodeCanvas.row0_y
            for node in audioNodeTable[depth] ?? [] {
                node.position.x = curX
                node.position.y = curY
                curY += node.height + 50
            }
            curX += (NodeView.nodeWidth + NodeCanvas.column_spacing)
        }

        // now move single outputs into place (Zebu Audio Outs + HP out)
        // Zebu Audio Outs are single outs but they should be placed as a pair
        if output_node.ref_mod_idx == 95 {
            // find the other node for the output pair
            if let otherNode = nodes.first(where: { $0.ref_mod_idx == 96 }) {
                otherNode.position.x = output_node.position.x
                otherNode.position.y = output_node.position.y + output_node.height + 30
                curY = otherNode.position.y + otherNode.height + 30
            }
        }
        if output_node.ref_mod_idx == 96 {
            if let otherNode = nodes.first(where: { $0.ref_mod_idx == 95 }) {
                otherNode.position.x = output_node.position.x
                otherNode.position.y = output_node.position.y + output_node.height + 30
                curY = otherNode.position.y + otherNode.height + 30
            }
        }
        // move EuroBuro HP output to the output column
        if let hpNode = nodes.first(where: { $0.ref_mod_idx == 92 }) {
            hpNode.position.x = output_node.position.x
            hpNode.position.y = curY
        }
        
        nodes = nodes.sorted(by: { $0.position.x < $1.position.x })

        // remove connections we used for positioning
        edges = []
    }

    // this needs a lot of work in order to properly lay out patches with lots of feedback and patches with lots of UI / button modules
    func layoutNodesRecursive() {
        
        // we start off by placing nodes in single row (this filters out the non visible nodes)
        layoutNodesInSingleRow()
        placeConnections()

        // recursive methods starts at output node and recurses backwards from there
        // step 1 - find the output module
        
        let output_node = nodes.first(where: { patch?.parsedPatchFile?.modules.item(at: $0.mod_idx)?.ref_mod_idx == 2 }) ??
        nodes.first(where: { patch?.parsedPatchFile?.modules.item(at: $0.mod_idx)?.ref_mod_idx == 95 }) ??
        nodes.first(where: { patch?.parsedPatchFile?.modules.item(at: $0.mod_idx)?.ref_mod_idx == 96 }) ??
        nodes.first(where: { patch?.parsedPatchFile?.modules.item(at: $0.mod_idx)?.ref_mod_idx == 60 })
        
        guard let output_node = output_node else { return }
        
        // step 2 - score nodes - calculates each nodes depth as well as num of rows per column
        scoreNodes(rootNode: output_node)

        // step 3 - place all unconnected nodes
        var curX: CGFloat = NodeCanvas.col0_x
        var curY: CGFloat = NodeCanvas.row0_y

        let unplacedNodes = nodes.filter({ $0.depth == 0 })

        if unplacedNodes.isEmpty == false {
            maxDepth += 1
            allNodesTable[maxDepth] = unplacedNodes
        }

        for depth in (1...maxDepth).reversed() {
            curY = NodeCanvas.row0_y
            for node in allNodesTable[depth] ?? [] {
                node.position.x = curX
                node.position.y = curY
                curY += node.height + 30
            }
            if allNodesTable[depth]?.isEmpty == false {
                curX += (NodeView.nodeWidth + NodeCanvas.column_spacing)
            }
        }
        
        // now move single outputs into place (Zebu Audio Outs + HP out)
        // Zebu Audio Outs are single outs but they should be placed as a pair
        if output_node.ref_mod_idx == 95 {
            // find the other node for the output pair
            if let otherNode = nodes.first(where: { $0.ref_mod_idx == 96 }) {
                otherNode.position.x = output_node.position.x
                otherNode.position.y = output_node.position.y + output_node.height + 30
                curY = otherNode.position.y + otherNode.height + 30
            }
        }
        if output_node.ref_mod_idx == 96 {
            if let otherNode = nodes.first(where: { $0.ref_mod_idx == 95 }) {
                otherNode.position.x = output_node.position.x
                otherNode.position.y = output_node.position.y + output_node.height + 30
                curY = otherNode.position.y + otherNode.height + 30
            }
        }
        // move EuroBuro HP output to the output column
        if let hpNode = nodes.first(where: { $0.ref_mod_idx == 92 }) {
            hpNode.position.x = output_node.position.x
            hpNode.position.y = curY
        }
        
        var finalNodeList: [Node] = []
        for(_, nodeList) in allNodesTable {
            for node in nodeList {
                finalNodeList.append(node)
            }
        }
        nodes = finalNodeList
        // remove connections we used for positioning
        edges = []
    }
    
    func scoreLeft(node: Node, depth: Int) -> Set<Node> {
        // during testing of algorithms, it is a good idea to have infinite feedback loop detection
        feedbackDetector += 1
        if feedbackDetector > 5000 { print("we found a feedback loop - bailing..."); return node.allChildNodes }

        node.depth = max(node.depth, depth)
        maxDepth = max(maxDepth, node.depth)
        
        if layoutAlgorithm == .splitAudioCV {
            switch splitModeLayoutState {
            case .audio:

                if audioNodeTable[depth] == nil {
                    audioNodeTable[depth] = []
                }
                if audioNodeTable[depth]?.contains(node) == false {
                    audioNodeTable[depth]?.append(node)
                }
                
                for input in node.inputs {
                    for port in input.connections.filter({ $0.isAudioPort == true }) {
                        let leftNode = port.parentNode
                        
                        if !node.allChildNodes.contains(leftNode) {
                            node.allChildNodes.insert(leftNode)
                            node.allChildNodes = node.allChildNodes.union(scoreLeft(node: leftNode, depth: depth + 1))
                        }
                    }
                }
            case .cv:
                
                if cvNodeTable[depth] == nil {
                    cvNodeTable[depth] = []
                }
                if cvNodeTable[depth]?.contains(node) == false {
                    cvNodeTable[depth]?.append(node)
                }
                for input in node.inputs {
                    for port in input.connections.filter({ $0.isAudioPort == false }) {
                        let leftNode = port.parentNode
                        if !node.allChildNodes.contains(leftNode) {
                            node.allChildNodes.insert(leftNode)
                            node.allChildNodes = node.allChildNodes.union(scoreLeft(node: leftNode, depth: depth + 1))
                        }
                    }
                }
            case .unplaced:
                break
            }
        } else {
            
            // rows are now managed by the index of the allNodesTable[depth] array
            if allNodesTable[depth] == nil {
                allNodesTable[depth] = []
            }
            if allNodesTable[depth]?.contains(node) == false {
                allNodesTable[depth]?.append(node)
            }
            
            for input in node.inputs {
                for port in input.connections {
                    let leftNode = port.parentNode
                    if !node.allChildNodes.contains(leftNode) {
                        node.allChildNodes.insert(leftNode)
                        node.allChildNodes = node.allChildNodes.union(scoreLeft(node: leftNode, depth: depth + 1))
                    }
                }
            }
        }
        return node.allChildNodes
    }
    
    
    func scoreNodes(rootNode: Node) {
        // node level > 1 are placed nodes : node level == 0 is an unplaced node
        rootNode.allChildNodes = scoreLeft(node: rootNode, depth: 1)
    }
    
    // this method puts all nodes with no inputs in 1st column and completes layout following output->input
    // no recursion, no scoring of node placement, no detection of crossed edges
    // it's bad - but it is dirt simple and it works
    func layoutNodesInputToOutput() {
        
        modulesToPlace = patch?.parsedPatchFile?.modules ?? []
        nodeProcessingState = .initialColumn(nextYOffset: NodeCanvas.row0_y)
        
        while modulesToPlace.count > 0 {
            
            switch nodeProcessingState {
            case .initialColumn(let nextYOffset):
                
                // now move all nodes that have no inputs to the first column
                let connects_with_dest = (patch?.parsedPatchFile?.blockConnections ?? []).filter { $0.dest_module_idx != nil }
                let all_mods_with_dest = connects_with_dest.map { $0.dest_module_idx ?? 5000 }
                let no_input_modules: [Bool:[ParsedBinaryPatch.Module]] = Dictionary.init(grouping: modulesToPlace, by: { proposedModule in
                    return !all_mods_with_dest.contains(proposedModule.number)
                })

                allNodesTable[0] = []
                moduleTable[0] = []
                allNodesTable[NodeCanvas.lastColIndex] = []
                moduleTable[NodeCanvas.lastColIndex] = []

                var curY: CGFloat = nextYOffset
                for module in no_input_modules[true] ?? [] {
                    
                    if isModuleVisible(module: module) {
                        moduleTable[0]?.append(module)
                        let nodePos = CGPoint(x: NodeCanvas.col0_x, y: curY)
                        let node = Node(name: module.name ?? "", mod_idx: module.number, ref_mod_idx: module.ref_mod_idx, pos: nodePos)
                        node.colorId = module.color
                        for block in module.input_blocks {
                            node.createAndAppendPort(portType: .input, name: block.keys.first ?? "")
                        }
                        for block in module.output_blocks {
                            node.createAndAppendPort(portType: .output, name: block.keys.first ?? "")
                        }
                        allNodesTable[0]?.append(node)
                        curY += (node.height + 50)
                    }
                }
                
                // now move all nodes that have no outputs to the last column
                let connects_with_src = (patch?.parsedPatchFile?.blockConnections ?? []).filter { $0.source_module_idx != nil }
                let all_mods_with_src = connects_with_src.map { $0.source_module_idx ?? 5000 }
                
                modulesToPlace = no_input_modules[false] ?? []
                
                let no_ouput_modules: [Bool: [ParsedBinaryPatch.Module]] = Dictionary.init(grouping: modulesToPlace, by: { proposedModule in
                    return !all_mods_with_src.contains(proposedModule.number)
                })
                
                curY = nextYOffset
                
                for module in no_ouput_modules[true] ?? [] {
                    
                    if isModuleVisible(module: module) {
                        moduleTable[NodeCanvas.lastColIndex]?.append(module)
                        let nodePos = CGPoint(x: NodeCanvas.col5_x, y: curY)
                        let node = Node(name: module.name ?? "", mod_idx: module.number, ref_mod_idx: module.ref_mod_idx, pos: nodePos)
                        node.colorId = module.color
                        for block in module.input_blocks {
                            node.createAndAppendPort(portType: .input, name: block.keys.first ?? "")
                        }
                        for block in module.output_blocks {
                            node.createAndAppendPort(portType: .output, name: block.keys.first ?? "")
                        }
                        allNodesTable[NodeCanvas.lastColIndex]?.append(node)
                        curY += (node.height + 50)
                    }

                }
                
                modulesToPlace = no_ouput_modules[false] ?? []
                nodeProcessingState = .arbitraryColumn(column: 1, nextYOffset: NodeCanvas.row0_y)
                
            case .arbitraryColumn(let column, let nextYOffset):
                
                allNodesTable[column] = []
                moduleTable[column] = []
                
                var curY: CGFloat = nextYOffset
                let prevColModules = moduleTable[column - 1] ?? []
                let prevColModIdx = Set(prevColModules.map { $0.number })
                
                var columnGrouping : [Bool:[ParsedBinaryPatch.Module]] = Dictionary(grouping: modulesToPlace, by: { proposedModule in
                    return (patch?.parsedPatchFile?.blockConnections ?? []).contains(where: { $0.dest_module_idx == proposedModule.number && prevColModIdx.contains($0.source_module_idx ?? 500)  })
                })
                
                if columnGrouping[true] == nil || columnGrouping[true]?.count == 0 {
                    columnGrouping[true] = modulesToPlace
                    columnGrouping[false] = []
                }
                
                for module in columnGrouping[true] ?? [] {
                    if isModuleVisible(module: module) {
                        moduleTable[column]?.append(module)
                        let alg_x = NodeCanvas.col0_x + (NodeView.nodeWidth + NodeCanvas.column_spacing) * CGFloat(column)
                        let alg_y = curY
                        let nodePos = CGPoint(x: alg_x, y: alg_y)
                        let node = Node(name: module.name ?? "", mod_idx: module.number, ref_mod_idx: module.ref_mod_idx, pos: nodePos)
                        node.colorId = module.color
                        for block in module.input_blocks {
                            node.createAndAppendPort(portType: .input, name: block.keys.first ?? "")
                        }
                        for block in module.output_blocks {
                            node.createAndAppendPort(portType: .output, name: block.keys.first ?? "")
                        }
                        allNodesTable[column]?.append(node)
                        curY += (node.height + 50)
                    }
                }
                modulesToPlace = columnGrouping[false] ?? []
                nodeProcessingState = .arbitraryColumn(column: column + 1, nextYOffset: NodeCanvas.row0_y)
            }
        }
        
        // now move the output col to the last column processed
        let lastCol = allNodesTable.keys.count - 1
        
        for node in allNodesTable[NodeCanvas.lastColIndex] ?? [] {
            node.position.x = (NodeCanvas.col0_x + (NodeView.nodeWidth + NodeCanvas.column_spacing) * CGFloat(lastCol))
        }

        for (_, values) in allNodesTable {
            for node in values {
                nodes.append(node)
            }
        }
    }

    func placeConnections() {
        
        clearConnections()
        for blockConnection in patch?.parsedPatchFile?.blockConnections ?? [] {
            
            guard let srcNode = self.nodes.first(where: { $0.mod_idx == blockConnection.source_module_idx }) else { continue }
            
            var dstNode: Node?
            dstNode = self.nodes.first(where: { $0.mod_idx == blockConnection.dest_module_idx })
            guard let dstNode = dstNode else { continue }
            guard let srcPortIndex = blockConnection.source_block_idx else { continue }
            guard let destPortIndex = blockConnection.dest_block_idx else { continue }
            guard let srcPort = srcNode.outputs.item(at: srcPortIndex) else  { continue }
            guard let dstPort = dstNode.inputs.item(at: destPortIndex) else {continue }
            
            let srcConnection = NodeConnection(node: srcNode, port: srcPort)
            let endConnection = NodeConnection(node: dstNode, port: dstPort)
            
            _ = srcPort.connectTo(dstPort)
            _ = dstPort.connectTo(srcPort)

            let edge = Edge(src: srcConnection, dst: endConnection, strength: 100)
            
            if srcPort.isAudioPort || dstPort.isAudioPort {
                if !hiddenModules.contains(.audioConnections) {
                    self.edges.append(edge)
                }
            } else {
                if !hiddenModules.contains(.cvConnections) {
                    self.edges.append(edge)
                }
            }
        }
    }
    
    func clearConnections() {
        for node in nodes {
            for input in node.inputs {
                input.connections = []
            }
            for output in node.outputs {
                output.connections = []
            }
        }
        
        self.edges = []
    }
    
    
    // MARK: - Private Utility Functions
    private func fitNodesInView() {
        
        let bounds = calculateBounds()
        if viewSize.width > 0 && viewSize.height > 0 && bounds.width > 0 && bounds.height > 0 {
            let neededZoomForWidth = self.viewSize.width / bounds.width
            let neededZoomForHeight = self.viewSize.height / bounds.height
            let targetZoom = min(neededZoomForWidth, neededZoomForHeight)
            if targetZoom < 1.0 && targetZoom > 0.05 {
                zoomScale = targetZoom - 0.05
            }
        }
        scrollOffset.x = nodesMinX * -1.0 * zoomScale
        scrollOffset.y = nodesMinY * -1.0 * zoomScale
    }
    
    
    private func isModuleVisible(module: ParsedBinaryPatch.Module) -> Bool {
        return !self.hiddenModules.contains(where: { $0.rawValue == module.ref_mod_idx })
    }
    
    private func calculateBounds() -> CGSize {
        
        nodesMinX = .infinity
        nodesMinY = .infinity
        nodesMaxX = .leastNonzeroMagnitude
        nodesMaxY = .leastNonzeroMagnitude
        for node in nodes {
            nodesMinX = min(nodesMinX, node.position.x)
            nodesMinY = min(nodesMinY, node.position.y)
            nodesMaxX = max(node.position.x + NodeView.nodeWidth, nodesMaxX)
            nodesMaxY = max(node.position.y + node.height, nodesMaxY)
        }
        let bounds = CGSize(width: nodesMaxX - nodesMinX, height: nodesMaxY - nodesMinY)
        return bounds
    }
    
}
