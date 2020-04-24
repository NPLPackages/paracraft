--[[
Title: Command Item
Author(s): LiXizhi
Date: 2014/2/22
Desc: item related command
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandItem.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


Commands["name"] = {
	name="name", 
	quick_ref="/name [name#tooltip1#tooltip2]", 
	desc="give a name to the current item in hand", 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local tooltip = cmd_text:gsub("#", "\n")
			local player = EntityManager.GetPlayer();
			if(player) then
				local itemStack = player.inventory:GetItemInRightHand();
				if(itemStack) then
					local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
					BroadcastHelper.PushLabel({id=name, label = format("item %s is named %s", itemStack:GetTooltip(), tooltip), max_duration=10000, color = "0 0 0", scaling=1, bold=true, shadow=true,});
					itemStack:SetTooltip(tooltip);
					player.inventory:OnInventoryChanged();
				end
			end
		end
	end,
};

Commands["durability"] = {
	name="durability", 
	quick_ref="/durability [value]", 
	desc=[[ set item durablilty in hand
/durability			:empty to clear durability
/durability   2		:set to 2 durability
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local value;
			value, cmd_text = CmdParser.ParseInt(cmd_text)
			
			local player = EntityManager.GetPlayer();
			if(player) then
				local itemStack = player.inventory:GetItemInRightHand();
				if(itemStack) then
					itemStack:SetDurability(value);
				end
			end
		end
	end,
};

Commands["edititem"] = {
	name="edititem", 
	quick_ref="/edititem [item_id]", 
	desc=[[ edit item property 
/edititem 62			:edit grass block item. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local item_id;
			item_id, cmd_text = CmdParser.ParseBlockId(cmd_text)
			if(item_id and item_id~=0) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditItemPage.lua");
				local EditItemPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditItemPage");
				EditItemPage.ShowPage(item_id);
			end
		end
	end,
};


Commands["registeritem"] = {
	name="registeritem", 
	quick_ref="/registeritem [-alphaTestTexture] [-blendedTexture] [-light] [block_id:2000-2999] [texture] [base_block_id] ", 
	desc=[[create a new item based on an icon and block id. 
e.g.
/registeritem 2000 Texture/blocks/lapis_ore.png 234  thin plate
/registeritem 2001 Texture/blocks/items/1013_Carrot.png 115  flower
/registeritem     it will create using the inventory of fromEntity. The first slot item must be a painting, the second one is base block if any. 
/registeritem -alphaTestTexture 2002 Texture/blocks/glass_pane.png 6   transparent block emitting light
/registeritem -blendedTexture 2003 Texture/blocks/ice.png 6    alpha-blended block emitting light
/registeritem -light 2004 Texture/blocks/leaves_birch.png 86   a tree leave block emitting light
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		if(cmd_text) then

			local options, block_id, texture, base_block_id;
			options, cmd_text = CmdParser.ParseOptions(cmd_text);
			block_id, cmd_text = CmdParser.ParseInt(cmd_text);
			texture, cmd_text = CmdParser.ParseString(cmd_text);
			
			if(fromEntity and fromEntity.inventory) then
				-- first slot is texture
				local item_image = fromEntity.inventory:GetItem(1);
				if(item_image and item_image.id == block_types.names.Painting) then
					local filename = item_image:GetTooltip()
					if(filename and filename:match("png$") or filename:match("jpg$")) then
						texture = filename;
						-- second slot is base block id. 
						local item_base = fromEntity.inventory:GetItem(2);
						if(item_base) then
							base_block_id = item_base.id;
						end
					end
				end
			end

			if(texture) then
				local base_block_id_
				base_block_id_, cmd_text = CmdParser.ParseBlockId(cmd_text);
				base_block_id = base_block_id_ or base_block_id or block_types.names.Cobblestone;

				cmd_params = cmd_params or {};
				cmd_params.id = cmd_params.id or block_id;
				cmd_params.texture = cmd_params.texture or texture;
				cmd_params.base_block_id = cmd_params.base_block_id or base_block_id;
				cmd_params.value, cmd_params.target = nil, nil;

				if(options.alphaTestTexture) then
					cmd_params.transparent = true;
					cmd_params.alphaTestTexture = true;
				end
				if(options.blendedTexture) then
					cmd_params.transparent = true;
					cmd_params.blendedTexture = true;
				end
				if(options.light) then
					cmd_params.light = true;
				end

				local item = ItemClient.RegisterCustomItem(cmd_params);
				if(item) then
					local fromEntity = fromEntity or EntityManager.GetPlayer()
					if(fromEntity) then
						local x, y, z = fromEntity:GetPosition();
						-- generate an item on top of the fromEntity
						NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityItem.lua");
						local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
						local EntityItem = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityItem")
						local entity = EntityItem:new():Init(x, y+BlockEngine.blocksize*2, z,ItemStack:new():Init(item.id,1))
						entity:Attach();
					end
					--local playerEntity = EntityManager.GetPlayer();
					--if(playerEntity and playerEntity.inventory and playerEntity.inventory.SetBlockInRightHand) then
						--playerEntity.inventory:SetBlockInRightHand(item.id);
					--end
				end
			end
		end
	end,
};

Commands["virtualitem"] = {
	name="virtualitem", 
	quick_ref="/virtualitem [@playername] [add|remove|get] [item_id]", 
	desc=[[add, remove or get a certain virtual item to a given player
@param [@playername]: default to trigger entity. 
@param [add|remove|get]: 
@param item_id : item_id or name
e.g.
/virtualitem add quest1111
/virtualitem remove quest1111
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playerEntity, cmd, item_id;
		playerEntity, cmd_text = CmdParser.ParsePlayer(cmd_text, fromEntity);
		cmd, cmd_text = CmdParser.ParseString(cmd_text);
		item_id, cmd_text = CmdParser.ParseString(cmd_text);

		NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/RuleBase.lua");
		local RuleBase = commonlib.gettable("MyCompany.Aries.Game.Rules.RuleBase");

		if(item_id) then
			if(cmd == "add") then
				RuleBase:AddVirtualItemToEntity({id=item_id}, playerEntity);
			elseif(cmd == "remove") then
				RuleBase:RemoveVirtualItemFromEntity({id=item_id}, playerEntity);
			elseif(cmd == "get") then
				return RuleBase:VerifyVirtualItemByEntity({id=item_id, count=1}, playerEntity);
			end
		end
	end,
};