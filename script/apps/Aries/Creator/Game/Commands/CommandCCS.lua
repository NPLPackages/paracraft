--[[
Title: CCS: Character Customization System 
Author(s): LiXizhi
Date: 2014/8/7
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandCCS.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/CharGeosets.lua");
local CharGeosets = commonlib.gettable("MyCompany.Aries.Game.Common.CharGeosets");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

--[[ toggle geosets of ccs character
examples:
/ccs					change to default ccs model
/ccs -m	filename		change to a given file name
/ccs shirt 2
/ccs -g hair 1
]]
Commands["ccs"] = {
	name="ccs", 
	quick_ref="/ccs [-geoset|g|model|m] [@playername] [integer or hair|shirt|pant|boot|hand|wing|eye] [id]", 
	mode_deny = "",
	mode_allow = "",
	desc="toggle model or geoset" , 
	handler = function(cmd_name, cmd_text, cmd_params)
		local options, playerEntity;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		playerEntity = playerEntity or EntityManager.GetFocus();
		if(not playerEntity) then
			return;
		end
		if(not next(options)) then
			local part_name = CmdParser.ParseString(cmd_text);
			if(part_name and CharGeosets[part_name]) then
				options["geoset"] = true;
			end
		end
		if( options["g"] or options["geoset"]) then
			local part_name, slot_id, item_id;
			part_name, cmd_text = CmdParser.ParseString(cmd_text);
			if(part_name) then
				slot_id = CharGeosets[part_name] or tonumber(part_name);
			end
			item_id, cmd_text = CmdParser.ParseInt(cmd_text);
			if(slot_id and item_id) then
				playerEntity:SetCharacterSlot(slot_id, item_id);
			end
		elseif(options["model"] or options["m"] or not next(options)) then
			local filename;
			filename, cmd_text = CmdParser.ParseString(cmd_text);
			filename = filename or "ccs"
			filename = EntityManager.PlayerAssetFile:GetValidAssetByString(filename);
			if(filename) then
				playerEntity:SetMainAssetPath(filename);
				if(not System.options.mc and playerEntity:isa(EntityManager.EntityPlayer)) then
					playerEntity:SetScaling(1);
				end
				playerEntity:SetCharacterSlot(CharGeosets["shirt"], 1);
			end
		end
	end,
};
