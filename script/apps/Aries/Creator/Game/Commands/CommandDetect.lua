--[[
Title: detect
Author(s): LiXizhi
Date: 2016/1/13
Desc: detect command 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandDetect.lua");
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

Commands["detect"] = {
	name="detect", 
	quick_ref="/detect [entity_name] [-p x y z (dx dy dz)] [-r radius]", 
	desc=[[detect if given entity_name entered the given region
@param entity_name: name of the entity, if not specified it means the players
@param -p x y z (dx dy dz): specify a aabb region to detect. please note, if dx dy dz is not specified, it will detect
a single point or a sphere region if -r is specified. 
@param -r radius: specify the radius if -p is a point. 
@return true if entity exist or false if not. 
Examples: 
/detect *
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

