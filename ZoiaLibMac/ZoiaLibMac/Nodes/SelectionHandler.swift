// GNU GENERAL PUBLIC LICENSE
// Version 3, 29 June 2007
//
// Copyright (c) 2022 Johnny Turpin (github.com/johnnyturpin-aow)

// some of the Node Editor code loosely inspired by RayWenderlich MindMap Tutorial
// https://www.raywenderlich.com/7705231-creating-a-mind-map-ui-in-swiftui


/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import CoreGraphics

struct DragInfo {
    var id: UUID
    var originalPosition: CGPoint
}

class SelectionHandler: ObservableObject {
    
    @Published var draggingNodes: [DragInfo] = []
    @Published private(set) var selectedNodeIDs: [NodeID] = []
    
    func selectNode(_ node: Node) {
        print("selecting node with ID = \(node.mod_idx)")
        selectedNodeIDs.append(node.id)
    }
    
    func isNodeSelected(_ node: Node) -> Bool {
        return selectedNodeIDs.contains(node.id)
    }
    
    func deselectAllNodes() {
        selectedNodeIDs = []
    }
    
    func deselectNode(_ node: Node) {
        selectedNodeIDs = selectedNodeIDs.filter({ $0 != node.id })
    }
    
    func selectedNodes(in canvas: NodeCanvas) -> [Node] {
        return selectedNodeIDs.compactMap { canvas.nodeWithID($0) }
    }

    func onlySelectedNode(in canvas: NodeCanvas) -> Node? {
        let selectedNodes = self.selectedNodes(in: canvas)
        if selectedNodes.count == 1 {
            return selectedNodes.first
        }
        return nil
    }
    
    func startDragging(_ canvas: NodeCanvas) {
        draggingNodes = selectedNodes(in: canvas)
            .map { DragInfo(id: $0.id, originalPosition: $0.position) }
    }
   
    func stopDragging(_ canvas: NodeCanvas) {
        draggingNodes = []
    }
}


