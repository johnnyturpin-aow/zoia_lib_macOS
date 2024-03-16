/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


import Foundation
import Combine

protocol EndpointKind {
    associatedtype RequestData
    static func prepare(_ request: inout URLRequest, with data: RequestData)
}

enum EndpointKinds {

    enum Get: EndpointKind {
        static func prepare(_ request: inout URLRequest, with _: Void) {
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.addValue("*/*", forHTTPHeaderField: "Accept")
            request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
            request.addValue("ZoiaLibMac/1.0.0", forHTTPHeaderField: "User-Agent")
            request.httpMethod = "GET"
        }
    }
}

struct Endpoint<Kind: EndpointKind, Response: Decodable> {
    var path: String
    var queryItems = [URLQueryItem]()
    
    func makeRequest(with data: Kind.RequestData) -> URLRequest? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "patchstorage.com"
        var p1 = path
        if path.first == "/" {
            p1 = String(path.dropFirst())
        }
        components.path = "/api/beta/" + p1
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        // If either the path or the query items passed contained
        // invalid characters, we'll get a nil URL back:
        guard let url = components.url else {
            print("error building URL")
            return nil
        }

        var request = URLRequest(url: url)
        print("endpoint URL = \(url.absoluteString)")
        
        Kind.prepare(&request, with: data)
        return request
    }
}

enum CustomError: Error, CustomStringConvertible, LocalizedError {
    case invalidEndpoint
    case notFound
    case justBad
    
    case unexpected(code: Int)
    
    public var description: String {
        switch self {
        case .invalidEndpoint: return "invalidEndpoint"
        case .notFound: return "not found"
        case .justBad: return "just bad"
        case .unexpected(_): return "An unexpected error occurred"
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .invalidEndpoint: return "invalidEndpoint"
        case .notFound: return "not found"
        case .justBad: return "just bad"
        case .unexpected(_): return "An unexpected error occurred"
        }
    }
}


struct EndpointFactory {
    
    // get detailed info about a specific patch
    // https://patchstorage.com/api/beta/patches/150831
    public static func getZoiaPatch(patchId: String) -> Endpoint<EndpointKinds.Get, PatchStorage.Patch> {
        return Endpoint(path: "patches/\(patchId)", queryItems: [])
    }
    
    // get list of platforms to find Zoia Platform ID
    // https://patchstorage.com/api/beta/platforms?per_page=100
    
    // https://patchstorage.com/api/beta/platforms?per_page=100
    public static func getAllPlatforms() -> Endpoint<EndpointKinds.Get, [PatchStorage.Platform]> {
        return Endpoint(path: "platforms", queryItems: [URLQueryItem(name: "per_page", value: "100")])
    }
    
    // using Zoia ID, request list of patches
    // https://patchstorage.com/api/beta/patches?per_page=100&platforms=3003
    public static func getPageOfPatches(zoiaPlatformId: String, sortBy: SortByItems, sortOrder: SortOrderItems, page: Int, pageSize: Int, categories: String?, tagsIncluded: String?, searchQuery: String?) -> Endpoint<EndpointKinds.Get, [PatchStorage.Patch]> {
		if let search = searchQuery {
			print("performing a search query = \(search)")
		} else {
			
		}
        var queryItems = [            URLQueryItem(name: "per_page", value: pageSize.description),
                                      URLQueryItem(name: "page", value: page.description),
                                      URLQueryItem(name: "platforms", value: zoiaPlatformId),
                                      URLQueryItem(name: "order", value: sortOrder.rawValue),
                                      URLQueryItem(name: "orderby", value: sortBy.rawValue),
									  URLQueryItem(name: "categories", value: searchQuery == nil ? categories : nil),
                                      URLQueryItem(name: "search", value: searchQuery),
									  URLQueryItem(name: "tags", value: searchQuery == nil ? tagsIncluded : nil)
        
        ]
        // URLSession doesn't filter nil query items - so do it manually
        queryItems = queryItems.filter({ $0.value != nil || $0.value?.isEmpty == false })
        
        return Endpoint(path: "patches", queryItems: queryItems)
    }

    
    // https://patchstorage.com/api/alpha/categories?per_page=100
    
    public static func getAllCategories() -> Endpoint<EndpointKinds.Get, [PatchStorage.GenericObject]> {
        return Endpoint(path: "categories", queryItems: [
            URLQueryItem(name: "per_page", value: "100")
        ])
    }
}

class PatchStorageAPI {
    
    var urlSession: URLSession
    var cancellable: Cancellable?
    var jsonDecoder: JSONDecoder
    var jsonEncoder: JSONEncoder
    
    static let shared = PatchStorageAPI()
    
    required init() {
        print("ZoiaLibraryInit called")
        urlSession = URLSession(configuration: .ephemeral)
        jsonDecoder = JSONDecoder()
        jsonEncoder = JSONEncoder()
        
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonDecoder.dateDecodingStrategy = .iso8601
    }
    
    // this version returns a publisher
    func getAllPlatforms() -> AnyPublisher<[PatchStorage.Platform], Error> {
        let request = EndpointFactory.getAllPlatforms().makeRequest(with: ())!
        return urlSession.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [PatchStorage.Platform].self, decoder: jsonDecoder)
            .eraseToAnyPublisher()
    }
    
    // this version makes the call and returns the platform list in a callback
    func getAllPlatforms(completion: @escaping ([PatchStorage.Platform])->Void) -> Cancellable? {
        
        guard let request = EndpointFactory.getAllPlatforms().makeRequest(with: ()) else { completion([]); return cancellable }
        cancellable = urlSession.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [PatchStorage.Platform].self, decoder: jsonDecoder)
            .eraseToAnyPublisher()
            .sink(receiveCompletion: {
                rxCompletion in
            }, receiveValue: {
                platformList in
                completion(platformList)
            })
        return cancellable
    }
    
    
    func getZoiaCategories() -> AnyPublisher<[PatchStorage.GenericObject], Error> {
        let request = EndpointFactory.getAllCategories().makeRequest(with: ())!
        return urlSession.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [PatchStorage.GenericObject].self, decoder: jsonDecoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }


    func getZoiaPatchesForPage(page: Int, sortBy: SortByItems, sortOrder: SortOrderItems, pageSize: Int, categories: Set<Int>? = nil, tagsIncluded: Set<Int>? = nil, searchQuery: String? = nil) -> AnyPublisher<[PatchStorage.Patch], Error> {
        
        //guard let categories = excludeCategories else { return getZoiaPatchesForPage(page: page, sortBy: sortBy, sortOrder: sortOrder, pageSize: pageSize) }
        let categoryList: String? = (categories == nil) || (categories?.isEmpty == true) ? nil : categories?.map{ $0.description }.joined(separator: ",")
        let tagList: String? = (tagsIncluded == nil) || (tagsIncluded?.isEmpty == true) ? nil : tagsIncluded?.map{ $0.description }.joined(separator: ",")
        let request = EndpointFactory.getPageOfPatches(zoiaPlatformId: "3003", sortBy: sortBy, sortOrder: sortOrder, page: page, pageSize: pageSize, categories: categoryList, tagsIncluded: tagList, searchQuery: searchQuery).makeRequest(with: ())!
		print("request = \(request.url?.absoluteString ?? "")")
        return urlSession.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [PatchStorage.Patch].self, decoder: jsonDecoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getZoiaPatch(patchId: Int) -> AnyPublisher<PatchStorage.Patch, Error> {
        let request = EndpointFactory.getZoiaPatch(patchId: patchId.description).makeRequest(with: ())!
        return urlSession.dataTaskPublisher(for: request)
            //.map(\.data)
                    .tryMap { (output) -> Data in
        
                        guard let response = output.response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode < 300 else {
                            print("bad server response") // debug statement
                            throw URLError(.badServerResponse)
                        }
        
                        print("got output") // debug statement
                        if let dataString = String(data: output.data, encoding: .utf8) { // debug statement
                                print("got dataString: \n\(dataString)") // debug statement
                            } // debug statement
                        return output.data
        
                    }
            .decode(type: (PatchStorage.Patch).self, decoder: jsonDecoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    
    func getZoiaPlatformId(completion: @escaping (Int?)->Void) {

        getAllPlatforms {
            platformList in
			if let zoiaPlatform = platformList.first(where: {  $0.slug == "zoia"}) {
				print("zoia platform ID = \(zoiaPlatform.id)")
			}
            completion( platformList.first(where: {$0.slug == "zoia"})?.id )
        }
    }
}

/*
 //			.tryMap { (output) -> Data in
 //				guard let response = output.response as? HTTPURLResponse else {
 //					print("bad server response") // debug statement
 //
 //					throw URLError(.badServerResponse)
 //				}
 //				if response.statusCode > 300 {
 //					print("response.statusCode is weird = \(response.statusCode)")
 //				}
 //				print("got output") // debug statement
 //				if let dataString = String(data: output.data, encoding: .utf8) { // debug statement
 //					print("got dataString: \n\(dataString)") // debug statement
 //				}
 //				return output.data
 //			}
 */
/*

 
 // https://patchstorage.com/api/alpha/platforms/3003
 
 
 // using Zoia ID, request list of patches
 // https://patchstorage.com/api/alpha/patches?per_page=100&platforms=3003
 
 // get detailed info about a specific patch
 // https://patchstorage.com/api/alpha/patches/150831
 api?.configureTransformer("/platforms") {
     try jsonDecoder.decode([PatchStoragePlatform].self, from: $0.content)
 }
 
 api?.configureTransformer("/patches") {
     try jsonDecoder.decode([PatchStoragePatch].self, from: $0.content)
 }
 
 api?.configureTransformer("/patches/ *") {
     try jsonDecoder.decode(PatchStoragePatch.self, from: $0.content)
 }
}

private func getAllPlatformsResource() -> Resource? {
 return api?.resource("/platforms")
     .withParam("per_page", "100")
}

private func getAllPatchesForPlatform(platformId: Int) -> Resource? {
 return api?.resource("/patches")
     .withParam("per_page", "100")
     .withParam("platforms", platformId.description)
}

private func getPatchForPlatform(patchId: Int) -> Resource? {
 return api?.resource("/patches")
     .child(patchId.description)
}
 
*/

