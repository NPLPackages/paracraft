--[[
Title: div element
Author(s): chenjinxian
Date: 2020/8/6
Desc: kp:usertag element
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/pe_mc_slot.lua");
MyCompany.Aries.Game.mcml2.pe_mc_slot:RegisterAs("pe:mc_slot");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/ItemSlot.lua");
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemSlot = commonlib.gettable("MyCompany.Aries.Game.mcml2.ItemSlot");

local pe_mc_slot = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("MyCompany.Aries.Game.mcml2.pe_mc_slot"));
pe_mc_slot:Property({"class_name", "pe:mc_slot"});

function pe_mc_slot:ctor()
end

function pe_mc_slot:LoadComponent(parentElem, parentLayout, style)
	local _this = self.control;
	if (not _this) then
		_this = ItemSlot:new():init(parentElem);
		self:SetControl(_this);
	else
		_this:SetParent(parentElem);
	end

	pe_mc_slot._super.LoadComponent(self, _this, parentLayout, style);
end

function pe_mc_slot:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
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
				LOG.std(nil, "warn", "pe_mc_slot_v2", "no slot defined. ")
			end
		else
			LOG.std(nil, "warn", "pe_mc_slot_v2", "no container view defined. ")
			local block_id = self:GetNumber("blockId");
			local agent_name = self:GetAttributeWithCode("agentName", nil, true);
			_this:SetBlockId(block_id, agent_name);
		end
	end

	pe_mc_slot._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)	
end

function pe_mc_slot:OnBeforeChildLayout(layout)
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
function pe_mc_slot:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
	end
end
