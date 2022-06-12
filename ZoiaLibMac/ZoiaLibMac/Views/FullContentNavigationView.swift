//
//  SidebarNavigationView.swift
//  ZoiaLibMac
//
//  Created by Johnny Turpin on 4/25/22.
//

import SwiftUI


struct FullContentNavigationView: View {
    
    @EnvironmentObject private var model: AppViewModel
//    @State private var selection: NavigationItem? = .info
//    @State private var categoryFiltersExpanded = true
//    @State private var tagFiltersExpanded = true
    
    var body: some View {
        
        DynamicNavigationView(showFilters: true, hasCloud: true)
            .environmentObject(model)
    }
    
    func toggleSidebar() {
        NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
    }
}

struct SidebarNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        FullContentNavigationView()
    }
}
