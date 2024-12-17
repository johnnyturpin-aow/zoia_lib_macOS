/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI

struct MigratedSidebarNavigationView: View {

	@Binding var showConfirmDelete: Bool
	
	@State private var categoryFiltersExpanded = true
	@State private var libraryFiltersExpanded = true
	@State private var banksExpanded = true
	@State private var banksEnabled = true

	@EnvironmentObject private var model: AppViewModel
	
	var sortByItems: [SortByItems] = SortByItems.allCases
	var orderByItems: [SortOrderItems] = SortOrderItems.allCases

	var body: some View {
		if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, visionOS 1, *) {
			NavigationSplitView {
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
								let _ = print("Sidebar Bank = \(bank.name)")
								BankNavigationLink(bank: bank, showConfirmDelete: $showConfirmDelete)

							}
							if let zoiaBank = model.factoryBank[.zoia] {
								let _ = print("ZOIA FactoryBank = \(zoiaBank.name)")
								FactoryBankNavigationLink(bank: zoiaBank, showConfirmDelete: $showConfirmDelete)
							}
							if let zebuBank = model.factoryBank[.euroburo] {
								let _ = print("zebuBank FactoryBank = \(zebuBank.name)")
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
			} content: {
				
			} detail: {
				
			}
		}
		else {
			Text("Use NavigationView instead")
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