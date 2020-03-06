--[[
Title: Paracraft related clipboard
Author(s): LiXizhi
Date: 2020/3/1
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Clipboard.lua");
local Clipboard = commonlib.gettable("MyCompany.Aries.Game.Common.Clipboard");
Clipboard.Save("any_type", {any_object})
local obj = Clipboard.LoadByType("any_type")
local obj_type, object = Clipboard.Load()
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Clipboard = commonlib.gettable("MyCompany.Aries.Game.Common.Clipboard");

-- save object to clipboard
function Clipboard.Save(obj_type, obj)
	if(obj_type and obj) then
		NPL.load("(gl)script/ide/LuaXML.lua");
		local root = {name="paracraft_clipboard", attr = {type = obj_type, data_type=type(obj)}}
		root[1] = type(obj) == "table" and commonlib.serialize_compact(obj) or obj;
		ParaMisc.CopyTextToClipboard(commonlib.Lua2XmlString(root))
		LOG.std(nil, "info", "Clipboard", "%s saved to clipboard", obj_type);
		return true;
	end
end

-- read clipboard by type
--@return object: where object can be table or string
function Clipboard.LoadByType(obj_type)
	local obj_type_, object = Clipboard.Load()
	if(obj_type_ == obj_type) then
		return object;
	end
end

--@return obj_type, object: where object can be table or string
-- return nil, if clipboard does not contain data
function Clipboard.Load()
	local obj_type, object;
	local clip = ParaMisc.GetTextFromClipboard();
	if(clip and clip:match("^<paracraft_clipboard")) then
		local xmlRoot = ParaXML.LuaXML_ParseString(clip)
		if(xmlRoot and not xmlRoot.name) then
			xmlRoot = xmlRoot[1]
		end
		if(xmlRoot and xmlRoot.name == "paracraft_clipboard" and xmlRoot.attr) then
			obj_type = xmlRoot.attr.type;
			local data_type = xmlRoot.attr.data_type;
			object = xmlRoot[1];
			if(data_type == "table") then
				object = NPL.LoadTableFromString(object)
			end
			return obj_type, object;
		end
	end
end

