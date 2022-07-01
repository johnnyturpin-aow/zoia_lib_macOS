// GNU GENERAL PUBLIC LICENSE
//   Version 3, 29 June 2007
//
// Copyright (c) 2022 Johnny Turpin (github.com/johnnyturpin-aow)

import SwiftUI

enum PipeType: String, Identifiable, Codable {
    
    case curved         // = "point.topleft.down.curvedto.point.bottomright.up.fill"
    case right_angle    // = "chevron.forward"
    case straight       // = "line.diagonal"
    
    
    var sysImage: String {
        switch self {
        case .curved: return "point.topleft.down.curvedto.point.bottomright.up.fill"
        case .right_angle: return "chevron.forward"
        case .straight: return "line.diagonal"
        }
    }
    var id: String { return rawValue }
}

struct NodeCanvasCodable: Codable {
    
    let nodeList: [NodeCodable]
    let connectionStyle: PipeType?
    let hiddenModules: [HidableModules]?
    let algorithm: LayoutAlgorithm?
    let zoomScale: Double?
    let portalPosition: CanvasPosition?
    
    init(nodeCanvas: NodeCanvas) {
        
        let listOfNodes: [NodeCodable] = nodeCanvas.nodes.map {
            node in
            let canvasPos = CanvasPosition(x: node.position.x, y: node.position.y)
            let nodeColor = CodableColor(color: node.color)
            let codableNode = NodeCodable(mod_idx: node.mod_idx, position: canvasPos, color: nodeColor)
            return codableNode
        }
        
        self.nodeList = listOfNodes
        self.connectionStyle = nodeCanvas.connectionStyle
        self.hiddenModules = Array(nodeCanvas.hiddenModules)
        self.algorithm = nodeCanvas.layoutAlgorithm
        self.zoomScale = nodeCanvas.zoomScale
        self.portalPosition = CanvasPosition(x: nodeCanvas.portalPosition.x, y: nodeCanvas.portalPosition.y)
    }
}


enum LayoutAlgorithm: String, Codable, Identifiable {
    
    case singleRow = "Single Row"
    case simple = "Compact"
    case simpleRecursive = "Recursive 1"
    case moveChildNodes = "Recursive 2"
    case recurseOnFeedback = "Recursive 3"

    var id: String { return rawValue }
    
    
    var image: String {
        switch self {
        case .singleRow:
            return "minus.square"
        case .simple:
            return "square.grid.3x3.square"
        case .simpleRecursive:
            return "1.square"
        case .moveChildNodes:
            return "2.square"
        case .recurseOnFeedback:
            return "3.square"
        }
    }
    
}

// 15 = PushButton
// 16 = Keyboard
// 45 = Value
// 56 = UI Button
// 81 = Pixel
enum HidableModules: Int, Codable, Identifiable, CaseIterable {
    case pushButton = 15
    case keyboard = 16
    case valueInput = 45
    case uiButton = 56
    case pixel = 81
    case connections = 9999
    
    var id: Int { rawValue }
    
    var description: String {
        switch self {
        case .keyboard: return "Keyboard"
        case .pixel: return "Pixel"
        case .pushButton: return "Push Button"
        case .uiButton: return "UI Button"
        case .valueInput: return "Value"
        case .connections: return "Connections"
        }
    }
    
    var image: String {
        switch self {
        case .pushButton:
            return "square.stack"
        case .keyboard:
            return "square.grid.3x2"
        case .valueInput:
            return "number.square"
        case .uiButton:
            return "square.grid.3x3.topleft.filled"
        case .pixel:
            return "squareshape.dashed.squareshape"
        case .connections:
            return "point.topleft.down.curvedto.point.bottomright.up.fill"
        }
    }
}

class NodeCanvas: ObservableObject {
    
    
    var appModel: AppViewModel?
    // these are all the displayed nodes and edges
    @Published var nodes: [Node] = []
    @Published var edges: [Edge] = []
    
    @Published var patch: ObservableBinaryPatch?
    var bundlePath: URL?
    
    init() {
        selection = SelectionHandler()
    }

    static let row0_y: CGFloat = 0
    static let col0_x: CGFloat = 0
    static let col5_x: CGFloat = (300 + 30) * 6
    static let minZoomScale: CGFloat = 0.05
    static let maxOffset: Int = 30
    
    static let lastColIndex: Int = 5000
    static let column_spacing: CGFloat = 300
    // Int is the column - the array of node are the nodes down that column
    @Published var selection: SelectionHandler
    @Published var zoomScale: CGFloat = 1.0
    @Published var portalPosition: CGPoint = .zero
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

    func selectAllNodesInSelectionRect() {
        
        for node in nodes {
            let scaledSelectionRect = CGRect(x: (selectionRect.minX - portalPosition.x) / zoomScale , y: (selectionRect.minY - portalPosition.y) / zoomScale , width: selectionRect.width / zoomScale, height: selectionRect.height / zoomScale )
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
    
    @Published var dragChange: Int = 0
    @Published var nodeDragChange: Int = 0
    @Published var connectionStyle: PipeType = .curved
    
    func updateConnectionStyle(newStyle: PipeType) {
        self.connectionStyle = newStyle
        self.edges = []
        if !self.hiddenModules.contains(.connections) {
            self.placeConnections()
            self.throttledSaveCanvas()
        }
    }
    
    @Published var layoutAlgorithm: LayoutAlgorithm = .moveChildNodes
    func updateLayout(newLayout: LayoutAlgorithm) {
        self.layoutAlgorithm = newLayout
        if self.patch != nil {
            self.placeNodes(useSavedNodes: false)
            self.throttledSaveCanvas()
        }
    }

    var nodeProcessingState: NodeProcessingState = .initialColumn(nextYOffset: NodeCanvas.row0_y)
    var modulesToPlace: [ParsedBinaryPatch.Module] = []
    var nodeTable: [Int:[Node]] = [:]
    var moduleTable: [Int: [ParsedBinaryPatch.Module]] = [:]
    var hiddenModules: Set<HidableModules> = []

    
    // v2 node layout algorithm
    var maxDepth: Int = 0
    var maxNumRows: Int = 0
    var ohShit: Int = 0
    
    let dontSave = false
    
    var nodeListSaveTimer: Timer?

    //var lastSavedNodeCanvas: NodeCanvasCodable?
    
    var loadedNodeCodableList: [NodeCodable] = []
    var adjustmentRoot: Node?
    var feedbackList: Set<Node> = []
    
    enum NodeProcessingState {
        case initialColumn(nextYOffset: CGFloat)
        case arbitraryColumn(column: Int, nextYOffset: CGFloat)
    }
    
    
    func throttledSaveCanvas() {
        nodeListSaveTimer?.invalidate()
        nodeListSaveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {
            [weak self] timer in
            if self?.dontSave == false  {
                self?.saveCanvas()
            }
            self?.nodeListSaveTimer = nil
        }
    }
    
    
    
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
                    
                    print("algorithm changed")
                    if algorithm != self.layoutAlgorithm {
                        self.layoutAlgorithm = algorithm
                    }
                })
            }
            
            print("loading saved canvas...")
            self.loadCanvas {
                _ in
                self.placeNodes(useSavedNodes: true)
                self.saveCanvas()
            }
        }
    }

    
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
    
    func nodeWithID(_ id: NodeID) -> Node? {
        return nodes.first(where: { $0.id == id })
    }
    
    private func saveCanvas(completion: (()->Void)? = nil) {
        guard let bundleUrl = self.bundlePath else { return }
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
                self.layoutAlgorithm = loadedNodeCanvas?.algorithm ?? .moveChildNodes
                self.portalPosition = CGPoint(x: loadedNodeCanvas?.portalPosition?.x ?? 0, y: loadedNodeCanvas?.portalPosition?.y ?? 0)
                self.zoomScale = loadedNodeCanvas?.zoomScale ?? 0.99
                completion(true)
            }
        }
    }
    
    var randomOffset: CGFloat {
        return self.connectionStyle == .right_angle ? CGFloat(Int.random(in: (-1 * NodeCanvas.maxOffset)...NodeCanvas.maxOffset)) : 0
    }

    func isModuleVisible(module: ParsedBinaryPatch.Module) -> Bool {
        return !self.hiddenModules.contains(where: { $0.rawValue == module.ref_mod_idx })
    }

    func updateFilteredNodes() {
        nodeListSaveTimer?.invalidate()
        saveCanvas() {
            [weak self] in
            self?.placeNodes(useSavedNodes: true)
            self?.saveCanvas()
        }
    }


    
    func fitNodesInView() {
        
        var minX: CGFloat = .infinity
        var minY: CGFloat = .infinity
        var maxX: CGFloat = .leastNonzeroMagnitude
        var maxY: CGFloat = .leastNonzeroMagnitude
        
        var tlNode: Node?
        var brNode: Node?
        for node in nodes {
            if node.position.x < minX || node.position.y < minY {
                tlNode = node
            }
            if (node.position.x + NodeView.nodeWidth) > maxX || (node.position.y + node.height) > maxY {
                brNode = node
            }
            minX = min(minX, node.position.x)
            minY = min(minY, node.position.y)
            maxX = max(node.position.x + NodeView.nodeWidth, maxX)
            maxY = max(node.position.y + node.height, maxY)
        }
        
        self.portalPosition.x = minX + viewSize.width * 0.05
        self.portalPosition.y = minY + viewSize.height * 0.05
        
        let totalWidth = maxX - minX
        let totalHeight = maxY - minY
        
        if viewSize.width > 0 && viewSize.height > 0 && totalWidth > 0 && totalHeight > 0 {
            let neededZoomForWidth = self.viewSize.width / totalWidth
            let neededZoomForHeight = self.viewSize.height / totalHeight
            
            let targetZoom = min(neededZoomForWidth, neededZoomForHeight)
            if targetZoom < 1.0 && targetZoom > 0.05 {
                zoomScale = targetZoom - 0.05
            }
        }
    }
    
    func placeNodes(useSavedNodes: Bool) {
        nodes = []
        edges = []
        
        print("placing nodes...")
        
        if useSavedNodes && !loadedNodeCodableList.isEmpty {
            print("we are placing nodes using saved positions...")
            placeNodesUsingSavedPos()
            // placing connections is always last
            if !hiddenModules.contains(.connections) {
                placeConnections()
            }
        } else {
            if useSavedNodes == false { print("not using saved nodes - using chosen layout algorithm") }
            if useSavedNodes && loadedNodeCodableList.isEmpty {
                print("loadedNodeCodableList is empty - this is our first layout pass...")
            }
            switch layoutAlgorithm {
            case .simple:
                layoutNodesInputToOutput()
            case .simpleRecursive:
                layoutNodesRecursive()
            case .moveChildNodes:
                layoutNodesRecursive()
            case .recurseOnFeedback:
                layoutNodesRecursive()
            case .singleRow:
                layoutNodesInSingleRow()
            }
            // placing connections is always last
            if !hiddenModules.contains(.connections) {
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
                curX += NodeView.nodeWidth + NodeCanvas.column_spacing + randomOffset
                placedNodes.append(node)
            }
        }
        nodes = placedNodes
    }
    

    func layoutNodesInSingleRow() {
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


    func layoutNodesRecursive() {
        
        // we start off by placing nodes in single row (this filters out the non visible nodes)
        layoutNodesInSingleRow()
        placeConnections()
        
        nodeTable = [:]
        moduleTable = [:]
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
        var curX: CGFloat = randomOffset
        var curY: CGFloat = randomOffset
        var replaced_nodes: [Node] = []
        let unplaced_nodes: [Bool:[Node]] = Dictionary.init(grouping: nodes, by: { node in
            return node.depth == 0
        })

        // all unplaced_nodes are placed in column 0
        for node in unplaced_nodes[true] ?? [] {
            node.position.x = curX
            node.position.y = curY + randomOffset
            replaced_nodes.append(node)
            curY += node.height + 30
        }
        
        // clear out nodeTable
        for depth in 1...maxDepth {
            nodeTable[depth] = []
        }
        // store nodes in dictionary of columns based on depth
        for node in unplaced_nodes[false] ?? [] {
            nodeTable[node.depth]?.append(node)
        }
        
        // now sort each node in each column according to their row num
        for depth in 1...maxDepth {
            nodeTable[depth] = nodeTable[depth]?.sorted(by: { $0.row_num < $1.row_num })
        }
        
        // now loop through all columns (depth) and each row within each column
        curY = NodeCanvas.row0_y + randomOffset
        curX = randomOffset
        for depth in (1...maxDepth).reversed() {
            curY = NodeCanvas.row0_y + randomOffset
            for node in nodeTable[depth] ?? [] {
                node.position.x = curX                  //CGFloat(column) * (NodeView.nodeWidth + NodeCanvas.column_spacing)
                node.position.y = curY
                curY += node.height + 50 + randomOffset
            }
            if nodeTable[depth]?.isEmpty == false {
                curX += (NodeView.nodeWidth + NodeCanvas.column_spacing) + randomOffset
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
        
        for(_, values) in nodeTable {
            for node in values {
                replaced_nodes.append(node)
            }
        }
        
        nodes = replaced_nodes
        
        
        // remove connections we used for positioning
        edges = []
    }
    
    func scoreLeft(node: Node, depth: Int) -> Set<Node> {
        
        // have we previously laid out this node?
        // if so, we need to adjust depth of all children skipping feedback loops
        ohShit += 1
        if ohShit > 5000 { print("we found a feedback loop - bailing..."); return node.allChildNodes }

        var rowNum: Int = 0

        switch layoutAlgorithm {
        case .recurseOnFeedback:
            if node.depth > 0 && depth > node.depth && !feedbackList.contains(node) {
                if adjustmentRoot == nil {
                    adjustmentRoot = node
                }
                feedbackList.insert(node)
                for input in node.inputs {
                    for port in input.connections {
                        let leftNode = port.parentNode
                        scoreLeft(node: leftNode, depth: depth + 1)
                    }
                }
            }
            if node == adjustmentRoot {
                adjustmentRoot = nil
                feedbackList = []
            }
        case .moveChildNodes:
            if node.depth > 0 && depth > node.depth {
                let depthDiff = depth - node.depth
                for childNode in node.allChildNodes {
                    
                    let targetDepth = childNode.depth + depthDiff
                    childNode.depth = max(childNode.depth, targetDepth)
                    maxDepth = max(maxDepth, childNode.depth)
                }
            }
        default:
            break

        }

        node.depth = max(node.depth, depth)
        maxDepth = max(maxDepth, node.depth)

        for input in node.inputs {
            for port in input.connections {
                let leftNode = port.parentNode
                if !node.allChildNodes.contains(leftNode) {
                    node.allChildNodes.insert(leftNode)
                    leftNode.row_num = rowNum
                    maxNumRows = max(maxNumRows, rowNum)
                    node.allChildNodes = node.allChildNodes.union(scoreLeft(node: leftNode, depth: depth + 1))
                    rowNum += 1
                }
            }
        }
        return node.allChildNodes
    }
    
    
    func scoreNodes(rootNode: Node) {
        
        // node level > 1 are placed nodes - node level == 0 is an unplaced node
        rootNode.allChildNodes = scoreLeft(node: rootNode, depth: 1)
        print("maxDepth = \(maxDepth)")
        print("totalNodes scored = \(nodes.count)")
//        for node in nodes {
//            print("\(node.name)[\(node.mod_idx)]: depth = \(node.depth), num_children = \(node.allChildNodes.count)")
//        }
    }
    
    
    // this method puts all nodes with no inputs in 1st column and completes layout following output->input
    // no recursion, no scoring of node placement, no detection of crossed edges
    // it's bad - but it is dirt simple and it works
    func layoutNodesInputToOutput() {
        
        nodeTable = [:]
        moduleTable = [:]
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

                nodeTable[0] = []
                moduleTable[0] = []
                nodeTable[NodeCanvas.lastColIndex] = []
                moduleTable[NodeCanvas.lastColIndex] = []
                
                let num_modules_no_input = no_input_modules[true]?.count ?? 0
                let num_modules_with_input = no_input_modules[false]?.count ?? 0

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
                        nodeTable[0]?.append(node)
                        curY += (node.height + 50 + randomOffset)
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
                        nodeTable[NodeCanvas.lastColIndex]?.append(node)
                        curY += (node.height + 50 + randomOffset)
                    }

                }
                
                modulesToPlace = no_ouput_modules[false] ?? []
                nodeProcessingState = .arbitraryColumn(column: 1, nextYOffset: NodeCanvas.row0_y)
                
            case .arbitraryColumn(let column, let nextYOffset):
                
                nodeTable[column] = []
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
                        nodeTable[column]?.append(node)
                        curY += (node.height + 50 + randomOffset)
                    }
                }
                modulesToPlace = columnGrouping[false] ?? []
                nodeProcessingState = .arbitraryColumn(column: column + 1, nextYOffset: NodeCanvas.row0_y)
            }
        }
        
        // now move the output col to the last column processed
        let lastCol = nodeTable.keys.count - 1
        
        for node in nodeTable[NodeCanvas.lastColIndex] ?? [] {
            node.position.x = (NodeCanvas.col0_x + (NodeView.nodeWidth + NodeCanvas.column_spacing) * CGFloat(lastCol))
        }

        for (_, values) in nodeTable {
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
            self.edges.append(edge)

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
}
