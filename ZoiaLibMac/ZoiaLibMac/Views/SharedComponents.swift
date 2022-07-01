/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI
import CachedAsyncImage
import WrappingHStack



struct PatchImageView: View {
    
    let patch: PatchStorage.Patch
    let width: CGFloat
    let height: CGFloat
    let shadowRadius: CGFloat
    
    var body: some View {
        Group {
            CachedAsyncImage(url: URL(string: patch.artwork?.url ?? "https://patchstorage.com/wp-content/uploads/2022/04/ZoiaholeA-1024x737.jpg")) { image in
                image.resizable()
            } placeholder: {
                Color.gray
            }
            .frame(width: width, height: height)
            .cornerRadius(2)
            .overlay(RoundedRectangle(cornerRadius: 2)
                .stroke(Color.black, lineWidth: 2))
            .shadow(radius: shadowRadius)
        }
    }
}

struct WrappingRoundedRectTagView: View {
    
    @EnvironmentObject private var model: AppViewModel
    let patch: PatchStorage.Patch
    let uppercased: Bool
    let isListStyle: Bool
    let onTapped: ((PatchStorage.GenericObject) -> Void)
    private func tagColorForTag(tagName: String?) -> Color {
        
        var color = PatchStorage.colorForTag(tagName: tagName) ?? .secondary
        if !isListStyle {
            return color
        }
        switch model.currentSidebarSelection {
        case NavigationItem.cloud.rawValue:
            if patch.id == model.selectedBrowsePatchId {
                color = PatchStorage.colorForTagSelected(tagName: tagName) ?? Color(red: 0.7, green: 0.7, blue: 0.7)
            }
        case NavigationItem.library.rawValue:
            if patch.id == model.selectedLocalPatchId {
                color = PatchStorage.colorForTagSelected(tagName: tagName) ?? Color(red: 0.7, green: 0.7, blue: 0.7)
            }
        
        default:
            break
        }
        
        return color
    }
    
    var body: some View {
        WrappingHStack(patch.tags ?? [], id: \.self) { tag in
            Button(uppercased == true ? (tag.name?.uppercased() ?? "") : (tag.name ?? "")) {
                onTapped(tag)
            }
            .buttonStyle(PlainButtonStyle())
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(self.tagColorForTag(tagName: tag.name))
                .padding(3)
                .background(Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 5)
                    .stroke(self.tagColorForTag(tagName: tag.name)))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.top, 5)
                
        }
    }
}

struct PatchCategoryView: View {
    
    let patch: PatchStorage.Patch
    let width: CGFloat
    let isListStyle: Bool
    
    var body: some View {
        VStack {
            if patch.categories?.count ?? 0 > 1 {
                Text(patch.mainCategory)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.categoryLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .frame(width: width)
                    
                Text(patch.subCategories)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(AppColors.categoryLabel)
                    .multilineTextAlignment(.center)
                    .padding([.leading, .trailing], 5)
                    .frame(width: width)
                    
                    
            } else {
                Text(patch.mainCategory)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.categoryLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }

        
        .frame(width: CloudPatchRow.categoryWidth, height: Layout.rowHeight - 5)
        .background(PatchStorage.colorForCategory(categoryName: patch.mainCategory) ?? (isListStyle ? .gray : .gray))
        .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.categoryStroke, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(Color.white, Color.init(red: 0.9, green: 0.9, blue: 0.9))
        
    }
}

struct PatchDownloadButton: View {

    @ObservedObject var patchDownloader: PatchDownloader
    static let downloadIconSize: CGFloat = 36.0
    @State private var downloadButtonHover = false
    
    @EnvironmentObject private var model: AppViewModel
    let subText: String
    let subText2: String?
    let width: CGFloat
    let hoverColor: Color
    let color: Color
    let downloadingColor: Color
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                switch patchDownloader.state {
                case .invalidFile:
                    Image(systemName: "xmark.square")
                        .font(.system(size: PatchDownloadButton.downloadIconSize))
                        .foregroundStyle(color)
                        .padding(0)
                case .noLocalCopy:
                    Button {
                        patchDownloader.download()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: PatchDownloadButton.downloadIconSize))
                    }
                    
                    .padding(0)
                    .foregroundStyle(downloadButtonHover ? hoverColor : color)
                    .buttonStyle(PlainButtonStyle())
                    .onHover { over in
                        downloadButtonHover = over
                    }
                case .versionUpdateAvailable:
                    Button {
                        patchDownloader.download()
                    } label: {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .font(.system(size: PatchDownloadButton.downloadIconSize))
                    }
                    
                    .padding(0)
                    .foregroundStyle(downloadButtonHover ? hoverColor : color)
                    .buttonStyle(PlainButtonStyle())
                    .onHover { over in
                        downloadButtonHover = over
                    }
                case .downloadingBinary, .downloadingPatchJson:
                    Button {
                        patchDownloader.cancel()
                    } label: {
                        Image(systemName: "stop.circle")
                            .font(.system(size: PatchDownloadButton.downloadIconSize))
                    }
                    
                    .padding(0)
                    .foregroundStyle(downloadButtonHover ? hoverColor : downloadingColor)
                    .buttonStyle(PlainButtonStyle())
                    .onHover { over in
                        downloadButtonHover = over
                    }
                case .completed:
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: PatchDownloadButton.downloadIconSize))
                        .foregroundStyle(color)
                        .padding(0)
                case .error:
                    Image(systemName: "exclamationmark.arrow.circlepath")
                        .font(.system(size: PatchDownloadButton.downloadIconSize))
                        .foregroundColor(.red)
                        .padding(0)
                case .bundleIsPatchFile:
                    Button {
                        model.openPatchFolder(patchId: patchDownloader.patchId)
                    } label: {
                        Image("doc-waveform")
                            .font(.system(size: PatchDownloadButton.downloadIconSize))
                            .foregroundStyle(color)
                            .padding(0)
                    }
                    
                    .padding(0)
                    .foregroundStyle(downloadButtonHover ? hoverColor : color)
                    .buttonStyle(PlainButtonStyle())
                    .onHover { over in
                        downloadButtonHover = over
                    }
                case .bundleIsZipFile:
                    Button {
                        model.openPatchFolder(patchId: patchDownloader.patchId)
                    } label: {
                        Image(systemName: "doc.zipper")
                            .font(.system(size: PatchDownloadButton.downloadIconSize))
                            .foregroundStyle(color)
                            .padding(0)
                    }
                    .padding(0)
                    .foregroundStyle(downloadButtonHover ? hoverColor : color)
                    .buttonStyle(PlainButtonStyle())
                    .onHover { over in
                        downloadButtonHover = over
                    }
                case .openBundleInNodeEditor:
                    Button {
                        model.openPatchInEditor(patchId: patchDownloader.patchId)
                    } label: {
                        Image("node-square")
                            .font(.system(size: PatchDownloadButton.downloadIconSize))
                            .foregroundStyle(color)
                            .padding(0)
                    }
                    .contextMenu {
                        Button {
                            model.openPatchFolder(patchId: patchDownloader.patchId)
                        } label: {
                            Text("View in finder")
                        }
                    }
                    .padding(0)
                    .foregroundStyle(downloadButtonHover ? hoverColor : color)
                    .buttonStyle(PlainButtonStyle())
                    .onHover { over in
                        downloadButtonHover = over
                    }
                }
            }
            .padding(.bottom, 1)
            if subText2 == nil {
                Text(subText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(0)
                    .frame(width: CloudPatchRow.nameWidth, alignment: .center)
            } else {
                Text(subText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: CloudPatchRow.nameWidth, alignment: .center)
                    .padding(0)
                Text("(ver: \(subText2 ?? ""))")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color.init(red: 0.6, green: 0.6, blue: 0.6))
                    .frame(width: CloudPatchRow.nameWidth, alignment: .center)
            }
            Spacer()
        }
        .frame(width: width)
    }
}

