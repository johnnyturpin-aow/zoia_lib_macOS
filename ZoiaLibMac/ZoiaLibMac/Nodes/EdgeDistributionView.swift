/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


import SwiftUI

struct EdgeDistributionView: View {
    
    @EnvironmentObject private var model: AppViewModel
    @ObservedObject var nodeCanvas: NodeCanvas
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(nodeCanvas.edges) {
                edge in
                EdgeView(edge: edge, nodeCanvas: nodeCanvas)
                    .stroke(edge.isAudio ? Color("edgeStrokeColor") : Color("Color-15") , lineWidth: edge.isAudio ? 3 : 1)
                    .animation(.linear, value: nodeCanvas.nodeDragChange)
            }
        }
    }
}

