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

function ItemCodeBlock:CompareItems(left, right)
	if(ItemCodeBlock._super.CompareItems(self, left, right) and left and right) then
		return (left:GetDataField("nplCode") == right:GetDataField("nplCode")) and (left:GetDataField("langConfigFile") == right:GetDataField("langConfigFile"));
	else
		return false;
	end
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
				local displayName = itemStack:GetDataField("displayname");
				if(displayName) then
					entity:SetDisplayName(displayName)
				end

				if(nplCode or blockly_nplcode) then
					entity:AutoCreateMovieEntity();
				end
			end
		end
		return true;
	end
end

-- virtual:
-- when alt key is pressed to pick a block in edit mode. 
function ItemCodeBlock:PickItemFromPosition(x,y,z)
	local itemStack = ItemCodeBlock._super.PickItemFromPosition(self, x,y,z)
	if(itemStack) then
		local entityCode = EntityManager.GetBlockEntity(x, y, z)
		if(entityCode and entityCode.GetLanguageConfigFile) then
			local lang = entityCode:GetLanguageConfigFile();
			if(lang and lang ~= "" and lang ~= "npl") then
				if(not itemStack:GetDataField("langConfigFile")) then
					itemStack:SetDataField("langConfigFile", lang);
				end
			end
		end
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
			elseif(data == 1280) then
				-- tricky: fixed picking haqi block. 
				itemStack.id = block_types.names.HaqiCodeBlock or itemStack.id;
			elseif(data == 1024) then
				-- tricky: for client side execution code block
				itemStack:SetPreferredBlockData(0)
			end
		end
		return itemStack;
	end
end

local displayMap = { npl_blockpen = "pen", npl_teacher = "Teacher"}
function ItemCodeBlock:GetLangIconDisplayText(langName)
	return displayMap[langName or ""];
end

local tooltipMap = { 
	npl_blockpen = L"画笔",
	npl_micro_robot = L"机器人",
	npl_cad = L"计算机辅助设计",
	npl_python = L"Python",
	npl_teacher = L"教师",
}
function ItemCodeBlock:GetLangTooltipText(langName)
	return tooltipMap[langName or ""] or langName;
end


-- virtual: draw icon with given size at current position (0,0)
-- this function is only called when IsOwnerDrawIcon property is true. 
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemCodeBlock:DrawIcon(painter, width, height, itemStack)
	ItemCodeBlock._super.DrawIcon(self, painter, width, height, itemStack)
	if(itemStack) then
		local lang = itemStack:GetDataField("langConfigFile")
		local text = self:GetLangIconDisplayText(lang)
		if(text) then
			painter:DrawText(0, height-15, width-1, 15, text, 0x122);
		end
	end
end

function ItemCodeBlock:GetTooltipFromItemStack(itemStack)
	local text = ItemCodeBlock._super.GetTooltipFromItemStack(self, itemStack)
	if(itemStack) then
		local lang = itemStack:GetDataField("langConfigFile")
		if(lang) then
			local tip = self:GetLangTooltipText(lang)
			if(tip) then
				text = (text or "").." "..tip;
			end
		end
	end
	return text;
end