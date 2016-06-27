--[[
Title: Command Entity
Author(s): LiXizhi
Date: 2014/3/27
Desc: command entity
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandEntity.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/EntityAnimation.lua");
local EntityAnimation = commonlib.gettable("MyCompany.Aries.Game.Effects.EntityAnimation");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


--[[ disableinput for a given entity or block entity
/disableinput
/disableinput ~ ~ ~
/disableinput @test false
/disableinput 20000 10 20000 true
]]
Commands["disableinput"] = {
	name="disableinput", 
	quick_ref="/disableinput [@playername] [x y z] [true|false]", 
	desc="disableinput for a given entity or block entity" , 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playerEntity, x, y, z;
		playerEntity, cmd_text = CmdParser.ParsePlayer(cmd_text);
		playerEntity = playerEntity or fromEntity;

		x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
		if(x) then
			playerEntity = EntityManager.GetBlockEntity(x, y, z);
		end

		local bIsInputDisabled, cmd_text = CmdParser.ParseBool(cmd_text);
		if(bIsInputDisabled == nil) then
			bIsInputDisabled = true;
		end

		if(playerEntity) then
			playerEntity:DisableInput(bIsInputDisabled);
		end
	end,
};

-- TODO:
Commands["createentity"] = {
	name="createentity", 
	quick_ref="/createentity [class_name] [name] [x y z] [filename] [...]", 
	desc="create a new entity based on class_name. Class name should be a registered entity class. " , 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local class_name, name, x, y, z, filename;
		class_name, cmd_text = CmdParser.ParseString(cmd_text, fromEntity);
		name, cmd_text = CmdParser.ParseString(cmd_text, fromEntity);
		if(class_name and name) then
			x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
			if(not x or not y or not z) then
				x,y,z = EntityManager.GetPlayer():GetBlockPos();
			end
			-- create based on class_name
			local entity_class = EntityManager[class_name];
			if(type(entity_class) == "table" and entity_class.Create) then
				local entity = entity_class:Create({bx=x,by=y,bz=z,});
				EntityManager.AddObject(entity);
			end
		end
	end,
};


Commands["createmob"] = {
	name="createmob", 
	quick_ref="/createmob name [x y z] [filename] [...]", 
	desc=[[create a mob entity. e.g.
/createmob test chicken.x
@param filename can be relative to world directory
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local name, x, y, z, filename;
		name, cmd_text = CmdParser.ParseString(cmd_text, fromEntity);
		if(name) then
			x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
			if(not x or not y or not z) then
				x,y,z = EntityManager.GetPlayer():GetBlockPos();
				x = x + 1;
			end
			filename, cmd_text = CmdParser.ParseString(cmd_text, fromEntity);
			NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMob.lua");
			local EntityMob = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMob");
			local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
			local item = ItemClient.GetItemByName("simple_mob");
			if(item) then
				local entity = EntityManager.EntityMob:Create({bx=x, by=y, bz=z, item_id = item.id, assetfile = filename});
				if(entity) then
					if(filename) then
						entity:SetModelFile(filename);
					end
					EntityManager.AddObject(entity);
				else
					GameLogic.AddBBS(nil, "can not create mob here");
				end
			else
				GameLogic.AddBBS(nil, "item simple_mob not found");
			end
		else
			GameLogic.AddBBS(nil, "create mob needs a name");
		end
	end,
};

