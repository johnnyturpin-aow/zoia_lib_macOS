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


class NodeCanvas: ObservableObject {
    
    // these are all the displayed nodes and edges
    @Published var nodes: [Node] = []
    @Published var edges: [Edge] = []
    
    @Published var patch: ObservableBinaryPatch?
    var bundlePath: URL?
    
    init() {
        selection = SelectionHandler()
    }
    
    func open(url: URL, appModel: AppViewModel) {
        ZoiaBundle.openZoiaBundle(filePath: url) {
            observablePatch in
            
            self.bundlePath = url
            self.patch = observablePatch
            self.loadNodes {
                _ in
                self.placeNodes()
                self.placeConnections()
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
    @Published var connectionStyle: PipeType = .right_angle {
        didSet {
            self.edges = []
            self.placeConnections()
        }
    }
    
    var numPlacedNodes = 0
    var nodeProcessingState: NodeProcessingState = .initialColumn(nextYOffset: NodeCanvas.row0_y)
    var modulesToPlace: [ParsedBinaryPatch.Module] = []
    var nodeTable: [Int:[Node]] = [:]
    var moduleTable: [Int: [ParsedBinaryPatch.Module]] = [:]
    var modulesInCurrentPass: [ParsedBinaryPatch.Module] = []
    
    
    var nodeListSaveTimer: Timer?

    // our list of saved node positions
    var nodeList: NodeCanvasCodable?
    
    enum NodeProcessingState {
        case initialColumn(nextYOffset: CGFloat)
        case arbitraryColumn(column: Int, nextYOffset: CGFloat)
    }
    
    func positionNode(_ node: Node, position: CGPoint) {
        node.position = position
        
        for edge in edges {
            if edge.startConnection.node == node {
                edge.calculatePos()
            }
            if edge.endConnection.node == node {
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
            
            self?.saveNodes()
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
                self.nodeList = loadedNodeCanvas
                self.connectionStyle = loadedNodeCanvas?.connectionStyle ?? .curved
                completion(true)
            }
        }
    }
    
    func placeConnections() {
        
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
            let edge = Edge(start: srcConnection, end: endConnection, strength: 100)
            self.edges.append(edge)
        }
    }
    
    
    // this is a first attempt at a dirt simple Node placement algorithm... no recursion, no scoring of node placement, no detection of crossed edges
    // it's bad - but it is dirt simple and it works
    func placeNodes() {
        
        modulesToPlace = patch?.parsedPatchFile?.modules ?? []
        for var module in modulesToPlace {
            module.name = module.name ?? EmpressReference.shared.moduleList[module.ref_mod_idx.description]?.name ?? ""
        }
        
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
                    
                    let savedNode = self.nodeList?.nodeList.first(where: { $0.mod_idx == module.number })
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
                    let savedNode = self.nodeList?.nodeList.first(where: { $0.mod_idx == module.number })
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
                    let savedNode = self.nodeList?.nodeList.first(where: { $0.mod_idx == module.number })
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
            let savedNode = self.nodeList?.nodeList.first(where: { $0.mod_idx == node.mod_idx })
            node.position.x = savedNode?.position.x ?? (NodeCanvas.col0_x + (NodeView.nodeWidth + NodeCanvas.column_spacing) * CGFloat(lastCol))
        }

        for (_, values) in nodeTable {
            for node in values {
                nodes.append(node)
            }
        }
    }
}

