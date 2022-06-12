/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI
import Combine

struct LibraryPatchRow: View {
    
    @ObservedObject var patch: LocalPatchCombo
    
    let isSelected: Bool
    static let nameWidth: CGFloat = 250
    static let descriptionWidth: CGFloat = 500
    static let categoryWidth: CGFloat = 100
    static let tagsWidth: CGFloat = 250
        
    @EnvironmentObject private var model: AppViewModel
    
    var body: some View {
        
        VStack {
            HStack {
                PatchImageView(patch: patch.patchJson, width: 96, height: Layout.rowHeight - 4, shadowRadius: 2)
                    .padding(2)
                    // ok this sucks - this is a bug with .onDrag of list items
                    // adding .onDrag blocks the selecting mechanic - so we have add back in one of our own
                    // this is the reason why we don't have the .onDrag on the entire row
                    .onTapGesture {
                        model.selectedLocalPatchId = patch.patchJson.id
                    }
                    .onDrag {
                        return NSItemProvider(item: patch.folderPath as NSURL, typeIdentifier: "public.file-url")
                    }
                VStack(alignment: .leading, spacing: 0) {
                    Text(patch.patchJson.title ?? "")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .frame(width: CloudPatchRow.nameWidth, alignment: .leading)
                        .padding(.bottom, 5)

                    Text(patch.patchJson.author?.name ?? "")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(width: CloudPatchRow.nameWidth, alignment: .leading)

                }
                .frame(width: CloudPatchRow.nameWidth)
                
                Text(patch.patchJson.excerpt ?? "")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .padding(.leading, 10)
                    .frame(minWidth: 50, idealWidth: CloudPatchRow.descriptionWidth, maxWidth: CloudPatchRow.descriptionWidth)
                    
                PatchCategoryView(patch: patch.patchJson, width: 80, isListStyle: true)
                .padding(20)
                
                WrappingRoundedRectTagView(patch: patch.patchJson, uppercased: false, isListStyle: true, onTapped: { tag in
                    model.addTagFilter(tag: tag)
                })
                .padding(.leading, 5)
                .frame(minWidth: 75, maxWidth: CloudPatchRow.tagsWidth)
                Spacer()
            }
        }
        .frame(height: Layout.rowHeight)
        .padding([.top, .bottom], 0)
    }
}


