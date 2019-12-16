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
commonlib.setfield("MyCompany.Aries.Game.Code.McmlBlockly", McmlBlockly);

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

-- custom toolbar UI's mcml on top of the code block window. return nil for default UI. 
-- return nil or a mcml string. 
function McmlBlockly.GetCustomToolbarMCML()
	McmlBlockly.toolBarMcmlText = McmlBlockly.toolBarMcmlText or string.format([[
    <div style="float:left;margin-left:5px;margin-top:7px;">
		<input type="button" value='<%%="%s"%%>' onclick="MyCompany.Aries.Game.Code.McmlBlockly.OnClickLearn" style="min-width:80px;color:#ffffff;font-size:12px;height:25px;background:url(Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png#179 89 21 21:8 8 8 8)" />
    </div>
]], L"学习HTML");
	return McmlBlockly.toolBarMcmlText;
end

function McmlBlockly.OnClickLearn()
	ParaGlobal.ShellExecute("open", L"https://github.com/tatfook/CodeBlockDemos/wiki/learn_html", "", "", 1);
end

-- public:
function McmlBlockly.GetAllCmds()
	McmlBlockly.AppendAll();
	return all_cmds;
end

