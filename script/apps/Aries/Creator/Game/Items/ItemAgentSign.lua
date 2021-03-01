--[[
Title: ItemAgentSign
Author(s): LiXizhi
Date: 2021/2/17
Desc: Agent sign block is a signature block for describing all scene blocks connected to it. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemAgentSign.lua");
local ItemAgentSign = commonlib.gettable("MyCompany.Aries.Game.Items.ItemAgentSign");
local item = ItemAgentSign:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemAgentSign = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemAgentSign"));

block_types.RegisterItemClass("ItemAgentSign", ItemAgentSign);

function ItemAgentSign:PickItemFromPosition(x,y,z)
	local entity = self:GetBlock():GetBlockEntity(x,y,z);
	if(entity) then
		if(entity.cmd and entity.cmd~="") then
			local itemStack = ItemStack:new():Init(self.id, 1);
			-- transfer filename from entity to item stack. 
			itemStack:SetTooltip(entity.cmd);
			itemStack:SetDataField("agentPackageName", entity:GetAgentName());
			itemStack:SetDataField("agentPackageVersion", entity:GetVersion());
			itemStack:SetDataField("agentDependencies", entity:GetAgentDependencies());
			itemStack:SetDataField("agentExternalFiles", entity:GetAgentExternalFiles());
			itemStack:SetDataField("agentUrl", entity:GetAgentUrl());
			itemStack:SetDataField("isGlobal", entity:IsGlobal());
			return itemStack;
		end
	end
	return ItemAgentSign._super.PickItemFromPosition(self, x,y,z);
end

-- return true if items are the same. 
-- @param left, right: type of ItemStack or nil. 
function ItemAgentSign:CompareItems(left, right)
	if(ItemAgentSign._super.CompareItems(self, left, right)) then
		if(left and right and left:GetDataField("agentPackageName") == right:GetDataField("agentPackageName")) then
			return true;
		end
	end
end


function ItemAgentSign:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	local text = itemStack:GetDataField("tooltip");

	local res = ItemAgentSign._super.TryCreate(self, itemStack, entityPlayer, x,y,z, side, data, side_region);
	if(res and text and text~="") then
		local entity = self:GetBlock():GetBlockEntity(x,y,z);
		if(entity and entity:GetBlockId() == self.id) then
			entity.cmd = text;
			entity:SetAgentName(itemStack:GetDataField("agentPackageName"))
			entity:SetVersion(itemStack:GetDataField("agentPackageVersion"))
			entity:SetAgentDependencies(itemStack:GetDataField("agentDependencies"))
			entity:SetAgentExternalFiles(itemStack:GetDataField("agentExternalFiles"))
			entity:SetAgentUrl(itemStack:GetDataField("agentUrl"))
			entity:SetGlobal(itemStack:GetDataField("isGlobal"))
			entity:Refresh();
			commonlib.TimerManager.SetTimeout(function()  
				entity:LoadFromAgentFile();
			end, 10)
		end
	end
	return res;
end
