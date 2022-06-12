//
//  MapView.swift
//  ZLIB
//
//  Created by Johnny Turpin on 6/2/22.
//

import SwiftUI

struct DistributionView: View {
    
    
    @ObservedObject var nodeCanvas: NodeCanvas
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            EdgeDistributionView(nodeCanvas: nodeCanvas)
            NodeDistributionView(nodeCanvas: nodeCanvas)
        }
    }
}

