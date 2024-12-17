/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


import SwiftUI



enum PipeType: String, Identifiable, Codable {
	
	case curved = "Curved"
	case right_angle = "Orthogonal"
	case straight = "Straight"
	
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
		self.portalPosition = CanvasPosition(x: nodeCanvas.scrollOffset.x, y: nodeCanvas.scrollOffset.y)
	}
}


enum LayoutAlgorithm: String, Codable, Identifiable {
	
	case singleRow = "Single Row"
	case compact = "Compact"
	case simpleRecursive = "Output to Input"
	case splitAudioCV = "Split Audio / CV"

	var id: String { return rawValue }
	var image: String {
		switch self {
		case .singleRow:
			return "minus.square"
		case .compact:
			return "square.grid.3x3.square"
		case .simpleRecursive:
			return "1.square"
//        case .moveChildNodes:
//            return "2.square"
		case .splitAudioCV:
			return "square.grid.3x1.below.line.grid.1x2"
		}
	}
	
}


enum HidableModules: Int, Codable, Identifiable, CaseIterable {
	case pushButton = 15
	case keyboard = 16
	case valueInput = 45
	case uiButton = 56
	case pixel = 81
	case audioConnections = 9999
	case cvConnections = 8888
	
	var id: Int { rawValue }
	
	var description: String {
		switch self {
		case .keyboard: return "Keyboard"
		case .pixel: return "Pixel"
		case .pushButton: return "Push Button"
		case .uiButton: return "UI Button"
		case .valueInput: return "Value"
		case .audioConnections: return "Audio Connection"
		case .cvConnections: return "CV Connection"
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
		case .audioConnections:
			return "waveform"
		case .cvConnections:
			return "point.topleft.down.curvedto.point.bottomright.up.fill"
		}
	}
}

enum SplitModeLayoutState {
	case audio
	case cv
	case unplaced
}


