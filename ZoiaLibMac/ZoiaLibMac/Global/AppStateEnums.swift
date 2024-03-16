/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/

import Foundation



class CustomUTITypes {
    static let ZioaPatchFileUTI: String = "com.polymorphicranch.patchFile"
    static let ZoiaLibDraggalbePatch: String = "com.polymorphicranch.comboFile"
}

enum ListStyle {
    case separated
    case flat
}

enum AppearanceOptions: String, Identifiable, CaseIterable {
    case Dark
    case Light
    case System
    
    var id: String { rawValue }
    
    init() {
        let type = UserDefaults.standard.string(forKey: "AppInterfaceStyle") ?? "Light"
        self = AppearanceOptions(rawValue: type)!
    }
}

enum NavigationItem: String {
    // trying to prevent naming collisions with renamabe banks
    case cloud = "cloud_3_18_69"
    case library = "library_3_18_69"
}

enum StateOfData: String {
    case appLaunched
    case noNetwork
    case hasFullData
}

enum SortOrderItems: String, CaseIterable, Identifiable {
    case asc
    case desc
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .asc: return "Ascending"
        case .desc: return "Descending"
        }
    }
}

enum SortByItems: String, CaseIterable, Identifiable {
    // "orderby" query for API
    case author
    case date
    case modified
    //case relevance
    case title
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .author: return "Author"
        case .date: return "Date Submitted"
        case .modified: return "Date Modified"
        //case .relevance: return "Relevance"
        case .title: return "Patch Title"
        }
    }
}

enum LibraryFilterType: String, CaseIterable {
    case notInLibrary = "Not In Library"
    case inLibrary = "In Library"
}


enum AppError: Error {
    case unknownError
    case networkOffline
    case diskAccessDenied
}

class FilterToggle: ObservableObject, Hashable {
    
    static func == (lhs: FilterToggle, rhs: FilterToggle) -> Bool {
        lhs.data.id == rhs.data.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(data.id)
        hasher.combine(data.name ?? "")
    }
    
    @Published var isOn = false
    let data: PatchStorage.GenericObject
    
    init(data: PatchStorage.GenericObject) {
        self.data = data
    }
}

class LibraryToggle: ObservableObject, Hashable {
    
    @Published var isOn = false
    let name: String
    let id: Int
    
    init(name: String, id: Int) {
        self.name = name
        self.id = id
    }
    
    static func == (lhs: LibraryToggle, rhs: LibraryToggle) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.name)
    }
}



