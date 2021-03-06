/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


import SwiftUI

struct NodeDistributionView: View {
    
    @EnvironmentObject private var model: AppViewModel
    @ObservedObject var nodeCanvas: NodeCanvas
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(nodeCanvas.nodes) {
                node in
                NodeView(node: node, nodeCanvas: nodeCanvas)
                    .padding(0)
                    .offset(x: node.position.x, y: node.position.y)
                    .animation(.linear, value: nodeCanvas.nodeDragChange)
            }
        }
    }
}

