/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI
import CachedAsyncImage
import YouTubePlayerKit

struct LibraryPatchDetailView: View {
    
    @ObservedObject var patch: LocalPatchCombo
    @EnvironmentObject private var model: AppViewModel
 
    var body: some View {
        ScrollView {
            CachedAsyncImage(url: URL(string: patch.patchJson.artwork?.url ?? "https://patchstorage.com/wp-content/uploads/2022/04/ZoiaholeA-1024x737.jpg")) { image in
                image.resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .detailImageStyle()
            .padding(.top, 50)
            .padding([.leading, .trailing], Layout.detailViewSideMargin)
            .padding(.bottom, 20)
            HStack {
                VStack(alignment: .leading) {
                    Text(patch.patchJson.title ?? "")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                        .padding(.bottom, 2)
                    Text("By: " + (patch.patchJson.author?.name ?? ""))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)
                        .onTapGesture(perform: {
                            model.searchQuery = "\(patch.patchJson.author?.name ?? "")"
                        } )
                }

                Spacer()
                PatchDownloadButton(patchDownloader: PatchDownloader(patchId: patch.patchJson.id.description, modifiedDate: patch.patchJson.updated_at ?? Date(), state: .openBundleInNodeEditor),
                                    subText: patch.patchJson.updated_at?.simpleDateString() ?? "",
                                    subText2: patch.patchJson.revision,
                                    width: 100,
                                    hoverColor: Color("Color-8"), color: .primary, downloadingColor: Color("Color-9"))
            }
            .padding([.leading, .trailing], Layout.detailViewSideMargin)
            
            HStack {
                PatchCategoryView(patch: patch.patchJson, width: 100, isListStyle: false)
                VStack(alignment: .leading) {
                    WrappingRoundedRectTagView(patch: patch.patchJson, uppercased: true, isListStyle: false, onTapped: {
                        tag in
                        model.addTagFilter(tag: tag)
                    } )
                    .padding(.top, 6)
                    .padding(.bottom, 6)
                }
                .padding(.leading, 20)
                Spacer()
                VStack {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20.0))
                            .foregroundColor(AppColors.tertiaryMetadata)
                            
                        Spacer()
                        Text(patch.patchJson.like_count?.description ?? "")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.tertiaryMetadata)
                    }
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 20.0))
                            .foregroundColor(AppColors.tertiaryMetadata)
                        Spacer()
                        Text(patch.patchJson.download_count?.description ?? "")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.tertiaryMetadata)
                    }
                    
                }
                .frame(width: 75)
                
            }
            .padding(20)
            .groupStyle(radius: 10)
            .padding(.top, 10)
            .padding([.leading, .trailing], Layout.detailViewSideMargin)
            
            PatchIOView(numPages: patch.parsedPatch?.pages.count ?? 0, patch_io: patch.parsedPatch?.patch_io ?? ParsedBinaryPatch.IO())
                .padding(20)
                .groupStyle(radius: 10)
                .onTapGesture(count: 2, perform: {
                    AppRouter.shared.openPatchFileInEditor(filePath: patch.patchFilePath)
                })
                .padding(Layout.detailViewSideMargin)
            
            ScrollView {
                Text(patch.patchJson.content ?? "")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.primary)
                    .frame(minWidth: 660, maxWidth: .infinity, minHeight: 50, alignment: .leading)
                    .padding(10)
                    .padding(.bottom, 30)
            }
            .groupStyle(radius: 10)
            .padding([.leading, .trailing], Layout.detailViewSideMargin)
            .frame(maxHeight: 300)
            .padding(.bottom, 20)

            if patch.patchJson.preview_url?.contains("you") == true, let url = patch.patchJson.preview_url {

                YouTubePlayerView(YouTubePlayer(stringLiteral: url))
                    .frame(height: 500)
                    .cornerRadius(5)
                    .overlay( RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.init(red: 0.1, green: 0.1, blue: 0.1), lineWidth: 2))
                    .padding(.top, 30)
                    .padding([.leading, .trailing], Layout.detailViewSideMargin)
                    .padding(.bottom, 20)
            }
            
            VStack {
                ForEach(patch.parsedPatch?.pages ?? []) {
                    page in
                    PatchPageView(page: page)
                }
            }
            .padding(.top, 5)
            Spacer()
        }
    }
}

/*
 .contextMenu {
     Button {
         // openDirectory
         model.openPatchFolder(comboPatch: patch)
     } label: {
         Text("Open Patch Bundle")
     }
 }
 */
