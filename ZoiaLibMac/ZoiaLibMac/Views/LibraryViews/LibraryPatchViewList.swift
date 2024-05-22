/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI


struct LocalPatchContainer: View {
    @EnvironmentObject private var model: AppViewModel
    var sortByItems: [SortByItems] = SortByItems.allCases
    var orderByItems: [SortOrderItems] = SortOrderItems.allCases
    
    var body: some View {
        LibraryPatchViewList()
            .searchable(text: $model.searchQuery)
            .onSubmit(of: .search) {
                print("searching for: \($model.searchQuery)")
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    if model.tagFilters.count > 0 {
                        Text("Tags:")
                    }
                    ForEach(model.tagFilters, id: \.self) { tag in
                        Button(tag.name ?? "") {
                            model.removeTagFilter(tag: tag)
                        }
                        .foregroundColor(PatchStorage.colorForTag(tagName: tag.name))
                        .font(.system(size: 10, weight: .regular))
                        .help("Click to remove from filter list")
                    }
                    if model.tagFilters.count > 0 {
                        Button(action: {
                            model.clearTagFilters()
                        }
                        , label: {
                            Image(systemName: "x.square")
                        }
                        )
                        .help("Remove all tag filters")
                    }

                    Spacer()
                }
                ToolbarItemGroup(placement: .automatic) {
                    if model.tagFilters.isEmpty {
                        Text("|")
                            .foregroundColor(Color.init(red: 0, green: 0, blue: 0, opacity: 0.2))
                            .hidden()
                    } else {
                        Text("|")
                            .foregroundColor(Color.init(red: 0, green: 0, blue: 0, opacity: 0.2))
                    }

                }
                
                ToolbarItemGroup(placement: .automatic) {
                    Text("Sort By:")
                    Picker("Sort By:", selection: $model.sortBySelection ) {
                        ForEach(sortByItems, id: \.self) {
                            Text($0.description)
                        }
                    }
                    .pickerStyle(.menu)
                    .help("Sort By")

                    Picker("Order:", selection: $model.orderSelection ) {
                        ForEach(orderByItems, id: \.self) {
                            Text($0.description)
                        }
                    }
                    .pickerStyle(.menu)
                    .help("Order By")
                    
                    Spacer()
                }
            }
    }
}

struct LibraryPatchViewList: View {
    
    @EnvironmentObject private var model: AppViewModel
    @State var showConfirmPatchDelete: Bool = false
    @State var selectedItem: Int?
    
    var body: some View {

        List(selection: $selectedItem) {
            ForEach(model.sortedLocalPatchList) {
                combo in
                NavigationLink(tag: combo.patchJson.id, selection: $model.selectedLocalPatchId) {
                    LibraryPatchDetailView(patch: combo)
                } label: {
                    LibraryPatchRow(patch: combo, isSelected: false)
                }
				if #unavailable(macOS 13)  {
					Divider()
				}
            }
            .onDelete(perform: deleteRows )
            .alert("Confirm Delete", isPresented: $showConfirmPatchDelete, actions: {
                Button(role: .destructive) {
                    model.deletePatch(patch: model.selectedPatchForDelete)
                } label: {
                    Text("Delete")
                }
            }, message: {
                Text("Are your sure your would like to delete: \(model.selectedPatchForDelete?.patchJson.title ?? "")?")
            })
        }
        .onDeleteCommand(perform: {
            if let patchToDelete = model.sortedLocalPatchList.first(where: { $0.patchJson.id == selectedItem }) {
                model.selectedPatchForDelete = patchToDelete
                showConfirmPatchDelete = true
            }
        })
    }
    
    func deleteRows(at offsets: IndexSet) {
        if let firstIndex = offsets.first {
            model.deletePatch(patch: model.sortedLocalPatchList.item(at: firstIndex)) {
                didSucceed in
            }
        }
    }
}
