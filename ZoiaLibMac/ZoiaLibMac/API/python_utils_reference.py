/*---------------------------------------------------------------------------------------------
 *  Copyright © Johnny Turpin (github.com/johnnyturpin-aow). All rights reserved.
 *  GNU GENERAL PUBLIC LICENSE
 *  Version 3, 29 June 2007
 *--------------------------------------------------------------------------------------------*/


/// The following utils are python code that is needed to 'convert' the JSON used by
/// the python/qt zoia-lib app to usable (valid) json that can be parsed with the Swift
/// json parsers - theses snippets are meant to be inserted into zoia_lib/backend/patch_binary.py
/// immediately following the loading of ModuleIndex.json:
///
/// with open(meipass("zoia_lib/common/schemas/ModuleIndex.json")) as f:
/// 	mod = json.load(f)
///
///
///
///
///
///
///

/// The following snippet is need because python supports dereferencing of dictionaries using an ordered naming convention
/// i.e., in python, the value referenced by dict[0][1] - would return the second item in the object or array of the
/// first item in the 'dict' dictionary.
///
/// This inherent "ordering" of dictionaries is not supported by Swift (or many other langauges) - as Swift is very specific that
/// dictionaries are not ordered and can only be referenced by their keys.
///
/// So what this does is read in the ModuleIndex.json file and create a new json file that uses an array
/// to store the "options" of each Module - as json arrays parsed by Swift are guaranteed to be ordered


 fixed_mod = mod.copy()


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

 with open('module_index.json', 'w') as fs:
	json.dump(fixed_mod, fs)



/// The following code snippet is used to create a Swift based enum which is used to store
/// a list of all the modules used in ZOIA patches as referenced by the module # defined by Empress
///

	print("loading ModuleIndex.json")
	module_iterator = mod.copy()

	all_modules = []
	for index in module_iterator:
		module = module_iterator[index]
		# label = {index: module["name"]}
		module_name = module["name"].lower().replace(" ", "_")
		label = 'case: {} = {}'.format(module_name, index)
		all_modules.append(label)


	with open('all_modules.json', 'w') as fs:
		json.dump(all_modules, fs)

