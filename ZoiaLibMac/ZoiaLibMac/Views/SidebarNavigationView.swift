/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI

struct SidebarNavigationView: View {

    @Binding var showConfirmDelete: Bool
    
    @State private var categoryFiltersExpanded = true
    @State private var libraryFiltersExpanded = true
    @State private var banksExpanded = true
    @State private var banksEnabled = true

    @EnvironmentObject private var model: AppViewModel
    
    var sortByItems: [SortByItems] = SortByItems.allCases
    var orderByItems: [SortOrderItems] = SortOrderItems.allCases

    var body: some View {
        NavigationView {
            List {
                Section("PATCHES") {
                    NavigationLink(tag: NavigationItem.cloud.rawValue, selection: $model.currentSidebarSelection) {
                        PatchListContainer()
                            .navigationTitle("Browse")
                            .navigationSubtitle("patchstorage.com")
                    } label: {
                        Label("Browse", systemImage: "square.grid.2x2")
                    }
                    
                    .help("Browses patchstorage.com for Zoia Patches")
                    NavigationLink(tag: NavigationItem.library.rawValue, selection: $model.currentSidebarSelection) {
                        LocalPatchContainer()
                            .navigationTitle("Library")
                            .navigationSubtitle("Downloaded Patches")
                    } label: {
                        Label("Library", systemImage: "folder")
                    }
                    .help("Download patches in the Browse tab to your own personal library")
                    DisclosureGroup(isExpanded: $banksExpanded, content: {

                        ForEach(model.banks) {
                            bank in
                            BankNavigationLink(bank: bank, showConfirmDelete: $showConfirmDelete)
                        }
                        if let zoiaBank = model.factoryBank[.zoia] {
                            FactoryBankNavigationLink(bank: zoiaBank, showConfirmDelete: $showConfirmDelete)
                        }
                        if let zebuBank = model.factoryBank[.euroburo] {
                            FactoryBankNavigationLink(bank: zebuBank, showConfirmDelete: $showConfirmDelete)
                        }
                        
                    }, label: {
                        BanksSectionHeader(icon: "list.number", title: "Banks", color: .accentColor, addAction: {
                            self.addNewBank()
                        }, isEnabled: $banksEnabled)

                    })
                    .help("Organize your patches into Zoia banks which you can export to you Zoia SD Card or a folder")
                }
                Divider()
                Spacer()
                Section("FILTERS") {
                    categoriesFilterGroup
                    libraryFilterGroup
                }
                Divider()
            }
            .listStyle(SidebarListStyle())
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                    }
                }
            }
            Text("If you see this message, please resize the window to trigger a refresh, as something has gone wrong during initialization.")
                .ignoresSafeArea()
            Text("Select an item in the list to the left to display a detailed view")
                .ignoresSafeArea()
        }
    }
    
    struct FactoryBankNavigationLink: View {
        @ObservedObject var bank: Bank
        @EnvironmentObject private var model: AppViewModel
        @Binding var showConfirmDelete: Bool
        
        var body: some View {
            NavigationLink(tag: bank.name, selection: $model.currentSidebarSelection) {
                BanksListContainer(bank: bank)
                    .navigationTitle(Text("Bank: \(bank.name)", comment: ""))
            } label: {
                HStack {
                    Image(systemName: bank.bankType == .zoia || bank.bankType == .euroburo ? "lock.square" : "person")
                    Text(bank.name)
                    Spacer()
                    if bank.bankType == .user {
                        Image(systemName: "square.and.arrow.down")
                            .opacity(0.3)
                    }
                }
                .padding(bank.isTargetedForDrop ? 2 : 0)
                .background(bank.isTargetedForDrop ? Color.init(red: 0.4, green: 0.4, blue: 0.4) : .clear)
                .cornerRadius(3)
            }
            .contextMenu {
                DuplicateBankButton()
                Divider()
                ExportBankButton()
            }
        }
    }

    struct BankNavigationLink: View {
        
        @ObservedObject var bank: Bank
        @EnvironmentObject private var model: AppViewModel
        @Binding var showConfirmDelete: Bool
        
        var body: some View {
            NavigationLink(tag: bank.name, selection: $model.currentSidebarSelection) {
                BanksListContainer(bank: bank)
                    .navigationTitle(Text("Bank: \(bank.name)", comment: ""))
            } label: {
                HStack {
                    Image(systemName: bank.bankType == .zoia || bank.bankType == .euroburo ? "lock.square" : "person")
                    Text(bank.name)
                    Spacer()
                    if bank.bankType == .user {
                        Image(systemName: "square.and.arrow.down")
                            .opacity(0.3)
                    }
                }
                .padding(bank.isTargetedForDrop ? 2 : 0)
                .background(bank.isTargetedForDrop ? Color.init(red: 0.4, green: 0.4, blue: 0.4) : .clear)
                .cornerRadius(3)
            }

            .help("Drop Patches here from your Library or from .bin files from the Finder")
            .bankDropTarget(bank: bank)
            .contextMenu {
                DuplicateBankButton()
                Divider()
                ExportBankButton()
                Divider()
                DeleteBankButton(showDeleteState: $showConfirmDelete)
            }
        }
    }
    
    func toggleSidebar() {
        NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
    }
    
    private var categoriesFilterGroup: some View {
        DisclosureGroup("Categories", isExpanded: $categoryFiltersExpanded) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("All", isOn: Binding(get: {
                        model.categoryFilters.hidden.isEmpty
                    }, set: {
                        isOn in
                        if isOn {
                            model.categoryFilters.hidden = []
                        } else {
                            model.categoryFilters.hidden = Set(model.allCategories)
                        }
                        model.onListFilteringChange()
                    }))
                    .accentColor(Color.secondary)
                    .foregroundColor(Color.secondary)
                    .padding(.bottom, 5)
                    ForEach(model.allCategories, id: \.self) {
                        category in
                        Toggle(category, isOn: Binding(get: {
                            !model.categoryFilters.hidden.contains(category)
                        }, set: {
                            isOn in
                            if isOn {
                                model.categoryFilters.hidden.remove(category)
                            } else {
                                model.categoryFilters.hidden.insert(category)
                            }
                            model.onListFilteringChange()
                        }))
                    }
                }
                Spacer()
            }
            .padding(.leading, 5)
        }
    }
    
    func addNewBank() {
        model.addNewBank()
    }

    private var libraryFilterGroup: some View {
        DisclosureGroup("Library Status", isExpanded: $libraryFiltersExpanded) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("All", isOn: Binding(get: {
                        model.libraryFilters.hidden.isEmpty
                    }, set: {
                        isOn in
                        if isOn {
                            model.libraryFilters.hidden = []
                        } else {
                            model.libraryFilters.hidden = Set(model.allLibraryFilters)
                        }
                        print(model.libraryFilters.hidden)
                        model.filterPatchListWithLibraryFilters()
                    }))
                    .accentColor(Color.secondary)
                    .foregroundColor(Color.secondary)
                    .padding(.bottom, 5)
                    .disabled(model.currentSidebarSelection != NavigationItem.cloud.rawValue)
                    ForEach(model.allLibraryFilters, id: \.self) {
                        category in
                        Toggle(category, isOn: Binding(get: {
                            !model.libraryFilters.hidden.contains(category)
                        }, set: {
                            isOn in
                            if isOn {
                                model.libraryFilters.hidden.remove(category)
                            } else {
                                model.libraryFilters.hidden.insert(category)
                            }
                            model.filterPatchListWithLibraryFilters()
                        }))
                        .disabled(model.currentSidebarSelection != NavigationItem.cloud.rawValue)
                    }
                }
                Spacer()
            }
            .padding(.leading, 5)
        }
    }
}


struct BanksSectionHeader: View {
    let icon: String
    let title: String
    let color: Color

    let addAction: () -> Void
    @Binding var isEnabled: Bool
    @EnvironmentObject private var model: AppViewModel
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .padding(.leading, 3)
                Text(title)
            }
            Spacer()
            if model.bankLoadingProgress.isFinished {
                Button(action: addAction) {
                    Image(systemName: "plus")
                        .foregroundColor(.secondary)
                }
            } else {
                ProgressView()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct BankItemDropDelegate: DropDelegate {
    
    let bank: Bank
    func handleDropOfFile(fileUrl: URL) {
        
        // TODO: Also handle new .zbundle folder types (used in NodeView)?
        if fileUrl.isDirectory {
            print("user has dropped combo directory onto bank")
            bank.insertComboDirectoryAsPatch(directoryUrl: fileUrl)
        } else {
            let fileName = fileUrl.lastPathComponent
            let (isZoiaFile, _, _) = BankManager.parseZoiaFileName(filename: fileName)
            if isZoiaFile {
                BankManager.insertBinFileAsPatch(bank: bank, fileUrl: fileUrl)
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        if let first = info.itemProviders(for: ["public.file-url"]).first {
            _ = first.loadDataRepresentation(forTypeIdentifier: "public.file-url") {
                data, error in
                if let error = error {
                    print(error)
                } else {
                    if let data = data, let str = NSString(data: data, encoding: 4), let fileUrl = URL(string: str as String) {
                        print("fileURL = \(fileUrl.absoluteString)")
                        self.handleDropOfFile(fileUrl: fileUrl)
                    }
                }
            }
        }
        return true
    }
}

