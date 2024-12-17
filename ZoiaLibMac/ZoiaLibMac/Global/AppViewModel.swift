/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


import SwiftUI
import Combine
import Network


// this is our main singleton app class object that stores all important app state info
// it is currently instantiated by ZoiaLibMacApp.swift as a StateObject and is our main cutsom EnvironmentObject for app data flow
class AppViewModel: ObservableObject {
    

    // MARK: - General App State properties
    @Published var stateOfData: StateOfData = .appLaunched
    @Published var alerter: Alerter = Alerter()
    @Published var bankLoadingProgress = Progress()
    @Published var networkError = false
    
    // MARK: - Sidebar Selection State
    @Published var currentSidebarSelection: String? = NavigationItem.cloud.rawValue {
        didSet {
            onSidebarSelectionChange()
            self.selectedBank = banks.first(where: { $0.name == currentSidebarSelection })
        }}
    
    
    @Published var customColorScheme: String?  {
        didSet {
            print("new colorScheme = \(customColorScheme ?? "")")
        }
    }
    
    // MARK: Selection State properties
    @Published var selectedBrowsePatch: PatchWrapper?
    @Published var selectedFactoryPatchId: String? // { didSet { onSelectedFactoryPatchDidChange() }}
    @Published var selectedBinaryPatchId: String? { didSet { onSelectedBankPatchChange() }}
    @Published var selectedBrowsePatchId: PatchStorage.Patch.ID? { didSet { onSelectedBrowsePatchChange(oldValue: oldValue) }}
    @Published var selectedLocalPatchId: PatchStorage.Patch.ID? { didSet { onSelectedLibraryPatchChange(oldValue: oldValue) }}
    @Published var selectedBinaryPatchFile: ObservableBinaryPatch?
    @Published var selectedPatchForDelete: LocalPatchCombo?
    @Published var selectedBank: Bank?
    @Published var nodeCanvas: [String: NodeCanvas] = [:]
    
    var systemColorScheme: ColorScheme?
    
    // MARK: NodeView settings

    var layoutChangeListeners: [String: (LayoutAlgorithm)->Void] = [:]
    
    @Published var nodeViewLayoutAlgorithm: LayoutAlgorithm = .simpleRecursive {
        didSet {
            for (_, value) in layoutChangeListeners {
                value(nodeViewLayoutAlgorithm)
            }
        }
    }
    
    @Published var nodeViewWindowName: String?
    
    func addLayoutChangeListener(nodeCanvasId: String, handler: @escaping (LayoutAlgorithm)->Void) {
        layoutChangeListeners[nodeCanvasId] = handler
    }
    
    func removeLayoutChangeListener(nodeCanvasId: String) {
        layoutChangeListeners[nodeCanvasId] = nil
    }

    
    // MARK: - Sorting and Filtering Properties
    @Published var searchQuery = "" { didSet { doThrottledSearch() }}
    @Published var sortBySelection: SortByItems = .modified {  didSet { onListFilteringChange() }}
    @Published var orderSelection: SortOrderItems = .desc { didSet { onListFilteringChange() }}
    @Published var tagFilters: [PatchStorage.GenericObject] = [] { didSet { onListFilteringChange() }}
 
    // MARK: - Categories and Filters
    @Published var categoryFilters = CategoryFilter.default
    @Published private(set) var allCategories: [String] = ["Effect","Synthesizer","Sound","Sequencer","Sampler","Other","Game","Composition","Utility","Video"]
    @Published var categoryList: [PatchStorage.GenericObject] = []
    
    @Published var libraryFilters = LibraryFilter.default
    @Published private(set) var allLibraryFilters: [String] = []
	
	var searchThrottle: Timer?
	
	
	func doThrottledSearch() {
		searchThrottle?.invalidate()
		searchThrottle = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) {
			[weak self] timer in
			self?.onListFilteringChange()
		}
	}
    
    struct CategoryFilter: Hashable {
        var hidden: Set<String> = []
        static let `default` = CategoryFilter()
    }
    
    var visibleCategories: Set<String> {
        return Set(allCategories).subtracting(categoryFilters.hidden)
    }
    
    struct LibraryFilter: Hashable {
        var hidden: Set<String> = []
        static let `default` = LibraryFilter()
        
        var disableFetch: Bool {
            return hidden.contains(LibraryFilterType.notInLibrary.rawValue)
        }
    }
    
    // MARK: - List Data

    private(set) var unfilteredCloudPatchList: Set<PatchStorage.Patch> = [] { didSet { onUnfilteredCloudListChanged() }}
    private(set) var filteredCloudPatchList: Set<PatchStorage.Patch> = [] { didSet { onCloudListChanged() }}
    // sortedCloudPatchList is intermediary of sorted browse list before addition of PatchWrapper
    @Published var sortedCloudPatchList: [PatchStorage.Patch] = []
    
    @Published var sortedWrappedPatchList: [PatchWrapper] = []
    @Published var localPatchIdList: Set<String> = []
    private(set) var libraryPatchList: Set<LocalPatchCombo> = [] { didSet { self.sortAndFilterLocalPatchList() }}
    
	// sortedWrappedPatchList is list used in display of Browse List
    @Published var sortedLocalPatchList: [LocalPatchCombo] = []
    @Published var banks: [Bank] = []
    @Published var factoryBank: [BankType:Bank] = [:]
    
    // MARK: - Combine management properties
    var startupCancellables = Set<AnyCancellable>()
    private var subscription = Set<AnyCancellable>()
    private var categoriesCancellable: Cancellable?
    private let networkMonitor = NWPathMonitor()
    
    // patchstorage page API management properties
    private var page: Int = 1
    private var canLoadNextPage = true
    private var pageSize: Int = 50
    
    init() {
        allLibraryFilters = LibraryFilterType.allCases.map { $0.rawValue }
        setupInitialAPILoadListeners()
        
        // load all data needed for app launch
        // TODO: If not connected to network, or patchstorage.com returns error, push user to Library
        EmpressReference.shared.loadModuleList {
            self.initLocalLibrary() {
                self.loadBanks()
                self.loadLocalPatches {
                    self.initPatchStorage()
                }
            }
        }
    }
    
    func setupInitialAPILoadListeners() {
        // setup listener for category list updates
        $categoryList
            .sink {
                list in
                if list.count == 0 {
                    self.stateOfData = .noNetwork
                } else {
                    self.allCategories = list.map { $0.name ?? "" }
                    self.stateOfData = .hasFullData                }
            }
            .store(in: &startupCancellables)
        
        // setup listener for network monitor updates
        $networkError.sink {
            error in
            DispatchQueue.main.async {
                if error {
                    self.stateOfData = .noNetwork
                } else {
                    self.stateOfData = .hasFullData
                }
            }

        }
        .store(in: &startupCancellables)
    }
    

    // MARK: - Published property Update functions
    
    func onListFilteringChange() {
        switch currentSidebarSelection {
        case NavigationItem.cloud.rawValue:
            fetchFirstPageOfPatches()
        case NavigationItem.library.rawValue:
            sortAndFilterLocalPatchList()
        default:
            break
        }
    }
    
    func onSidebarSelectionChange() {
        if currentSidebarSelection == NavigationItem.library.rawValue {
            self.loadLocalPatches()
        }
    }
    
    func onSelectedFactoryPatchDidChange(bankType: BankType) {
        guard let patchIndex = Int(self.selectedFactoryPatchId ?? "") else { return }
        guard let patchFile = self.factoryBank[bankType]?.orderedPatches.item(at: patchIndex) else { return }
        self.selectedBinaryPatchFile = ObservableBinaryPatch(patchFile: patchFile, parsedPatchFile: patchFile.parsedPatch)
    }
    
    func onSelectedBankPatchChange() {
        // find currently selected bank
        guard let currentBank = self.banks.first(where: { $0.name == self.currentSidebarSelection }) else { return }
        guard let patchIndex = Int(self.selectedBinaryPatchId ?? "") else { return }
        guard let patchFile = currentBank.orderedPatches.item(at: patchIndex) else { return }
        self.selectedBinaryPatchFile = ObservableBinaryPatch(patchFile: patchFile, parsedPatchFile: patchFile.parsedPatch)
        //TODO: Go looking for patchstorage.com Patch in Local Libaray folder?
    }
    
    func onSelectedBrowsePatchChange(oldValue: Int?) {
        if selectedBrowsePatchId != oldValue, let patchId = selectedBrowsePatchId {
            self.fetchPatchDetail(patchId: patchId)
        }
    }
    
    func onSelectedLibraryPatchChange(oldValue: Int?) {
        if selectedLocalPatchId != oldValue, let patchId = selectedLocalPatchId {
            libraryPatchList.first(where: { $0.patchJson.id == patchId })?.parseBinaryData()
        }
    }
    
    func onUnfilteredCloudListChanged() {
        if !libraryFilters.hidden.isEmpty {
            self.filterPatchListWithLibraryFilters()
        } else {
            filteredCloudPatchList = self.unfilteredCloudPatchList
        }
    }
    
    func onCloudListChanged() {
        self.sortedCloudPatchList = self.filteredCloudPatchList.sorted()
		
//		if selectedBrowsePatchId == nil {
//			
//			self.selectedBrowsePatchId = sortedCloudPatchList.first?.id
//		}
        
        // TODO: we need to find a better way to do this
        self.sortedWrappedPatchList = self.filteredCloudPatchList.map {
            patch in
            let wrapped = PatchWrapper(patch: patch)
            
            // check localLibrary to see if we have downloaded this patch
            if self.localPatchIdList.contains(patch.id.description) {
                if let libraryPatch = libraryPatchList.first(where: { $0.patchJson.id == patch.id }) {
                    let now = Date()
                    if patch.updated_at ?? now > libraryPatch.patchJson.updated_at ?? now {
                        wrapped.patchDownloader.state = .versionUpdateAvailable
                    } else {
                        wrapped.patchDownloader.state = .completed
                    }
                }
            }

            return wrapped
        }.sorted().reversed()
    }
    

    // MARK: - Bank Management
    
    func loadBanks(completion: (()->Void)? = nil) {
        
        bankLoadingProgress = BankManager.loadAllBanks {
            bankList in
            
            DispatchQueue.main.async {
                
                // TODO: this feels like a wonky way to handle the factory library - revisit
                
                let userBanks = bankList.filter({ $0.bankType == .user })
                
                self.factoryBank[.zoia] = bankList.filter({ $0.bankType == .zoia }).first
                self.factoryBank[.euroburo] = bankList.filter({$0.bankType == .euroburo }).first
                self.banks = userBanks
            }
        } ?? Progress()
    }
    
    func deleteBank(bank: Bank?, completion: ((Bool)->Void)? = nil) {
        guard let bank = bank else { completion?(false); return }
        if let foundIndex = banks.firstIndex(where: { $0.id == bank.id }) {
            BankManager.deleteBank(bank: bank) {
                didSucceed in
                DispatchQueue.main.async {
                    
                    if didSucceed {
                        self.banks.remove(at: foundIndex)
                        self.currentSidebarSelection = NavigationItem.library.rawValue
                    }
                    completion?(didSucceed)
                }
            }
        }
    }
    
    func duplicateBank(bank: Bank?, completion: ((Bool)->Void)? = nil) {
        
        guard let bank = bank else { completion?(false); return }
        let newBankName = bank.name + "-Copy"
        BankManager.duplicateBank(srcBank: bank, dstBankName: newBankName) {
            newBank in
            DispatchQueue.main.async {
                if let newBank = newBank {
                    self.banks.append(newBank)
                    completion?(true)
                } else {
                    completion?(false)
                }
            }
        }
    }
    
    func addNewBank() {
        
        let allNewBanks = banks.filter({ $0.name.lowercased().contains("new bank") })
        let lastIndex = allNewBanks.reduce(0, { currentMax, bank in
            if bank.name.lowercased().contains("new bank") && bank.name.count == "new bank-000".count {
                if let index = Int(bank.name.suffix(3)) {
                    return index > currentMax ? index : currentMax
                }
            }
            return 0
        })
        
        let bankName = String(format: "New Bank-%03d", lastIndex + 1)
        let bank = Bank(bankName: bankName)
        banks.append(bank)
        BankManager.saveBank(bank: bank)
        banks = Array(banks)
    }

    // MARK: - PatchStorage / Cloud Data
    func initPatchStorage() {
        networkMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                switch path.status {
                case .unsatisfied:
                    self.networkError = true
                default:
                    self.networkError = false
                }
            }

        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .background))
        fetchCategories()
    }
    
    
    private func fetchCategories() {
        
        // TODO: load default set of categories or save the previous downloaded set and load that
        guard networkError == false else { return }
        categoriesCancellable = PatchStorageAPI.shared.getZoiaCategories()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self.networkError = true
                }
            }, receiveValue: { categoryList in
                self.categoryList = categoryList
                
                for cat in self.categoryList {
                    print(cat.slug ?? "")
                }
            })
    }
    
    func fetchFirstPageOfPatches() {
        self.canLoadNextPage = true
        self.page = 1
        self.unfilteredCloudPatchList = []
        self.fetchNextPageIfPossible()
    }
    
    func fetchPatchDetail(patchId: Int) {
        PatchStorageAPI.shared.getZoiaPatch(patchId: patchId)
            .sink(receiveCompletion: {
                completion in
                switch completion {
                case .finished:
                    print("finished")
                    break
                    
                case .failure(let error):
                    print("api.getZoiaPatche error:")
                    print(error)
                }
            }, receiveValue: {
                detailPatch in
                
                DispatchQueue.main.async {
                    if let wrappedPatch = self.sortedWrappedPatchList.first(where: { $0.patch.id == detailPatch.id } ) {
                        wrappedPatch.patchDetail = detailPatch
                        
                        let isValid = detailPatch.fileName?.lowercased().suffix(4) == ".bin" || detailPatch.fileName?.lowercased().suffix(4) == ".zip"
                        if !isValid {
                            wrappedPatch.patchDownloader.state = .invalidFile
                        }
                    }
                }
            })
            .store(in: &subscription)
    }
    
    func fetchNextPageIfPossible() {
        
        guard canLoadNextPage else { return }
        var categories: Set<Int> = []
        let tagList: Set<Int>? = Set( self.tagFilters.map { $0.id } )
        
        
        print("requesting page size = \(self.pageSize)")
        // if we have category filters, then create the exclusion list
        if !self.visibleCategories.isEmpty  {
            for categoryName in self.visibleCategories {
                if let categoryId = categoryList.first(where: { $0.name == categoryName })?.id {
                    categories.insert(categoryId)
                }
            }
        }
        pageSize = categoryFilters.hidden.count == 0 ? 50 : 100
        PatchStorageAPI.shared.getZoiaPatchesForPage(page: self.page, sortBy: self.sortBySelection, sortOrder: self.orderSelection, pageSize: self.pageSize, categories: categories, tagsIncluded: tagList, searchQuery: self.searchQuery.isEmpty ? nil : self.searchQuery)
            .sink(receiveCompletion: {
                completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("api.getZoiaPatchesForPage error:")
                    print(error)
                    print("we got an error - setting canLoadNextPage to false!!!!!!!!")
                    self.canLoadNextPage = false
                }
            }, receiveValue: {
                patchData in
                print("number patches received = \(patchData.count)")
                self.unfilteredCloudPatchList = self.unfilteredCloudPatchList.union(Set(patchData))
                self.page += 1
                self.canLoadNextPage = (patchData.count == self.pageSize)
            })
            .store(in: &subscription)
    }
    
    
    // MARK: - Sorting and Filtering functions
    func clearTagFilters() {
        tagFilters = []
    }
    
    func addTagFilter(tag: PatchStorage.GenericObject) {
        if !tagFilters.contains(tag) {
            tagFilters.append(tag)
            onListFilteringChange()
        }
        
    }
    
    func removeTagFilter(tag: PatchStorage.GenericObject) {
        tagFilters = tagFilters.filter({ $0.id != tag.id })
    }
    
    func filterPatchListWithLibraryFilters() {
        self.filteredCloudPatchList = filterPatchList(libraryFilters: self.libraryFilters.hidden, patchList: self.unfilteredCloudPatchList)
    }

    // libraryFilters is list of *hidden* types
    func filterPatchList(libraryFilters: Set<String>, patchList: Set<PatchStorage.Patch>) -> Set<PatchStorage.Patch> {
        
        print("libraryData.filterPatchList with filter set = ")
        print(libraryFilters)
        return patchList.filter( {
            patch in
            
            var flagged = false
            if libraryFilters.contains(LibraryFilterType.notInLibrary.rawValue) {
                let inLibrary = localPatchIdList.contains(patch.id.description)
                flagged = !inLibrary
            }
            if libraryFilters.contains(LibraryFilterType.inLibrary.rawValue) {
                let inLibrary = localPatchIdList.contains(patch.id.description)
                flagged = inLibrary
            }
            return !flagged
        })
    }

    func sortAndFilterLocalPatchList() {
        
        DispatchQueue.global(qos: .background).async {
            
            let fullCategories = Set(self.allCategories)
            let visibleCategories = fullCategories.symmetricDifference(self.categoryFilters.hidden)
            
            var filteredFiles = self.libraryPatchList.filter {
                patch in
                let categoriesInPatch = Set((patch.patchJson.categories ?? []).map { $0.name })
                return !categoriesInPatch.intersection(visibleCategories).isEmpty
            }
            
            
            if !self.tagFilters.isEmpty {
                filteredFiles = filteredFiles.filter {
                    patch in
                    let tagsInPatch = Set(patch.patchJson.tags ?? [])
                    return !tagsInPatch.intersection(Set(self.tagFilters)).isEmpty
                }
            }
            
            if !self.searchQuery.isEmpty {
                filteredFiles = filteredFiles.filter {
                    patch in
                    
                    let query = self.searchQuery.lowercased()
                    return patch.patchJson.author?.name?.lowercased().contains(query) == true ||
                    patch.patchJson.content?.lowercased().contains(query) == true ||
                    patch.patchJson.title?.lowercased().contains(query) == true ||
                    patch.patchJson.excerpt?.lowercased().contains(query) == true
                }
            }

            var tempSort: [LocalPatchCombo] = []
            
            switch self.sortBySelection {
            case .author:
                tempSort = filteredFiles.sorted(by: { $0.patchJson.author?.name?.lowercased() ?? "" < $1.patchJson.author?.name?.lowercased() ?? "" })
            case .date:
                tempSort = filteredFiles.sorted(by: { $0.patchJson.created_at ?? Date() < $1.patchJson.created_at ?? Date() })
            case .modified:
                tempSort = filteredFiles.sorted(by: { $0.patchJson.updated_at ?? Date() < $1.patchJson.updated_at ?? Date() })
                // .relevance seems broken on patchstorage.com
//            case .relevance:
//                tempSort = filteredFiles.sorted(by: { $0.patchJson.download_count ?? 0 < $1.patchJson.download_count ?? 0 })
            case .title:
                tempSort = filteredFiles.sorted(by: { $0.patchJson.slug ?? "" < $1.patchJson.slug ?? "" })
            }
            DispatchQueue.main.async {
                self.sortedLocalPatchList = self.orderSelection == .desc ? tempSort.reversed() : tempSort
            }
        }
    }
    
    
    // MARK: - LibraryData functions
    // builds patchIdList by reading /ApplicationSupport/ZoiaLib/Library folder - each folder name is the ID of a patch
    // each folder should contain a .json file which is the downloaded PatchDetail object from patchstorage.com
    // + a .bin file which eaither follows the zioa naming convention or will be renamed to the zoia naming convention
    // of XXX_zoia_patch_name.binå
    
    func openPatchInEditor(patchId: String ) {
        if let comboPatch = libraryPatchList.first(where: { $0.patchJson.id.description == patchId }) {
            nodeViewWindowName = comboPatch.parsedPatch?.name ?? "nodeView"
            NSWorkspace.shared.open(comboPatch.folderPath)
        }
    }
    
    func openPatchFolder(patchId: String) {
        if let comboPatch = libraryPatchList.first(where: { $0.patchJson.id.description == patchId }) {
            //NSWorkspace.shared.open(comboPatch.folderPath)
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: comboPatch.folderPath, includingPropertiesForKeys: nil)
                
                if let firstFile = contents.first {
                    NSWorkspace.shared.activateFileViewerSelecting([NSURL].init(arrayLiteral: NSURL.init(fileURLWithPath: firstFile.path)) as [URL])
                }
            } catch {
                
            }
            
        }
    }
    
    // this call always returns on background thread
    func deletePatch(patch: LocalPatchCombo?, completion: ((Bool)->Void)? = nil) {
        guard let patch = patch else { completion?(false); return }
        
        // save off indeces for later deletion if file deletion succeeds d
        let patchIdListIndex = localPatchIdList.firstIndex(where: { $0 == patch.id.description })
        let libraryPatchListIndex = libraryPatchList.firstIndex(where: { $0.patchJson.id == patch.id })
        DispatchQueue.global(qos: .background).async {
            do {
                let patchDirectory = try AppFileManager.patchLibraryUrl().appendingPathComponent(patch.patchJson.id.description + AppFileManager.bundleExtension, isDirectory: true)
                if FileManager.default.fileExists(atPath: patchDirectory.path) {
                    try FileManager.default.removeItem(at: patchDirectory)
                }
                DispatchQueue.main.async {
                    if let patchIdListIndex = patchIdListIndex {
                        self.localPatchIdList.remove(at: patchIdListIndex)
                    }
                    if let libraryPatchListIndex = libraryPatchListIndex {
                        self.libraryPatchList.remove(at: libraryPatchListIndex)
                    }
                    self.filterPatchListWithLibraryFilters()
                }
                completion?(true)
            } catch {
                completion?(false)
            }
        }
    }
    
    func initLocalLibrary(completion: @escaping ()->Void) {
        // this call always returns on background thread
        BankManager.initFactoryBankIfNeeded {
            do {
                let libraryFolder = try AppFileManager.patchLibraryUrl()
                let fileArray = try FileManager.default.contentsOfDirectory(at: libraryFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                DispatchQueue.main.async {
                    self.localPatchIdList = Set(fileArray.map {
                        url in
                        //$0.lastPathComponent.dropLast(4) })
                        // .zbundle
                        let lpc = String(url.lastPathComponent.dropLast(AppFileManager.bundleExtension.count))
                        return lpc
                    })
                    completion()
                }
            } catch {
                print("error getting list of patches in library")
                DispatchQueue.main.async {
                    completion()
                }
                
            }
        }
    }

    func loadLocalPatches(completion: (()->Void)? = nil) {
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        var comboPatchList: Set<LocalPatchCombo> = []
        DispatchQueue.global(qos: .background).async {
            do {
                let libraryFolder = try AppFileManager.patchLibraryUrl()
                let listOfAllPatchFolders = try FileManager.default.contentsOfDirectory(at: libraryFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

                for patchFolder in listOfAllPatchFolders {
                    let patchParts = try FileManager.default.contentsOfDirectory(at: patchFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                    
                    guard let jsonPatchPath = patchParts.first(where: { $0.pathExtension.contains("json") && $0.lastPathComponent.first?.isNumber == true }) else { continue }
                    guard let binaryPatchPath = patchParts.first(where: { $0.pathExtension.contains("bin") } ) else { continue }
                    
                    let jsonData = try Data(contentsOf: jsonPatchPath)
                    let binaryPatchData = try Data(contentsOf: binaryPatchPath)
                    let jsonPatch: PatchStorage.Patch = try jsonDecoder.decode(PatchStorage.Patch.self, from: jsonData)
                    let localPatchCombo = LocalPatchCombo(patchJson: jsonPatch, patchData: binaryPatchData, folderPath: patchFolder, filePath: binaryPatchPath)
                    comboPatchList.insert(localPatchCombo)
                }
                DispatchQueue.main.async {
                    self.libraryPatchList = comboPatchList
                    completion?()
                }
            } catch {
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }
}


