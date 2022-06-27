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
}


enum LayoutAlgorithm: String, Identifiable {
    case moveChildNodes = "Mode 1"
    case investigation1 = "Mode 2"
    case singleRow = "Single Row"
    
    var id: String { return rawValue }
    
    
    var description: String {
        switch self {
        case .moveChildNodes:
            return "Mode 1"
        case .investigation1:
            return "Mode 2"
        case .singleRow:
            return "Single Row"
        }
    }
}

// 15 = PushButton
// 16 = Keyboard
// 45 = Value
// 56 = UI Button
// 81 = Pixel
enum HidableModules: Int, Identifiable, CaseIterable {
    case pushButton = 15
    case keyboard = 16
    case valueInput = 45
    case uiButton = 56
    case pixel = 81
    
    var id: Int { rawValue }
    
    var description: String {
        switch self {
        case .keyboard: return "Keyboard"
        case .pixel: return "Pixel"
        case .pushButton: return "Push Button"
        case .uiButton: return "UI Button"
        case .valueInput: return "Value"
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
    
    func open(url: URL, appModel: AppViewModel) {
        self.appModel = appModel
        
        ZoiaBundle.openZoiaBundle(filePath: url) {
            observablePatch in
            
            self.bundlePath = url
            self.patch = observablePatch
            
            if let patchName = self.patch?.parsedPatchFile?.name {
                self.appModel?.addLayoutChangeListener(nodeCanvasId: patchName, handler: {
                    algorithm in
                    
                    print("algorithm changed")
                    if algorithm != self.layoutAlgorithm {
                        self.layoutAlgorithm = algorithm
                    }
                })
            }
            
            self.loadNodes {
                _ in
                //self.placeNodes()
                //self.placeConnections()
                self.placeNodesOrdered(useSavedNodes: true)
            }
        }
    }

    
    static let row0_y: CGFloat = 0
    static let col0_x: CGFloat = 0
    static let col5_x: CGFloat = (300 + 30) * 6
    
    static let lastColIndex: Int = 5000
    static let column_spacing: CGFloat = 300
    // Int is the column - the array of node are the nodes down that column
    @Published var selection: SelectionHandler
    @Published var zoomScale: CGFloat = 0.9
    @Published var portalPosition: CGPoint = .zero
    @Published var dragOffset: CGSize = .zero
    @Published var isDraggingNode: Bool = false
    @Published var isDraggingCanvas: Bool = false
    
    @Published var dragChange: Int = 0
    @Published var nodeDragChange: Int = 0
    @Published var connectionStyle: PipeType = .curved {
        didSet {
            self.edges = []
            self.placeConnections()
        }
    }
    
    var layoutAlgorithm: LayoutAlgorithm = .moveChildNodes {
        didSet {
            if self.patch != nil {
                self.placeNodesOrdered(useSavedNodes: false)
            }
        }
    }

    var nodeProcessingState: NodeProcessingState = .initialColumn(nextYOffset: NodeCanvas.row0_y)
    var modulesToPlace: [ParsedBinaryPatch.Module] = []
    var nodeTable: [Int:[Node]] = [:]
    var moduleTable: [Int: [ParsedBinaryPatch.Module]] = [:]
    var modulesInCurrentPass: [ParsedBinaryPatch.Module] = []
    
    
    var hiddenModules: Set<HidableModules> = []

    
    // v2 node layout algorithm
    var maxDepth: Int = 0
    var maxNumRows: Int = 0
    var ohShit: Int = 0
    
    let dontSave = true
    
    var nodeListSaveTimer: Timer?

    // our list of saved node positions
    var savedNodes: NodeCanvasCodable?
    
    var adjustmentRoot: Node?
    var feedbackList: Set<Node> = []
    
    enum NodeProcessingState {
        case initialColumn(nextYOffset: CGFloat)
        case arbitraryColumn(column: Int, nextYOffset: CGFloat)
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
        
        nodeListSaveTimer?.invalidate()
        nodeListSaveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {
            [weak self] timer in
            
            if self?.dontSave == false  { self?.saveNodes() }
            
            self?.nodeListSaveTimer = nil
        }
    }
    
    func nodeWithID(_ id: NodeID) -> Node? {
        return nodes.first(where: { $0.id == id })
    }
    
    
    func saveNodes() {
        guard let bundleUrl = self.bundlePath else { return }
        let listOfNodes: [NodeCodable] = nodes.map {
            node in
            let canvasPos = CanvasPosition(x: node.position.x, y: node.position.y)
            let nodeColor = CodableColor(color: node.color)
            let codableNode = NodeCodable(mod_idx: node.mod_idx, position: canvasPos, color: nodeColor)
            return codableNode
        }
        let nodeList = NodeCanvasCodable(nodeList: listOfNodes, connectionStyle: self.connectionStyle)
        
        ZoiaBundle.saveNodeList(bundleUrl: bundleUrl, nodeList: nodeList) {
            print("nodes saved")
        }
    }
    
    func loadNodes(completion: @escaping (Bool)->Void) {
        guard let bundleUrl = self.bundlePath else { return }
        ZoiaBundle.loadNodeList(bundleUrl: bundleUrl) {
            loadedNodeCanvas in
            
            DispatchQueue.main.async {
                guard loadedNodeCanvas != nil else { completion(false); return }
                self.savedNodes = loadedNodeCanvas
                self.connectionStyle = loadedNodeCanvas?.connectionStyle ?? .curved
                completion(true)
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
    
    func placeConnections() {
        
        clearConnections()
        for blockConnection in patch?.parsedPatchFile?.blockConnections ?? [] {
            
            guard let srcNode = self.nodes.first(where: { $0.mod_idx == blockConnection.source_module_idx }) else { continue }
            guard let dstNode = self.nodes.first(where: { $0.mod_idx == blockConnection.dest_module_idx }) else { continue }
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
    
    
    func scoreLeft(node: Node, depth: Int) -> Set<Node> {
        
        // have we previously laid out this node?
        // if so, we need to adjust depth of all children skipping feedback loops
        ohShit += 1
        if ohShit > 5000 { print("we found a feedback loop - bailing..."); return node.allChildNodes }

        var rowNum: Int = 0
        
        
        switch layoutAlgorithm {
            
        case .investigation1:
            if node.depth > 0 && depth > node.depth && !feedbackList.contains(node) {
                
                //node.depth = max(node.depth, depth)
                //maxDepth = max(maxDepth, node.depth)
                
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
            
        case .moveChildNodes:
            if node.depth > 0 && depth > node.depth {
                let depthDiff = depth - node.depth
                for childNode in node.allChildNodes {
                    
                    let targetDepth = childNode.depth + depthDiff
                    childNode.depth = max(childNode.depth, targetDepth)
                    maxDepth = max(maxDepth, childNode.depth)
                }
            }
        case .singleRow:
            break
            
        default:
            break

        }
        
        if node == adjustmentRoot {
            adjustmentRoot = nil
            feedbackList = []
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
        for node in nodes {
            print("\(node.name)[\(node.mod_idx)]: depth = \(node.depth), num_children = \(node.allChildNodes.count)")
        }
    }
    
    // if no save, will simply place nodes in a single row
    func placeNodesFromSave() {
        
        var placedNodes: [Node] = []
        var curX: CGFloat = 0
        modulesToPlace = patch?.parsedPatchFile?.modules ?? []
        for module in modulesToPlace {
            if !self.hiddenModules.contains(where: { $0.rawValue == module.ref_mod_idx }) {
                let savedNode = self.savedNodes?.nodeList.first(where: { $0.mod_idx == module.number })
                let nodePos = CGPoint(x: savedNode?.position.x ?? curX, y: savedNode?.position.y ?? 0)
                let node = Node(name: module.name ?? "", mod_idx: module.number, pos: nodePos)
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
    
    
    func placeNodesSingleRow() {
        var placedNodes: [Node] = []
        var curX: CGFloat = 0
        modulesToPlace = patch?.parsedPatchFile?.modules ?? []
        for module in modulesToPlace {
            
            let nodePos = CGPoint(x: curX, y: 0)
            let node = Node(name: module.name ?? "", mod_idx: module.number, pos: nodePos)
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
        nodes = placedNodes
    }
    
    func updateFilteredNodes() {
        placeNodesOrdered(useSavedNodes: true)
    }

    func placeNodesOrdered(useSavedNodes: Bool) {
        
        nodes = []
        edges = []
        
        if useSavedNodes {
            placeNodesFromSave()
            
        } else {
            placeNodesSingleRow()
        }
        
        placeConnections()
        
        // if we have loaded saved positions and we are not changing a layout algorithm, then we are done

        if useSavedNodes && self.savedNodes != nil {
            placeConnections()
            return
        }
        
        if layoutAlgorithm == .singleRow { return }
        
        // step 1 - find the output module
        
        let output_node = nodes.first(where: { patch?.parsedPatchFile?.modules.item(at: $0.mod_idx)?.ref_mod_idx == 2 }) ??
        nodes.first(where: { patch?.parsedPatchFile?.modules.item(at: $0.mod_idx)?.ref_mod_idx == 95 }) ??
        nodes.first(where: { patch?.parsedPatchFile?.modules.item(at: $0.mod_idx)?.ref_mod_idx == 96 }) ??
        nodes.first(where: { patch?.parsedPatchFile?.modules.item(at: $0.mod_idx)?.ref_mod_idx == 60 })
        
        
        guard let output_node = output_node else { return }
        

        // step 2 - score nodes - calculates each nodes depth as well as num of rows per column
        scoreNodes(rootNode: output_node)

        // step 3 - place all unconnected nodes
        var curX: CGFloat = 0
        var curY: CGFloat = 0
        var replaced_nodes: [Node] = []
        let unplaced_nodes: [Bool:[Node]] = Dictionary.init(grouping: nodes, by: { node in
            return node.depth == 0
        })

        // all unplaced_nodes are placed in column 0
        for node in unplaced_nodes[true] ?? [] {
            node.position.x = curX
            node.position.y = curY
            replaced_nodes.append(node)
            curX += NodeView.nodeWidth + NodeCanvas.column_spacing
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
        curY = 300
        curX = 0
        for depth in (1...maxDepth).reversed() {
            curY = 300
            //let column = maxDepth - depth
            for node in nodeTable[depth] ?? [] {
                node.position.x = curX //CGFloat(column) * (NodeView.nodeWidth + NodeCanvas.column_spacing)
                node.position.y = curY
                curY += node.height + 50
            }
            if nodeTable[depth]?.isEmpty == false {
                curX += (NodeView.nodeWidth + NodeCanvas.column_spacing)
            }
        }
        
        for(_, values) in nodeTable {
            for node in values {
                replaced_nodes.append(node)
            }
        }
        
        nodes = replaced_nodes

        placeConnections()
    }
    
    
    // this is a first attempt at a dirt simple Node placement algorithm... no recursion, no scoring of node placement, no detection of crossed edges
    // it's bad - but it is dirt simple and it works
    func placeNodesV1() {
        
        modulesToPlace = patch?.parsedPatchFile?.modules ?? []
//        // decided to do this during module import - helps Detail View buttons
//        for var module in modulesToPlace {
//            module.name = module.name ?? EmpressReference.shared.moduleList[module.ref_mod_idx.description]?.name ?? ""
//        }
        
        var we_got_a_problem: Int = 0
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
                
                var curY: CGFloat = nextYOffset
                for module in no_input_modules[true] ?? [] {
                    moduleTable[0]?.append(module)
                    
                    let savedNode = self.savedNodes?.nodeList.first(where: { $0.mod_idx == module.number })
                    let nodePos = CGPoint(x: savedNode?.position.x ?? NodeCanvas.col0_x, y: savedNode?.position.y ?? curY)
                    //let node = Node(name: module.name ?? "", mod_idx: module.number, pos: CGPoint(x: NodeCanvas.col0_x, y: curY))
                    let node = Node(name: module.name ?? "", mod_idx: module.number, pos: nodePos)
                    node.colorId = module.color
                    for block in module.input_blocks {
                        node.createAndAppendPort(portType: .input, name: block.keys.first ?? "")
                    }
                    for block in module.output_blocks {
                        node.createAndAppendPort(portType: .output, name: block.keys.first ?? "")
                    }
                    nodeTable[0]?.append(node)
                    curY += (node.height + 30)
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
                    moduleTable[NodeCanvas.lastColIndex]?.append(module)
                    let savedNode = self.savedNodes?.nodeList.first(where: { $0.mod_idx == module.number })
                    let nodePos = CGPoint(x: savedNode?.position.x ?? NodeCanvas.col5_x, y: savedNode?.position.y ?? curY)
                    let node = Node(name: module.name ?? "", mod_idx: module.number, pos: nodePos)
                    node.colorId = module.color
                    for block in module.input_blocks {
                        node.createAndAppendPort(portType: .input, name: block.keys.first ?? "")
                    }
                    for block in module.output_blocks {
                        node.createAndAppendPort(portType: .output, name: block.keys.first ?? "")
                    }
                    nodeTable[NodeCanvas.lastColIndex]?.append(node)
                    curY += (node.height + 30)
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
                    
                    moduleTable[column]?.append(module)
                    let alg_x = NodeCanvas.col0_x + (NodeView.nodeWidth + NodeCanvas.column_spacing) * CGFloat(column)
                    let alg_y = curY
                    let savedNode = self.savedNodes?.nodeList.first(where: { $0.mod_idx == module.number })
                    let nodePos = CGPoint(x: savedNode?.position.x ?? alg_x, y: savedNode?.position.y ?? alg_y)
                    let node = Node(name: module.name ?? "", mod_idx: module.number, pos: nodePos)
                    node.colorId = module.color
                    for block in module.input_blocks {
                        node.createAndAppendPort(portType: .input, name: block.keys.first ?? "")
                    }
                    for block in module.output_blocks {
                        node.createAndAppendPort(portType: .output, name: block.keys.first ?? "")
                    }
                    nodeTable[column]?.append(node)
                    curY += (node.height + 30)
                }
                modulesToPlace = columnGrouping[false] ?? []
                nodeProcessingState = .arbitraryColumn(column: column + 1, nextYOffset: NodeCanvas.row0_y)
            }
            
            we_got_a_problem += 1
            if we_got_a_problem > 200 {
                modulesToPlace = []
            }
        }
        
        // now move the output col to the last column processed
        let lastCol = nodeTable.keys.count - 1
        
        for node in nodeTable[NodeCanvas.lastColIndex] ?? [] {
            let savedNode = self.savedNodes?.nodeList.first(where: { $0.mod_idx == node.mod_idx })
            node.position.x = savedNode?.position.x ?? (NodeCanvas.col0_x + (NodeView.nodeWidth + NodeCanvas.column_spacing) * CGFloat(lastCol))
        }

        for (_, values) in nodeTable {
            for node in values {
                nodes.append(node)
            }
        }
    }
}
