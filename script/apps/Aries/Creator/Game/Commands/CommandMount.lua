--[[
Title: CommandMount
Author(s): LiXizhi
Date: 2015/17/22
Desc: entity walk action
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandMount.lua");
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


Commands["mount"] = {
	name="mount", 
	quick_ref="/mount [@entityname] -target [targetname] [-radius number]", 
	desc=[[mount player or the given entity to another entity. 
@param entityname: name of the entity, if nil, it means the calling entity, such as inside the entity's inventory.  
@param targetname: if not specified, it will automatically find a nearby mountable target. 
@param radius: default to 2, only mount if the distance between two target is smaller than this. 
e.g.
/mount      :mount the player or calling entity to nearby railcars if any
/mount @p   :mount the last trigger entity or player to nearby railcars if any
/mount @test    :mount the "test" NPC to nearby railcars if any
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playerEntity;
		playerEntity, cmd_text = CmdParser.ParsePlayer(cmd_text);
		playerEntity = playerEntity or fromEntity or EntityManager.GetPlayer();

		local target;
		local radius = 2;
		local option = "";
		while (option) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option == "target") then
				target, cmd_text = CmdParser.ParseString(cmd_text);
			elseif(option == "radius") then
				radius, cmd_text = CmdParser.ParseNumber(cmd_text);
			end
		end
		if(not target) then
			local aabb = playerEntity:GetCollisionAABB():clone_from_pool();
			aabb:Expand(radius,radius,radius);
			local entities = EntityManager.GetEntitiesByAABBExcept(aabb, playerEntity);
			if(entities) then
				for _, entity in ipairs(entities) do
					if(entity:CanBeMounted()) then
						target = entity;
						break;
					end
				end
			end
		end
		if(target) then
			playerEntity:MountEntity(target);
			playerEntity:SetAnimation(0);
		else
			-- no target to mount to. 
		end
	end,
};

Commands["unmount"] = {
	name="unmount", 
	quick_ref="/mount [@entityname]", 
	desc=[[unmount player or the given entity from its currently riding entity. 
e.g.
/unmount
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playerEntity;
		playerEntity, cmd_text = CmdParser.ParsePlayer(cmd_text);
		playerEntity = playerEntity or fromEntity or EntityManager.GetPlayer();

		if(playerEntity) then
			playerEntity:MountEntity(nil);
			local bx, by, bz = playerEntity:GetBlockPos();
			playerEntity:PushOutOfBlocks(bx, by, bz);
		end
	end,
};