--[[
Title: ItemCodePPT
Author(s): leio
Date: 2019/11/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/NPLCAD/ItemCodePPT.lua");
local ItemCodePPT = commonlib.gettable("MyCompany.Aries.Game.Items.ItemCodePPT");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemCodePPT = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemCodePPT"));

block_types.RegisterItemClass("ItemCodePPT", ItemCodePPT);

function ItemCodePPT:ctor()
end

function ItemCodePPT:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	if (itemStack and itemStack.count == 0) then
		return;
	elseif (entityPlayer and not entityPlayer:CanPlayerEdit(x,y,z, data, itemStack)) then
		return;
	elseif (self:CanPlaceOnSide(x,y,z,side, data, side_region, entityPlayer, itemStack)) then
		local langConfigFile = "npl_ppt";
		local codeLanguageType = "ppt_xml";
		
		itemStack:SetDataField("langConfigFile", langConfigFile);
		itemStack:SetDataField("codeLanguageType", codeLanguageType);

		-- add purple color to the code block using 8bit color data
		local color8_data = (data or 0) + 0x0300; 

		if(ItemCodePPT._super.TryCreate(self, itemStack, entityPlayer, x,y,z, side, color8_data, side_region)) then
			if(itemStack) then
				local entity = EntityManager.GetBlockEntity(x,y,z);
				if(entity and entity:isa(EntityManager.EntityCode)) then

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
					local displayName = itemStack:GetDataField("displayname");
					if(displayName) then
						entity:SetDisplayName(displayName)
					end
					entity.AutoCreateMovieEntity = function()
					end
					-- if(nplCode or blockly_nplcode) then
					-- 	entity:AutoCreateMovieEntity();
					-- end
				end
			end
			return true;
		end
	end
end
