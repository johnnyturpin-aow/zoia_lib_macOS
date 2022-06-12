/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var model: AppViewModel
    @Binding var showConfirmDelete: Bool
    
    var body: some View {
        SidebarNavigationView(showConfirmDelete: $showConfirmDelete)
    }
}


