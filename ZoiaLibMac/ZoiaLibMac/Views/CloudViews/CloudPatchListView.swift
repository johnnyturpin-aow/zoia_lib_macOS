/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI
import Combine

struct PatchListContainer: View {
    
    @EnvironmentObject private var model: AppViewModel
    var sortByItems: [SortByItems] = SortByItems.allCases
    var orderByItems: [SortOrderItems] = SortOrderItems.allCases
	
    let showToolbarHere = false
    
    var body: some View {
        CloudPatchListView()
            .onAppear(perform: model.fetchNextPageIfPossible)
            .searchable(text: $model.searchQuery)
			//.searchable(text: $searchQuery)
            .onSubmit(of: .search) {
                
            }
//			.onChange(of: searchQuery) {
//				searchText in
//				searchTextPublisher.send(searchText)
//			}
//			.onReceive(searchTextPublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main), perform: { debouncedText in
//				print("debounced Search = \(debouncedText)")
//				model.searchQuery = debouncedText
//			})
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

struct CloudPatchListView: View {
    
    @EnvironmentObject private var model: AppViewModel

    var body: some View {
        
        List {
            ForEach(model.sortedWrappedPatchList) { patch in
                NavigationLink(tag: patch.patch.id, selection: $model.selectedBrowsePatchId) {
                    CloudPatchDetailView(patch: patch)
                } label: {
                    CloudPatchRow(patch: patch)
                        .onAppear {
                            if self.model.sortedWrappedPatchList.last?.patch == patch.patch {
                                if !model.libraryFilters.disableFetch {
                                    model.fetchNextPageIfPossible()
                                }
                            }
                        }
                }
                Divider()
            }
        }
    }
}

