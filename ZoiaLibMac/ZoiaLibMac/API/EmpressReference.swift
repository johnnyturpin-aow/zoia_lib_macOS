// GNU GENERAL PUBLIC LICENSE
//   Version 3, 29 June 2007
//
// Copyright (c) 2022 Johnny Turpin (github.com/johnnyturpin-aow)

import Foundation
import CoreImage

typealias EmpressModuleList = [String: EmpressReference.Module]
typealias ModuleOption = [String: [IntOrString]]
typealias ModuleBlock = [String: EmpressReference.Block]

class EmpressReference {
    
    static let shared = EmpressReference()
    var factoryReference: [String] = Array(repeating: "", count: 64)
    var moduleList: EmpressModuleList = [:]


    private func loadFactoryList(completion: @escaping ()->Void) {
        if let path = Bundle.main.path(forResource: "factory_list", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                let decoder = JSONDecoder()
                //self.factoryList = try decoder.decode(FactoryList.self, from: data)
                let factoryList: FactoryList = try decoder.decode(FactoryList.self, from: data)
                
                for item in factoryList.factoryList {
                    let (_, index, shortName) = BankManager.parseZoiaFileName(filename: item)
                    // array ordered by slot for fast lookup
                    if let index = index {
                        self.factoryReference[index] = shortName ?? ""
                    }
                }
                
                completion()
            }
            catch let error {
                print(error)
                completion()
            }
        }
    }
    
    func loadModuleList(completion: @escaping ()->Void) {
        

        self.loadFactoryList {
            if let path = Bundle.main.path(forResource: "module_index_ordered", ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                    let decoder = JSONDecoder()
                    self.moduleList = try decoder.decode([String: EmpressReference.Module].self, from: data)
                    
                    // used to modify python style .json file into a statically ordered list
//                    var reordererModuleList: EmpressModuleList = [:]
//                    for (name, var module) in self.moduleList {
//                        var newblocks = module.blocks.sorted(by: { lhs, rhs in
//                            let lhs_pos = lhs.values.first?.position ?? 0
//                            let rhs_pos = rhs.values.first?.position ?? 0
//                            return lhs_pos < rhs_pos
//                        })
//                        module.blocks = newblocks
//                        reordererModuleList[name] = module
//                    }
//                    let tempPath = try AppFileManager.appSupportUrl().appendingPathComponent("fixed_module_list.json")
//                    let output = try JSONEncoder().encode(reordererModuleList)
//                    try output.write(to: tempPath)
                    
                    
                    completion()
                }
                catch let error {
                    print(error)
                    completion()
                }
            }
        }
    }
    
    struct Module: Codable {
        
        let category: String
        let cpu: Double
        let default_blocks: Int
        let description: String
        let max_blocks: Int
        let min_blocks: Int
        let name: String
        
        var blocks: [ModuleBlock]
        let options: [ModuleOption]
        let params: Int
    }
    
    struct Option: Codable {
        
    }
    
    struct Block: Codable {
        let isDefault: Bool?
        let isParam: Bool?
        let position: Int
    }
}

