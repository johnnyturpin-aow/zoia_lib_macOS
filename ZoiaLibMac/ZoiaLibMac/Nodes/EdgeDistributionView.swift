// GNU GENERAL PUBLIC LICENSE
//   Version 3, 29 June 2007
//
// Copyright (c) 2022 Johnny Turpin (github.com/johnnyturpin-aow)

import SwiftUI

struct EdgeDistributionView: View {
    
    @EnvironmentObject private var model: AppViewModel
    @ObservedObject var nodeCanvas: NodeCanvas
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(nodeCanvas.edges) {
                edge in
                EdgeView(edge: edge, nodeCanvas: nodeCanvas)
                    .stroke(Color("edgeStrokeColor"), lineWidth: 2)
                    .animation(.linear, value: nodeCanvas.nodeDragChange)
            }
        }
    }
}

