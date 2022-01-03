--[[
Title: Rendering block in an entity's hand
Author(s): LiXizhi
Date: 2014/4/8
Desc: common functions to render a block in an entity's hand such as EntityPlayer or EntityNPC
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/BlockInEntityHand.lua");
local BlockInEntityHand = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockInEntityHand");
BlockInEntityHand.RefreshRightHand(entity, itemStack)
-------------------------------------------------------
]]
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local BlockInEntityHand = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockInEntityHand");

local iconModel = "model/blockworld/IconModel/IconModel_32x32.x"
local iconModel16 = "model/blockworld/IconModel/IconModel_16x16.x"
local iconChar32 = "model/blockworld/IconModel/IconChar_32x32.x"
local iconChar16 = "model/blockworld/IconModel/IconChar_16x16.x"

local modelScalings = {
	["default"] = 0.4,
	[iconModel] = 1,
	["model/blockworld/BlockModel/block_model_cross.x"] = 0.4,
	["model/blockworld/BlockModel/block_model_one.x"] = 0.3,
	["model/blockworld/BlockModel/block_model_four.x"] = 0.3,
	["model/blockworld/BlockModel/block_model_slope.x"] = 0.3,
}

local modelOffsets = {
	["default"] = {0,0.3,0},
	["model/blockworld/BlockModel/block_model_cross.x"] = {0,0,0},
	["model/blockworld/BlockModel/block_model_one.x"] = {0,0,0},
	["model/blockworld/BlockModel/block_model_four.x"] = {0,0,0},
	[iconModel] = {0,0.2,0},
	["model/blockworld/BlockModel/block_model_slope.x"] = {0,0,0},
}

local modelBootHeights = {
	["model/blockworld/BlockModel/block_model_cross.x"] = 0,
	["model/blockworld/BlockModel/block_model_one.x"] = 0,
	["model/blockworld/BlockModel/block_model_four.x"] = 0,
	[iconModel] = 0.55,
	[iconModel16] = 0.55,
	[iconChar32] = 0.55,
	[iconChar16] = 0.55,
	["model/blockworld/BlockModel/block_model_slope.x"] = 0,
}

function BlockInEntityHand.IsFilenameIconModel(filename)
	return filename == iconModel or filename == iconModel16  or filename == iconChar16;
end

-- @param entity: the parent entity such as EntityPlayer or EntityNPC. 
-- @param itemStack: the item to hold in hand or nil. usually one that is in the inventory of entity. it can also be item id
-- @param player: force using a given ParaObject as EntityPlayer's scene object. 
function BlockInEntityHand.RefreshRightHand(entity, itemStack, player)
	if(not (entity or player)) then
		return
	end
	local player = player or entity:GetInnerObject();
	if(player) then
		local meshModel;
		local model_filename;
		local texReplaceable;
		local scaling;
		local inhand_offsets;
		local bUseIcon;
		local item;

		if(not itemStack or type(itemStack) == "number") then
			if(itemStack) then
				item = ItemClient.GetItem(itemStack);
			end
		else
			item = itemStack:GetItem();
		end
		if(itemStack) then
			if(item) then
				model_filename = item:GetItemModel();	
				if(not model_filename or model_filename == "icon") then
					model_filename = iconModel;
					bUseIcon = true;
				end
				inhand_offsets = item:GetItemModelInHandOffset();
			end
			
			if(model_filename and model_filename~="") then
				scaling = (modelScalings[model_filename] or modelScalings["default"])*item:GetItemModelScaling();
				meshModel = ParaAsset.LoadStaticMesh("", model_filename);
				if(bUseIcon) then
					texReplaceable = item:GetIconObject();
					-- obj:SetField("FaceCullingDisabled", true);
				else
					local block = item:GetBlock();
					if(block) then
						texReplaceable = block:GetTextureObj();
					end
				end
			end
		end
		local nRightHandId = 1;
			
		if(meshModel) then
			if(texReplaceable) then
				player:ToCharacter():AddAttachment(meshModel, nRightHandId, -1, scaling, texReplaceable);
			else
				player:ToCharacter():AddAttachment(meshModel, nRightHandId, -1, scaling);
			end
			if(bUseIcon) then
				player:ToCharacter():GetAttachmentAttObj(nRightHandId):SetField("FaceCullingDisabled", true);
			end
			inhand_offsets = inhand_offsets or modelOffsets[model_filename or ""] or modelOffsets["default"];
			player:ToCharacter():GetAttachmentAttObj(nRightHandId):SetField("position", inhand_offsets);
		else
			player:ToCharacter():RemoveAttachment(nRightHandId);
		end
	end
end

-- @param itemStackOrItemId: the item to hold in hand or nil. usually one that is in the inventory of entity. it can also be item id
function BlockInEntityHand.TransformEntityToBlockItem(entity, itemStackOrItemId)
	local itemStack = itemStackOrItemId;
	local model_filename;
	local texReplaceable;
	local bUseIcon;
	local item;
	local bootHeight;

	if(type(itemStack) == "number") then
		item = ItemClient.GetItem(itemStack);
	else
		item = itemStack:GetItem();
	end

	if(item) then
		model_filename = item:GetItemModel();	
		if(not model_filename or model_filename == "icon") then
			model_filename = iconChar32;
			bUseIcon = true;
		end
		if(model_filename and model_filename~="") then
			entity:SetModelFile(model_filename)
			if(bUseIcon) then
				texReplaceable = item:GetIcon();
			else
				local block = item:GetBlock();
				if(block) then
					texReplaceable = block:GetTexture();
				end
			end
			bootHeight = modelBootHeights[model_filename];
			local block = item:GetBlock();
			if(block and block.customBlockModel) then
				bootHeight = bootHeight or BlockEngine.blocksize*0.5;
			end
		end
		entity:SetScaling(bUseIcon and 1 or BlockEngine.blocksize)
		entity:SetSkin(texReplaceable)
		entity:SetBootHeight(bootHeight or 0)
	end
end

--@param itemId: custom character item id
function BlockInEntityHand.TransformEntityToCustomCharItem(entity, itemId)
	local item = CustomCharItems:GetItemInCategoryById(itemId)
	if(item and item.icon) then
		local model_filename = iconChar32;
		entity:SetModelFile(model_filename)
		entity:SetSkin(item.icon)
		local bootHeight = modelBootHeights[model_filename];
		entity:SetBootHeight(bootHeight or 0)
	end
end
