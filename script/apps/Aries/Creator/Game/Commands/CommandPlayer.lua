--[[
Title: Command Player
Author(s): LiXizhi
Date: 2014/1/22
Desc: slash command 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandPlayer.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/EntityAnimation.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
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


Commands["clearbag"] = {
	name="clearbag", 
	quick_ref="/clearbag [@playername] [itemid] [count]", 
	desc=[[clear all or given item in the inventory of a given player
/clearbag @p   clear all 
/clearbag [item_id]   clear all items with the give id
/clearbag @p [item_id] [count]  clear [count] number of items with the give id
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not System.options.is_mcworld) then
			return;
		end
		local item_id, item_count, playerEntity, hasInputName;
		playerEntity, cmd_text, hasInputName = CmdParser.ParsePlayer(cmd_text);
		item_id,cmd_text  = CmdParser.ParseInt(cmd_text);
		item_count, cmd_text = CmdParser.ParseInt(cmd_text);
		
		playerEntity = playerEntity or (not hasInputName and EntityManager.GetPlayer());
		if(playerEntity and playerEntity.inventory) then
			if(item_id) then
				playerEntity.inventory:ClearItems(item_id, item_count);
			else
				-- clear all
				playerEntity.inventory:Clear();
			end
		end
	end,
};

Commands["give"] = {
	name="give", 
	quick_ref="/give [@playername] [item_id] [count] [serverdata]", 
	desc=[[give a certain item to a given player
@param item_id : item_id or name
@param serverdata: server data table in {}
e.g.
/give 61
/give BlockModel {tooltip="blocktemplates/1.bmax"}
/give ColorBlock 100 {color="#ff0000"}
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playerEntity, blockid, count, data, method, serverdata, hasInputName;
		playerEntity, cmd_text, hasInputName = CmdParser.ParsePlayer(cmd_text);
		blockid, cmd_text = CmdParser.ParseBlockId(cmd_text);
		count, cmd_text = CmdParser.ParseInt(cmd_text);
		serverdata, cmd_text = CmdParser.ParseServerData(cmd_text);
		if(blockid) then
			playerEntity = playerEntity or (not hasInputName and EntityManager.GetPlayer());
			if(playerEntity and playerEntity.inventory and playerEntity.inventory) then
				local item = ItemStack:new():Init(blockid, count or 1, serverdata);
				playerEntity.inventory:AddItemToInventory(item);
			end
		end
	end,
};

Commands["take"] = {
	name="take", 
	quick_ref="/take [@playername] [block] [count] [serverdata]", 
	desc=[[set a given block to the hand of the player
@param block : block id or name
@param serverdata: server data table in {}
e.g.
/take 61
/take BlockModel {tooltip="blocktemplates/1.bmax"}
/take ColorBlock 100 {color="#ff0000"}
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local playerEntity, blockid, count, data, method, serverdata, hasInputName;
		playerEntity, cmd_text, hasInputName = CmdParser.ParsePlayer(cmd_text);
		blockid, cmd_text = CmdParser.ParseBlockId(cmd_text);
		count, cmd_text = CmdParser.ParseInt(cmd_text);
		serverdata, cmd_text = CmdParser.ParseServerData(cmd_text);
		if(blockid) then
			playerEntity = playerEntity or (not hasInputName and EntityManager.GetPlayer());
			if(playerEntity and playerEntity.inventory and playerEntity.inventory) then
				local item = ItemStack:new():Init(blockid, count or 1, serverdata);
				if(playerEntity.SetBlockInRightHand) then
					playerEntity:SetBlockInRightHand(item);
				end
			end
		end
	end,
};

Commands["gravity"] = {
	name="gravity", 
	quick_ref="/gravity [@playername] [value|9.81]", 
	desc=[[gravity globally or a given player 
@param playername: @a means player, or a player name. if not specified, it means the global gravity. 
Examples: 
/gravity 9.81   set global gravity to 9.81
/gravity @a 9.81   only set the player's gravity to 9.81
/gravity @test 9.81   only set the player's gravity to 9.81
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local gravity, playerEntity, hasInputName;
		playerEntity, cmd_text, hasInputName = CmdParser.ParsePlayer(cmd_text);
		gravity, cmd_text = CmdParser.ParseInt(cmd_text);
		if(gravity) then
			if(playerEntity) then
				playerEntity:SetGravity(gravity);
			elseif(not hasInputName) then
				GameLogic.options:SetGravity(gravity);
			end
		end
	end,
};

Commands["density"] = {
	name="density", 
	quick_ref="/density [value|1.2]", 
	desc=[[density of the player
/density [value]
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local density;
		density, cmd_text = CmdParser.ParseInt(cmd_text);
		if(density) then
			GameLogic.options:SetDensity(density);
		end
	end,
};


Commands["speedscale"] = {
	name="speedscale", 
	quick_ref="/speedscale [value|1]", 
	desc=[[ speed scale of the player. 1 is original speed
/speed [value|1]
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local speed;
		speed, cmd_text = CmdParser.ParseInt(cmd_text);
		if(speed) then
			local player = EntityManager:GetFocus();
			if(player) then
				player:SetSpeedScale(speed);
			end
		end
	end,
};

Commands["viewbobbing"] = {
	name="viewbobbing", 
	quick_ref="/viewbobbing [on|off]", 
	desc="turn on/off or toggle viewbobbing" , 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		viewbobbing, cmd_text = CmdParser.ParseBool(cmd_text);
		GameLogic.options:SetViewBobbing(viewbobbing);
	end,
};


Commands["velocity"] = {
	name="velocity", 
	quick_ref="/velocity [add|set] [@playername] [~|x] [~|y] [~|z]", 
	desc=[[add or set velocity to a given entity. 
@param [add|set]: default to set. please note you can not add motion to focused entity, use set instead. 
@param x,y,z: if only one value is provided it means y. if only two values are provided it means x,y.
Examples:
/velocity set @test 1,1,1   :set speed of the test entity
/velocity add @test 1,~,~   :use ~ to retain last speed.
/velocity 1,~,~   :set current player's speed
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		if(not System.options.is_mcworld) then
			return;
		end
		local playerEntity, list, bIsAdd, hasInputName;
		-- default to set velocity
		bIsAdd, cmd_text = CmdParser.ParseText(cmd_text, "add");
		if(not bIsAdd) then
			bIsAdd, cmd_text = CmdParser.ParseText(cmd_text, "set");
			bIsAdd = nil;
		end
		playerEntity, cmd_text, hasInputName = CmdParser.ParsePlayer(cmd_text);
		playerEntity = playerEntity or (not hasInputName and EntityManager.GetPlayer());
		list, cmd_text = CmdParser.ParseNumberList(cmd_text, nil, "|,%s")
		if(list and playerEntity) then
			local x, y, z;
			if(#list == 1) then
				x,y,z = nil,list[1],nil;
			elseif(#list == 2) then
				x,y,z = list[1],nil,list[2];
			else
				x,y,z = list[1],list[2],list[3];
			end
			if(bIsAdd) then
				playerEntity:AddVelocity(x or 0,y or 0,z or 0);
			else
				playerEntity:SetVelocity(x,y,z);
			end
		end
	end,
};



Commands["move"] = {
	name="move", 
	quick_ref="/move [@playername] [x y z]", 
	desc=[[move a given player to a given block position. Similar to /tp except that it uses block position. 
/move x y z  abs position
/move ~ ~1 ~  relative position
/move home -- teleport to home   
/move [@playername] [x y z]
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		
		if(System.options.is_mcworld) then
			local playerEntity, x, y, z;
			playerEntity, cmd_text = CmdParser.ParsePlayer(cmd_text);
			
			fromEntity = fromEntity or playerEntity
			x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
			if(not x) then
				local location;
				location, cmd_text = CmdParser.ParseString(cmd_text);
				if(location == "home") then
					x,y,z = GameLogic.GetHomePosition();
					x,y,z = BlockEngine:block(x,y+0.1,z);
				end
			end
			if( not x and fromEntity) then
				x, y, z = fromEntity:GetBlockPos();
			end

			if(x and y and z and playerEntity) then
				playerEntity:TeleportToBlockPos(x,y,z);
			end
		end
	end,
};

Commands["speeddecay"] = {
	name="speeddecay", 
	quick_ref="/speeddecay [@playername] [surface_decay] [air_decay]", 
	desc=[[speed decay when block is on ground or in air
@param surface_decay:  [0,1]. 0 means no speed lost, 1 will lost all speed.  default to 0.5
Examples:
/speeddecay @p 0.1
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		if(not System.options.is_mcworld) then
			return;
		end

		local playerEntity, list, hasInputName;
		-- default to add velocity
		playerEntity, cmd_text, hasInputName = CmdParser.ParsePlayer(cmd_text);
		playerEntity = playerEntity or (not hasInputName and EntityManager.GetPlayer());
		list, cmd_text = CmdParser.ParseNumberList(cmd_text, nil, "|,%s")
		if(list and playerEntity) then
			local surface_decay, air_decay;
			if(#list == 1) then
				surface_decay = list[1];
			elseif(#list == 2) then
				surface_decay, air_decay = list[1],list[2];
			end
			if(surface_decay) then
				playerEntity:SetSurfaceDecay(surface_decay);
			end
			if(air_decay) then
				playerEntity:GetPhysicsObject():SetAirDecay(air_decay);
			end
		end
	end,
};

Commands["facing"] = {
	name="facing", 
	quick_ref="/facing [@playername] angle", 
	desc=[[set facing of a given player. 
/facing [@playername] angle
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playerEntity, facing, hasInputName;
		playerEntity, cmd_text, hasInputName  = CmdParser.ParsePlayer(cmd_text);
		facing, cmd_text = CmdParser.ParseInt(cmd_text);
		if(facing) then
			playerEntity = playerEntity or (not hasInputName and EntityManager.GetPlayer());
			if(playerEntity) then
				playerEntity:SetFacing(facing);
			end
		end
	end,
};

Commands["scaling"] = {
	name="scaling", 
	quick_ref="/scaling [@playername] size", 
	desc=[[set scaling of a given player. 
/scaling [@playername] size
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playerEntity, scaling, hasInputName;
		playerEntity, cmd_text, hasInputName  = CmdParser.ParsePlayer(cmd_text);
		scaling, cmd_text = CmdParser.ParseInt(cmd_text);
		if(scaling) then
			playerEntity = playerEntity or (not hasInputName and EntityManager.GetPlayer());
			if(playerEntity) then
				playerEntity:SetScaling(scaling);
			end
		end
	end,
};

Commands["tickrate"] = {
	name="tickrate", 
	quick_ref="/tickrate [@playername] rate", 
	desc=[[set how many times per second an entity need to be updated
/tickrate [@playername] rate
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playerEntity, tickrate;
		playerEntity, cmd_text  = CmdParser.ParsePlayer(cmd_text);
		tickrate, cmd_text = CmdParser.ParseInt(cmd_text);
		if(tickrate and tickrate>0) then
			playerEntity = playerEntity;
			if(playerEntity) then
				playerEntity:SetTickRate(tickrate);
			end
		end
	end,
};

Commands["anim"] = {
	name="anim", 
	quick_ref="/anim [@playername] anim_name_or_id[,anim_name_or_id ...]", 
	desc=[[play animation
@param playername: if not specified and containing entity is a biped, it is the containing entity like NPC; otherwise it is current player
if NPC run this command from its rule bag, the NPC will be animated. 
/anim [@playername] anim_name_or_id[,anim_name_or_id ...]. currently only two anim can be chained. the first one can be looping anim, which will only play once. 
/anim lie
/anim @p sit
/anim lie,0   : lie down first and then play idle 0
/anim [filename].fbx    : play any fbx or x file in current world.
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playerEntity, anims, hasInputName;
		playerEntity, cmd_text, hasInputName = CmdParser.ParsePlayer(cmd_text);
		if(not playerEntity and not hasInputName) then
			if(fromEntity and fromEntity:IsBiped()) then
				playerEntity = fromEntity;
			else
				playerEntity = EntityManager.GetFocus() or EntityManager.GetPlayer();
			end
		end
		
		anims, cmd_text = CmdParser.ParseStringList(cmd_text);
		if(anims and playerEntity) then
			if(#anims == 1) then
				local name = anims[1];
				if(type(name) == "string" and name:match("%.")) then
					name = Files.GetWorldFilePath(name);
				end
				playerEntity:SetAnimation(name);
			else
				playerEntity:SetAnimation(anims);
			end
		end
	end,
};


Commands["skin"] = {
	name="skin", 
	quick_ref="/skin [@playername] [filename]", 
	desc=[[change skin. if no filename is specified a random one is used. 
@param playername: if not specified and containing entity is a biped, it is the containing entity like NPC; otherwise it is current player
@param filename: can be relative to world directory, or "Texture/blocks/human/" or root path. It can also be preinstalled id 
/skin 1     :change current player's skin to id=1
/skin texture/blocks/1.png :change current player's skin to a file in current world directory
/skin @test 1:  change 'test' player's skin to id=1
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(GameLogic.IsSocialWorld()) then
			return
		end
		local playerEntity, hasInputName;
		playerEntity, cmd_text, hasInputName = CmdParser.ParsePlayer(cmd_text);
		if(not playerEntity and not hasInputName) then
			if(fromEntity and fromEntity:IsBiped()) then
				playerEntity = fromEntity;
			else
				playerEntity = EntityManager.GetFocus() or EntityManager.GetPlayer();
			end
		end

		if(cmd_text) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
			local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
			local skin_filename = PlayerSkins:GetSkinByString(cmd_text);
			
			if(skin_filename and playerEntity and playerEntity.SetSkin) then
				playerEntity:SetSkin(skin_filename);
			end
		end
	end,
};

Commands["/avatar"] = {
	name="avatar", 
	quick_ref="/avatar [@playername] [filename]", 
	desc=[[change current avatar model. if no filename is specified, default one is used. 
@param playername: if not specified and containing entity is a biped, it is the containing entity like NPC; otherwise it is current player
@param filename: can be relative to current world directory or one of the preinstalled ones like "actor". 
/avatar dog    : change the current player to dog avator
/avatar @test test.fbx :change 'test' player to a fbx file in current world directory. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(GameLogic.IsSocialWorld()) then
			return
		end
		local playerEntity, hasInputName;
		playerEntity, cmd_text, hasInputName  = CmdParser.ParsePlayer(cmd_text);
		if(not playerEntity and not hasInputName) then
			if(fromEntity and fromEntity:IsBiped()) then
				playerEntity = fromEntity;
			else
				playerEntity = EntityManager.GetFocus() or EntityManager.GetPlayer();
			end
		end
		if(not cmd_text or cmd_text=="") then
			cmd_text = "default";
		end
		
		if(cmd_text and playerEntity) then
			local assetfile = cmd_text;
			assetfile = EntityManager.PlayerAssetFile:GetValidAssetByString(assetfile);
			if(assetfile and assetfile~=playerEntity:GetMainAssetPath()) then
				local oldAssetFile = playerEntity:GetMainAssetPath()
				if(playerEntity.SetModelFile) then
					playerEntity:SetModelFile(old_filename);
				else
					playerEntity:SetMainAssetPath(assetfile);
				end
				-- this ensure that at least one default skin is selected
				if(playerEntity:GetSkin()) then
					playerEntity:SetSkin(nil);
				else
					playerEntity:RefreshSkin();
				end
				if(math.abs(EntityManager.PlayerAssetFile:GetDefaultScale(oldAssetFile) - playerEntity:GetScaling()) < 0.01) then
					playerEntity:SetScaling(EntityManager.PlayerAssetFile:GetDefaultScale(assetfile))
				end
			elseif(not assetfile) then
				LOG.std(nil, "warn", "cmd:avatar", "file %s not found", cmd_text or "");
			end
		end
	end,
};
