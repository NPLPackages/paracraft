--[[
Title: pe:mc_block element in mcml2
Author(s): lixizhi
Date: 2021/12/14
Desc: pe:mc_block element
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/pe_mc_block.lua");
MyCompany.Aries.Game.mcml2.pe_mc_block:RegisterAs("pe:mc_block");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/ItemSlot.lua");
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local ItemSlot = commonlib.gettable("MyCompany.Aries.Game.mcml2.ItemSlot");

local pe_mc_block = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("MyCompany.Aries.Game.mcml2.pe_mc_block"));
pe_mc_block:Property({"class_name", "pe:mc_slot"});

function pe_mc_block:ctor()
end

function pe_mc_block:LoadComponent(parentElem, parentLayout, style)
	local _this = self.control;
	if (not _this) then
		_this = ItemSlot:new():init(parentElem);
		self:SetControl(_this);
	else
		_this:SetParent(parentElem);
	end

	pe_mc_block._super.LoadComponent(self, _this, parentLayout, style);
end

function pe_mc_block:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	local _this = self.control;
	if(_this) then
		local contView = self:GetAttributeWithCode("ContainerView", nil, true) or EntityManager.GetPlayer():GetInventoryView();
		local bagpos = self:GetAttributeWithCode("bagpos", nil, true);

		if(bagpos and contView) then
			bagpos = tonumber(bagpos);
			local slot = contView:GetSlot(bagpos);
			if(slot) then
				_this:SetSlot(slot);
			else
				LOG.std(nil, "warn", "pe_mc_block_v2", "no slot defined. ")
			end
		else
			LOG.std(nil, "warn", "pe_mc_block_v2", "no container view defined. ")
			local block_id = self:GetNumber("blockId");
			block_id = block_id or self:GetAttributeWithCode("block_id", nil, true);
			local agent_name = self:GetAttributeWithCode("agentName", nil, true);
			_this:SetBlockId(block_id, agent_name);

			local tooltip = self:GetAttributeWithCode("tooltip", nil, true)
			if(not tooltip and block_id) then
				local block_item = ItemClient.GetItem(block_id);
				if(block_item) then
					tooltip = block_item:GetTooltip();
				end
			end
			_this:SetTooltip(tooltip);
		end
	end

	pe_mc_block._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)	
end

function pe_mc_block:OnBeforeChildLayout(layout)
	if(#self ~= 0) then
		local myLayout = layout:new();
		local css = self:GetStyle();
		local width, height = layout:GetPreferredSize();
		local padding_left, padding_top = css:padding_left(),css:padding_top();
		myLayout:reset(padding_left,padding_top,width+padding_left, height+padding_top);
		self:UpdateChildLayout(myLayout);
		width, height = myLayout:GetUsedSize();
		width = width - padding_left;
		height = height - padding_top;
		layout:AddObject(width, height);
	end
	return true;
end

-- virtual function: 
-- after child node layout is updated
function pe_mc_block:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
	end
end
