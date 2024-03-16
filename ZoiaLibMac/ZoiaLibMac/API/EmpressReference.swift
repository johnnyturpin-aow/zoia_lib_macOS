/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


import Foundation
import CoreImage

typealias EmpressModuleList = [String: EmpressReference.Module]
typealias ModuleOption = [String: [IntOrString]]
typealias ModuleBlock = [String: EmpressReference.Block]



// Factory Patches downloads
// https://patchstorage.com/wp-content/uploads/2019/05/ZOIA-FACTORY-PATCHES.zip
// https://patchstorage.com/wp-content/uploads/2021/09/ZOIA-Euroburo-Factory-Patches.zip

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
    
                    completion()
                }
                catch let error {
                    print(error)
                    completion()
                }
            }
        }
    }
	
	struct ModuleIndexModule: Codable {
		let category: String
		let cpu: Double
		let default_blocks: Int
		let description: String
		let max_blocks: Int
		let min_blocks: Int
		let name: String
		var blocks: ModuleBlock
		var options: ModuleOption
		var params: Int
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

/*
 // python code to export ModuleIndex.json in appropriate formats for swift
 

	 module_iterator = mod.copy()

	 all_modules = []
	 for index in module_iterator:
		 module = module_iterator[index]
		 #label = {index: module["name"]}
		 module_name = module["name"].lower().replace(" ","_")
		 label = 'case: {} = {}'.format(module_name, index)
		 all_modules.append(label)

 with open('/Users/jturpin/Library/Application Support/ZoiaLib/all_modules.json', 'w') as fs:
	 json.dump(all_modules, fs)



	 fixed_mod = mod.copy()

	 # loop over all root level objects (these are modules referenced using a string name - which is their index)
	 # for each module, convert the options dictionary into an ordered array
	 for index in fixed_mod:
		 ordered_options = []
		 module = fixed_mod[index]
		 opts = module["options"]
		 for opt_name, opt_value in opts.items():
			 ordered_options.append({opt_name: opt_value})
		 module["options"] = ordered_options

		 ordered_blocks = []
		 blocks = module["blocks"]
		 for block_name, block_value in blocks.items():
			 ordered_blocks.append({block_name: block_value})
		 module["blocks"] = ordered_blocks

	 
 with open('/Users/jturpin/Library/Application Support/ZoiaLib/module_index.json', 'w') as fs:
	 json.dump(fixed_mod,fs)


 */
