/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI

struct BanksListContainer: View {
    
    let bank: Bank
    
    @EnvironmentObject private var model: AppViewModel
    var body: some View {
        if bank.bankType == .zoia || bank.bankType == .euroburo {
            FactoryListView(bank: bank)
        } else {
            BanksListView(bank: bank)
        }
    }
}

struct FactoryListView: View {
    
    @EnvironmentObject private var model: AppViewModel
    @ObservedObject var bank: Bank
    
    
    init(bank: Bank) {
        self.bank = bank
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            BankHeaderView(bank: bank)
                .frame(height: 150)
            List {

                ForEach(bank.orderedPatches.indices) {
                    i in
                    let patch = bank.orderedPatches[i]
                    NavigationLink(tag: i.description, selection: $model.selectedFactoryPatchId) {
                        BankPatchDetailView()
                    } label: {
                        BankRowView(patch: patch, index: i)
                    }
                    .onChange(of: model.selectedFactoryPatchId) {
                        newValue in
                        model.onSelectedFactoryPatchDidChange(bankType: bank.bankType)
                    }
                }

            }
            .padding(0)
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }
}

struct BanksListView: View {
    
    @EnvironmentObject private var model: AppViewModel
    @ObservedObject var bank: Bank
    @State private var isDropping: Bool = false
    @State private var destinationIndex: Int = 0
    @State private var sourceIndex: Int = 0
    
    
    init(bank: Bank) {
        self.bank = bank
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            BankHeaderView(bank: bank)
                .frame(height: 150)
                .bankDropTarget(bank: bank)
            List {

                ForEach(bank.orderedPatches.indices) {
                    i in
                    let patch = bank.orderedPatches[i]
                    NavigationLink(tag: i.description, selection: $model.selectedBinaryPatchId) {
                        BankPatchDetailView()
                    } label: {
                        BankRowView(patch: patch, index: i)
                    }
                    .contextMenu {
                        Button {
                            bank.deletePatch(at: i)
                        } label: {
                            Text("Delete patch")
                        }
                        Button {
                            bank.replacePatchWithBlankPatch(at: i)
                        } label: {
                            Text("Replace patch with Blank patch")
                        }
                    }
                }
                .onMove(perform: move)
                .onDelete(perform: deleteRows)

            }
            .padding(0)
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .bankDropTarget(bank: bank)
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {

        if bank.name.lowercased() == "factory" {
            return
        }
        // TODO: modify to support multiple source patches / support full IndexSet
        if let srcIndex = source.first {
            bank.movePatch(from: srcIndex, to:  destination)
        }
    }
    
    func deleteRows(at offsets: IndexSet) {
        if bank.name.lowercased() == "factory" {
            return
        }
        
        
        for index in offsets {
            if bank.orderedPatches.item(at: index)?.patchType == .empty { continue }
            bank.deletePatch(at: index)
            model.selectedBinaryPatchId = nil
        }
    }
}

