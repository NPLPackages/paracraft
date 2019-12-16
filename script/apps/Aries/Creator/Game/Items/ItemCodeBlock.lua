--[[
Title: ItemCodeBlock
Author(s): LiXizhi
Date: 2019/1/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCodeBlock.lua");
local ItemCodeBlock = commonlib.gettable("MyCompany.Aries.Game.Items.ItemCodeBlock");
local item_ = ItemCodeBlock:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemCodeBlock = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemCodeBlock"));

block_types.RegisterItemClass("ItemCodeBlock", ItemCodeBlock);

function ItemCodeBlock:ctor()
end

function ItemCodeBlock:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	if(ItemCodeBlock._super.TryCreate(self, itemStack, entityPlayer, x,y,z, side, data, side_region)) then
		if(itemStack) then
			local entity = EntityManager.GetBlockEntity(x,y,z);
			if(entity and entity:isa(EntityManager.EntityCode)) then
				local langConfigFile = itemStack:GetDataField("langConfigFile");
				local codeLanguageType = itemStack:GetDataField("codeLanguageType");
				if(langConfigFile) then
					entity:SetLanguageConfigFile(langConfigFile);
				end
                entity:SetCodeLanguageType(codeLanguageType);
				local nplCode = itemStack:GetDataField("nplCode");
				if(nplCode) then
					entity:SetNPLCode(nplCode);
				end
				local blockly_nplcode = itemStack:GetDataField("blockly_nplcode");
				if(blockly_nplcode) then
					entity:SetBlocklyNPLCode(blockly_nplcode);
				end
			end
		end
	end
end

-- virtual:
-- when alt key is pressed to pick a block in edit mode. 
function ItemCodeBlock:PickItemFromPosition(x,y,z)
	local itemStack = ItemCodeBlock._super.PickItemFromPosition(self, x,y,z)
	if(itemStack) then
		local data = itemStack:GetPreferredBlockData()
		if(data ~= 0) then
			if(data == 2048) then
				-- tricky: fixed picking NPL cad 2 block. 
				-- TODO: this is not a good way to implement it. Do it formally. 
				itemStack.id = block_types.names.NPLCADCodeBlock or itemStack.id;
				-- local item = ItemClient.GetItem(block_types.names.NPLCADCodeBlock);
			elseif(data == 768) then
				-- tricky: fixed picking python block. 
				-- TODO: this is not a good way to implement it. Do it formally. 
				itemStack.id = block_types.names.PyRuntimeCodeBlock or itemStack.id;
			elseif(data == 1024) then
				-- tricky: for client side execution code block
				itemStack:SetPreferredBlockData(0)
			end
		end
		return itemStack;
	end
end