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
				if(langConfigFile) then
					entity:SetLanguageConfigFile(langConfigFile);
				end
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