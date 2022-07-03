/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


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

