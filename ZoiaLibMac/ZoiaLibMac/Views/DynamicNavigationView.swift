//
//  DynamicNavigationView.swift
//  ZoiaLibMac
//
//  Created by Johnny Turpin on 4/26/22.
//

import SwiftUI

struct DynamicNavigationView: View {
    
    var showFilters = true
    var splitViewType: SplitViewType = .double
    var hasCloud = true
    
    @State private var selection: NavigationItem? = .info
    @State private var categoryFiltersExpanded = true
    @EnvironmentObject private var model: AppViewModel
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(tag: NavigationItem.info, selection: $selection) {
                    InfoView()
                } label: {
                    Label("Info", systemImage: "info.circle")
                }
                Section("Patches") {

                    if hasCloud {
                        NavigationLink(tag: NavigationItem.cloud, selection: $selection) {
                            PatchListContainer(viewModel: model.cloudData)
                        } label: {
                            Label("Cloud", systemImage: "square.grid.2x2")
                        }
                    }

                    NavigationLink(tag: NavigationItem.library, selection: $selection) {
                        PatchListContainer(viewModel: model.cloudData)
                    } label: {
                        Label("Manage", systemImage: "folder")
                    }
                    NavigationLink(tag: NavigationItem.export, selection: $selection) {
                        PatchListContainer(viewModel: model.cloudData)
                    } label: {
                        Label("Export", systemImage: "sdcard")
                    }
                }
                if showFilters {
                    Section("Filters") {
                        DisclosureGroup("Categories", isExpanded: $categoryFiltersExpanded) {
                            ForEach($model.cloudData.categoryToggleList, id: \.self) {
                                $toggle in
                                Toggle(toggle.data.name ?? "", isOn: $toggle.isOn )
                            }
                        }
                    }
                }

            }
            .listStyle(SidebarListStyle())
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                    }
                }
            }
            Text("Select a menu item")
            if splitViewType == .triple {
                Text("Triple")
            }
        }
        .onChange(of: selection) {
            value in
            print("new selection = \(selection ?? .info)")
            model.updateAppConfig(selection: selection)
        }
    }
    
    func toggleSidebar() {
        NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
    }
}

struct DynamicNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicNavigationView()
    }
}
