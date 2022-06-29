/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI



struct NodeViewCommands: Commands {
    
    @Binding var layoutAlgorithm: LayoutAlgorithm
    
    var body: some Commands {
        CommandMenu(Text("Layout")) {
            Picker(selection: $layoutAlgorithm, label: Text("Layout Algorithm")) {
                Text(LayoutAlgorithm.singleRow.rawValue).tag(LayoutAlgorithm.singleRow)
                Text(LayoutAlgorithm.simple.rawValue).tag(LayoutAlgorithm.simple)
                Text(LayoutAlgorithm.simpleRecursive.rawValue).tag(LayoutAlgorithm.simpleRecursive)
                Text(LayoutAlgorithm.moveChildNodes.rawValue).tag(LayoutAlgorithm.moveChildNodes)
                Text(LayoutAlgorithm.recurseOnFeedback.rawValue).tag(LayoutAlgorithm.recurseOnFeedback)
            }
        }
    }
}


struct BankCommands: Commands {
    
    
    @Binding var showConfirmDelete: Bool
    let model: AppViewModel
    @Binding var customScheme: AppearanceOptions

    var body: some Commands {
        
        CommandGroup(before: .toolbar) {
            Picker(selection: $customScheme, label: Text("Color Scheme")) {
                Text(AppearanceOptions.System.rawValue).tag(AppearanceOptions.System)
                Text(AppearanceOptions.Light.rawValue).tag(AppearanceOptions.Light)
                Text(AppearanceOptions.Dark.rawValue).tag(AppearanceOptions.Dark)
            }

        }

        CommandMenu(Text("Banks")) {
            NewBankButton()
                .environmentObject(model)
            Divider()
            DuplicateBankButton()
                .environmentObject(model)
                .keyboardShortcut("D", modifiers: [.command])
            Divider()
            ExportBankButton()
                .environmentObject(model)
            Divider()
            DeleteBankButton(showDeleteState: $showConfirmDelete)
            .environmentObject(model)
        }
    }
}


struct DuplicateBankButton: View {
    
    @EnvironmentObject private var model: AppViewModel

    var body: some View {
        Button {
            model.duplicateBank(bank: model.selectedBank) {
                didSucceed in
                let alerter = Alerter()
                alerter.alert = Alert(title: Text(didSucceed ? "Bank successfuly duplicated" : "Duplication failed"))
                model.alerter = alerter
            }
        } label: {
            Text("Duplicate")
        }
        .disabled(model.selectedBank == nil)
    }
}


struct NewBankButton: View {
    @EnvironmentObject private var model: AppViewModel
    var body: some View {
        Button("New Bank") {
            model.addNewBank()
        }
    }
}


struct DeleteBankButton: View {
    @Binding var showDeleteState : Bool
    @EnvironmentObject private var model: AppViewModel
    var body: some View {
        Button {
            self.showDeleteState = true
        } label: {
            Label("Delete from Library", systemImage: "exclamationmark.circle")
        }
        .disabled(model.selectedBank == nil)
    }
}

struct ExportBankButton: View {

    @EnvironmentObject private var model: AppViewModel
    
    var body: some View {
        Button {
            handleExportOfBank(bank: model.selectedBank) {
                didSucceed in
                let alerter = Alerter()
                alerter.alert = Alert(title: Text(didSucceed ? "Bank successfuly exported" : "Export failed"))
                model.alerter = alerter
            }
        } label: {
            Text("Export")
        }
        .disabled(model.selectedBank == nil)
    }
    
    func handleExportOfBank(bank: Bank?, completion: ((Bool)->Void)? = nil) {
        
        guard let bank = bank else { completion?(false); return }
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        if openPanel.runModal() == .OK {
            //elf.filename = panel.url?.lastPathComponent ?? "<none>"
            if let exportDirectory = openPanel.url {
                BankManager.exportBank(bank: bank, exportFolder: exportDirectory) {
                    didSucceed in
                    DispatchQueue.main.async {
                        completion?(didSucceed)
                    }
                }
            }
        }
    }
}
