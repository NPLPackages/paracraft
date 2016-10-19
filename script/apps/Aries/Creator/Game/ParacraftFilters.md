# Paracraft Filters
Filters are integration points in Paracraft, which allows paracraft mod/app developers to customize the application cooperatively. 
Filters is a design pattern of input-output chains. Please see [script/ide/System/Core/Filters.lua](https://github.com/NPLPackages/main/blob/master/script/ide/System/Core/Filters.lua) for details.

## How to Use Filters In Paracraft
There is a global function called `GameLogic.GetFilters()` which returns the primary filter in Paracraft. 
One should `add_filter` before `apply_filter`, so one should call `add_filter` code as early as possible to install all filters used by your plugin, such as when Mod is initialized or application just started. 

The following example code, registered a new item.
```lua
-- register a new block item, id < 512 is internal blocks, which is not recommended to modify. 
GameLogic.GetFilters():add_filter("block_types", function(xmlRoot) 
	local blocks = commonlib.XPath.selectNode(xmlRoot, "/blocks/");
	if(blocks) then
		blocks[#blocks+1] = {name="block", attr={
			id = 512, 
			text = "Demo Item",
			name = "DemoItem",
			texture="Texture/blocks/bookshelf_three.png",
			obstruction="true",
			solid="true",
			cubeMode="true",
		}}
		LOG.std(nil, "info", "DemoItem", "a new block is registered");
	end
	return xmlRoot;
end)
```

## List of Paracraft Filters
This givens an overview of filters in paracraft. Please search the source code of paracraft for how to use these filters. 

- block related:
  - "block_type", xmlRoot: for registering new item type
  - "block_list", xmlRoot: for registering new item type in builder GUI
  - "block_types_template", xmlRoot: for registering or modify block type's template
- global:
  - "register_classes_into_sandbox_api", additionalEnv:
  - "desktop_menu", menu_items:
  - "cmd_open_url", cmd_text: 
  - "show", name, bIsShow: 
  - "hide", name: 
  - "new_item", itemStackArray, self:
  - "item_client_new_item_type_added", block_id, item:
- user input mouse and keyboard:
  - "DefaultContext", context, self.mode: getting the default scene context for user input
- file exporters:
  - "file_exported", id, filename:
  - "GetExporters", exporters: file exporters
  - "export_to_file", filename:
  - "select_exporter", id:
- world:
  - "before_generate_chunk", x, z:
  - "after_generate_chunk", x, z:
  - "load_world_info", worldInfo, node：
  - "save_world_info", worldInfo, node:
  - "OnBeforeLoadBlockRegion", true, x, y:
  - "OnSaveBlockRegion", true, region_x, region_z, "region.xml":
  - "OnLoadBlockRegion", true, x, y:
  - "OnUnLoadBlockRegion", true, x, y:
  - "worldFileChanged", msg:
   

