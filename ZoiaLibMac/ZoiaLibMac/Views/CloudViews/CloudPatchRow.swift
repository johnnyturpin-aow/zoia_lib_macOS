/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI
import WrappingHStack
import CachedAsyncImage

struct CloudPatchRow: View {
    
    @ObservedObject var patch: PatchWrapper
    
    static let nameWidth: CGFloat = 225
    static let descriptionWidth: CGFloat = 200
    static let categoryWidth: CGFloat = 100
    static let tagsWidth: CGFloat = 300
    
    @EnvironmentObject private var model: AppViewModel
    @State private var downloadButtonHover = false
    
    var body: some View {
        HStack {
            PatchImageView(patch: patch.patch, width: 96, height: Layout.rowHeight - 4, shadowRadius: 2)
                .padding(2)
            VStack(alignment: .leading, spacing: 0) {
                Text(patch.patch.title ?? "")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(width: CloudPatchRow.nameWidth, alignment: .leading)
                    .padding(.bottom, 5)
                
                Text(patch.patch.author?.name ?? "")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: CloudPatchRow.nameWidth, alignment: .leading)

            }
            .frame(width: CloudPatchRow.nameWidth)
            
            Text(patch.patch.excerpt ?? "")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .padding(.leading, 10)
                .frame(minWidth: 50, idealWidth: CloudPatchRow.descriptionWidth, maxWidth: CloudPatchRow.descriptionWidth)
                
            PatchCategoryView(patch: patch.patch, width: 80, isListStyle: true)
            .padding(20)
            
            WrappingRoundedRectTagView(patch: patch.patch, uppercased: false, isListStyle: true, onTapped: { tag in
                print("tag[\(tag.name ?? "")] tapped")
                model.addTagFilter(tag: tag)
            })
            .padding(.leading, 5)
            .frame(minWidth: 75, idealWidth: CloudPatchRow.tagsWidth, maxWidth: CloudPatchRow.tagsWidth)
            
            
            PatchDownloadButton(patchDownloader: patch.patchDownloader,
                                subText: patch.patch.updated_at?.simpleDateString() ?? "",
                                subText2: patch.patch.revision,
                                width: 100,
                                hoverColor: Color("Color-8"), color: .primary, downloadingColor: Color("Color-9"))
            .padding([.top, .bottom], 3)

            Spacer()
        }
        
        .frame(height: Layout.rowHeight)
        .padding([.top, .bottom], 0)
        
    }
}

