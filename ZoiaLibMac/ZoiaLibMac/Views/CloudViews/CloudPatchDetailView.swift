/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI
import CachedAsyncImage
import YouTubePlayerKit

struct CloudPatchDetailView: View {

    @EnvironmentObject private var model: AppViewModel
    @ObservedObject var patch: PatchWrapper
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            CachedAsyncImage(url: URL(string: patch.patchDetail?.artwork?.url ?? patch.patch.artwork?.url ?? "https://patchstorage.com/wp-content/uploads/2022/04/ZoiaholeA-1024x737.jpg")) { image in
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
                    Text(patch.patchDetail?.title ?? patch.patch.title ?? "")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                        .padding(.bottom, 2)
                    Text("By: " + (patch.patchDetail?.author?.name ?? patch.patch.author?.name ?? ""))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)
                        .onTapGesture(perform: {
                            model.searchQuery = "\(patch.patchDetail?.author?.name ?? patch.patch.author?.name ?? "")"
                        })
                }

                Spacer()
                PatchDownloadButton(patchDownloader: patch.patchDownloader,
                                    subText: patch.patchDetail?.updated_at?.simpleDateString() ?? patch.patch.updated_at?.simpleDateString() ?? "",
                                    subText2: patch.patchDetail?.revision ?? patch.patch.revision,
                                    width: 100,
                                    hoverColor: Color("Color-8"), color: .primary, downloadingColor: Color("Color-9"))

            }
            .padding([.leading, .trailing], Layout.detailViewSideMargin)
            
            
            HStack {
                PatchCategoryView(patch: patch.patchDetail ?? patch.patch, width: 100, isListStyle: false)
                VStack(alignment: .leading) {
                    WrappingRoundedRectTagView(patch: patch.patchDetail ?? patch.patch, uppercased: false, isListStyle: false, onTapped: {
                        tag in
                        model.addTagFilter(tag: tag)
                    })
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
                        Text(patch.patchDetail?.like_count?.description ?? patch.patch.like_count?.description ?? "")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.tertiaryMetadata)
                    }
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 20.0))
                            .foregroundColor(AppColors.tertiaryMetadata)
                        Spacer()
                        Text(patch.patchDetail?.download_count?.description ?? patch.patch.download_count?.description ?? "")
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
            .padding(.bottom, 20)
            ScrollView {
                Text(patch.patchDetail?.content ?? "")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.primary)
                    .frame(minWidth: 660, maxWidth: .infinity, minHeight: 50, alignment: .leading)
                    .padding(10)
                    .padding(.bottom, 30)
            }
            .groupStyle(radius: 10)
            .padding([.leading, .trailing], Layout.detailViewSideMargin)
            .frame(maxHeight: 300)
            .padding(.bottom, 10)

            if patch.patchDetail?.preview_url?.contains("you") == true, let url = patch.patchDetail?.preview_url {

                YouTubePlayerView(YouTubePlayer(stringLiteral: url))
                    .frame(height: 500)
                    .cornerRadius(5)
                    .overlay( RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.init(red: 0.1, green: 0.1, blue: 0.1), lineWidth: 2))
                    .padding(.top, 30)
                    .padding([.leading, .trailing], Layout.detailViewSideMargin)
                    .padding(.bottom, 40)
            }
            Spacer()
        }
    }
}

