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
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local BlockInEntityHand = commonlib.gettable("MyCompany.Aries.Game.EntityManager.BlockInEntityHand");


local modelScalings = {
	["default"] = 0.4,
	["model/blockworld/IconModel/IconModel_32x32.x"] = 1,
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
	["model/blockworld/IconModel/IconModel_32x32.x"] = {0,0.2,0},
	["model/blockworld/BlockModel/block_model_slope.x"] = {0,0,0},
}

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
				local tex_replaceable;
				if(not model_filename or model_filename == "icon") then
					model_filename = "model/blockworld/IconModel/IconModel_32x32.x";
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
