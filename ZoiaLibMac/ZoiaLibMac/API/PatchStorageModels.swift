/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import SwiftUI

struct PatchStorage {
    
    struct Artwork: Codable {
        let url: String?
    }
    
    struct GenericObject: Codable, Identifiable, Hashable {
        let id: Int
        let slug: String?
        let name: String?
        let description: String?
    }
    
    struct DownloadableFile: Codable, Identifiable {
        let id: Int
        let url: String?
        let filesize: Int
        let filename: String?
    }
}


extension PatchStorage {
    
    struct Platform: Codable, Identifiable {
        let id: Int
        let selfUrl: String?
        let description: String?
        let slug: String?
        let name: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case selfUrl = "self"
            case description
            case slug
            case name
        }
    }
}

/*
 * as of Jun 1, 2022 - these are the categories on patchstorage.com
 
  composition
  effect
  game
  other
  sampler
  sequencer
  sound
  synthesizer
  utility
  video
  
 */

extension PatchStorage {

    struct Patch: Codable, Identifiable, Equatable, Hashable, Comparable {
        static func < (lhs: PatchStorage.Patch, rhs: PatchStorage.Patch) -> Bool {
            lhs.updated_at ?? Date() < rhs.updated_at ?? Date()
        }
        
        static func == (lhs: PatchStorage.Patch, rhs: PatchStorage.Patch) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id.description)
            hasher.combine(slug ?? "")
        }

        // cheesy attempt at prioritizing main category
        var indexOfMainCat: Int? {
            var index: Int?
            index = categories?.firstIndex(where: { $0.slug == "sequencer" }) ?? index
            index = categories?.firstIndex(where: { $0.slug == "effect" }) ?? index
            index = categories?.firstIndex(where: { $0.slug == "sound" }) ?? index
            index = categories?.firstIndex(where: { $0.slug == "composition" }) ?? index
            index = categories?.firstIndex(where: { $0.slug == "sampler" }) ?? index
            index = categories?.firstIndex(where: { $0.slug == "synthesizer" }) ?? index
            return index
        }
        
        var mainCategory: String {
            if let index = indexOfMainCat {
                return categories?.item(at: index)?.name ?? ""
            }
            return categories?.first?.name ?? ""
        }
        
        var subCategories: String {
            var subCatList = categories
            if let index = indexOfMainCat {
                subCatList?.remove(at: index)
            }
            return subCatList?.map {String($0.name ?? "") }.joined(separator: ",") ?? ""
        }
        
        var fileName: String? {
            return files?.first?.filename
        }
        
        let id: Int
        let selfUrl: String?
        let link: String?
        let created_at: Date?
        let updated_at: Date?
        let slug: String?
        let title: String?
        let excerpt: String?
        let content: String?
        let files: [DownloadableFile]?
        let artwork: Artwork?
        let revision: String?
        let preview_url: String?
        let comment_count: Int?
        let view_count: Int?
        let like_count: Int?
        let download_count: Int?
        let author: GenericObject?
        let categories: [GenericObject]?
        let tags: [GenericObject]?
        let platform: GenericObject?
        let state: GenericObject?
        let license: GenericObject?
        let customer_license_text: String?
        
        // custom property to identify downloaded patches that are .zip archives
        var is_zip_archive: Bool?
        
        enum CodingKeys: String, CodingKey {
            case id
            case selfUrl = "self"
            case link
            case created_at
            case updated_at
            case slug
            case title
            case excerpt
            case content
            case artwork
            case files
            case comment_count
            case view_count
            case like_count
            case download_count
            case author
            case categories
            case tags
            case platform
            case state
            case preview_url
            case revision
            case license
            case customer_license_text
            case is_zip_archive
        }
    }
}


