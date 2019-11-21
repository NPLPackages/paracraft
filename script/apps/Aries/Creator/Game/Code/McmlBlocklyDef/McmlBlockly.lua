--[[
Title: McmlBlockly
Author(s): LiXizhi
Date: 2019/10/28
Desc: language configuration file for McmlBlockly
use the lib:
-------------------------------------------------------
local langConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/McmlBlockly.lua");
-------------------------------------------------------
]]
local McmlBlockly = NPL.export();

local all_cmds = {}

local default_categories = {
{name = "McmlControls", text = L"控件", colour="#0078d7", },
{name = "McmlAttrs", text = L"属性" , colour="#7abb55", },
{name = "McmlStyles", text = L"样式", colour="#764bcc", },
{name = "McmlData", text = L"数据", colour="#459197", },
};

local is_installed = false;
function McmlBlockly.AppendAll()
	if(is_installed)then
		return
	end
	is_installed = true;
	
	local all_source_cmds = {
		NPL.load("./McmlBlocklyDef_Controls.lua"),
		NPL.load("./McmlBlocklyDef_Attrs.lua"),
		NPL.load("./McmlBlocklyDef_Styles.lua"),
		NPL.load("./McmlBlocklyDef_Data.lua"),
	}
	for k,v in ipairs(all_source_cmds) do
		McmlBlockly.AppendDefinitions(v);
	end
end

function McmlBlockly.AppendDefinitions(source)
	if(source)then
		for k,v in ipairs(source) do
			table.insert(all_cmds,v);
		end
	end
end
-- public:
function McmlBlockly.GetCategoryButtons()
	return default_categories;
end

-- public:
function McmlBlockly.GetAllCmds()
	McmlBlockly.AppendAll();
	return all_cmds;
end

