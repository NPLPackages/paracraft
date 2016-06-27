--[[
Title: property
Author(s): LiXizhi
Date: 2014/1/29
Desc: property command 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandProperty.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ObjectPath.lua");
local ObjectPath = commonlib.gettable("System.Core.ObjectPath")
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


local allowed_root_names = {
	all = true, scene=true, npl=true, asset=true, gui=true
}

local paths = {
	ParaEngine = "/all",
	BlockWorldClient = "-scene-1_1",
}
-- well known property name to its object path, just in case object path is not specified
local name_to_objpath = {
	["WindowText"] = paths.ParaEngine,
	["AsyncChunkMode"] = paths.BlockWorldClient,
	["UseAsyncLoadWorld"] = paths.BlockWorldClient,
	["MaxBufferRebuildPerTick_FarChunk"] = paths.BlockWorldClient,
	["MaxBufferRebuildPerTick"] = paths.BlockWorldClient,
}

Commands["property"] = {
	name="property", 
	quick_ref="/property [set|get] [-objPath] name value", 
	mode_deny = "",
	mode_allow = "",
	desc=[[set engine attribute value by name. 
@param set|get: default to set property. 
@param objPath: attribute model path. if not specified, we will search for name in major places. 
please see NPL code wiki (F11)->View Menu->Object Browser for possible obj paths.
for security reasons, only all, scene, gui, asset, npl can be modified
Examples: 
/property -scene-1_1 MaxBufferRebuildPerTick_FarChunk  100
/tip $(property get -all WindowText)
/property set -all WindowText helloworld
/property WindowText helloworld short cut
/property AsyncChunkMode false
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local set_get, objPath, name, value;
		bAsyncMode, cmd_text = CmdParser.ParseBool(cmd_text);
		name, cmd_text = CmdParser.ParseString(cmd_text);
		if(name == "set" or name == "get") then
			set_get = name;
			name, cmd_text = CmdParser.ParseString(cmd_text);
		else
			-- default to set
			set_get = "set"; 
		end

		if(name:match("^[/%-]")) then
			objPath = name;
			name, cmd_text = CmdParser.ParseString(cmd_text);
		end

		if(name) then
			if(not objPath) then
				objPath = name_to_objpath[name] or "-scene-1_1";
			end
			objPath = objPath:gsub("-", "/");

			local root_name = objPath:match("^/(%w+)")
			if(allowed_root_names[root_name or ""]) then
				local path = ObjectPath:new():init(objPath);
				if(path) then
					if(set_get == "get") then
						value = path:GetFieldStr(name);
						return value;
					else
						path:SetFieldStr(name, cmd_text);
					end
				else
					GameLogic.AddBBS(nil, format(L"root path %s is not found", objPath));
				end
			else
				GameLogic.AddBBS(nil, L"root object path is not allowed");
			end
		end
	end,
};

