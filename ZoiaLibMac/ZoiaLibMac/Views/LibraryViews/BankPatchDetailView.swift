/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI

struct BankPatchDetailView: View {
    
    @EnvironmentObject private var model: AppViewModel
    
    var body: some View {
        
        if let patch = model.selectedBinaryPatchFile?.patchFile {
            switch patch.patchType {
            case .empty:
                VStack {
                    HStack {
                        // TODO: Make this better
                        Text("This slot is available for a patch")
                            .foregroundStyle(.primary)
                            .font(.system(size: 32, weight: .regular))
                            .padding(.top, 20)
                        Spacer()
                    }
                    Spacer()
                }
            case .user, .blank:
                ScrollView {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(patch.name ?? "")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.primary)
                                .padding(.bottom, 2)
                            Text("Target Slot: \(patch.targetSlot)")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.top, 20)
                        Spacer()
                        
                    }
                    .padding([.leading, .trailing], Layout.detailViewSideMargin)
                    .padding(.top, 20)
                    PatchIOView(numPages: patch.numPages, patch_io: patch.patch_io)
                        .padding(20)
                        .groupStyle(radius: 10)
                        .padding(Layout.detailViewSideMargin)
                        .onTapGesture(count: 2, perform: {
                            if let patchPath = patch.patchFilePath  {
                                let patchUrl = URL(fileURLWithPath: patchPath)
                                AppRouter.shared.openPatchFileInEditor(filePath: patchUrl)
                            }
                        })
                    VStack {
                        ForEach(model.selectedBinaryPatchFile?.parsedPatchFile?.pages ?? []) {
                            page in
                            PatchPageView(page: page)
                        }
                    }
                    Spacer()
                }

            }
        } else {
            EmptyView()
        }
    }
}

