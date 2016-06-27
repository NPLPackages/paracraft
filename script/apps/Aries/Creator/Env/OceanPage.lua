--[[
Title: Environment Ocean page
Author(s): LiXizhi
Date: 2010/1/26
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Env/OceanPage.lua");
------------------------------------------------------------
]]

local OceanPage = commonlib.gettable("MyCompany.Aries.Creator.OceanPage")

-- called to init page
function OceanPage.OnInit()
	local self = OceanPage;
	self.ClearDataBind();
	local Page = document:GetPageCtrl();
	self.page = Page;
	local att = ParaScene.GetAttributeObjectOcean();
	if(att~=nil) then
		-- update Ocean color UI
		local color = att:GetField("OceanColor", {1, 1, 1});
		Page:SetNodeValue("OceanColorpicker", string.format("%d %d %d", color[1]*255, color[2]*255, color[3]*255));
	end	
end

------------------------
-- page events
------------------------

-- called when the Ocean color changes
function OceanPage.OnOceanColorChanged(r,g,b)
	local self = OceanPage;
	if(r and g and b) then
		r = r/255;
		g = g/255;
		b = b/255;
		Map3DSystem.SendMessage_env({type = Map3DSystem.msg.OCEAN_SET_WATER, r = r, g = g, b = b,})
		
		if(self.bindingContext and self.bindTarget)then
			self.bindTarget.R = r;
			self.bindTarget.G = g;
			self.bindTarget.B = b;
			self.bindTarget.Color = string.format("%d %d %d", r, g, b)
		end
	end
end

--[[ set the current water level by the current player's position plus the offset.
@param fOffset: offset
@param bEnable: true to enable water, false to disable. 
]]
function OceanPage.WaterLevel(fOffset, bEnable)
	local self = OceanPage;
	fOffset = tonumber(fOffset)
	if(type(bEnable) == "string") then
		bEnable = (bEnable=="true");
	end
	local height;
	local player = ParaScene.GetPlayer();
	if (player:IsValid() == true) then
		local x,y,z = player:GetPosition();
		if(fOffset ~= 0) then
			y = ParaScene.GetGlobalWaterLevel();
		end
		height = y+fOffset;
		
		Map3DSystem.SendMessage_env({type = Map3DSystem.msg.OCEAN_SET_WATER, height = height, bEnable = bEnable})
		
		if(self.bindingContext and self.bindTarget)then
			self.bindTarget.WaterLevel = height;
		end
	end
end

-- called when the Ocean color changes
function OceanPage.OnOceanLevelSlider(value)
	if(value) then
		local _level = ParaScene.GetGlobalWaterLevel();
		local delta = -value - _level;
		OceanPage.WaterLevel(delta, true);		
	end
end
function OceanPage.DataBind(bindTarget)
	local self = OceanPage;
	if(not bindTarget or not self.page)then return; end
	
	self.bindTarget = bindTarget;
	self.bindingContext = commonlib.BindingContext:new();	
	self.bindingContext:AddBinding(bindTarget, "WaterLevel", self.page.name, commonlib.Binding.ControlTypes.MCML_node, "OceanLevel")
	self.bindingContext:AddBinding(bindTarget, "Color", self.page.name, commonlib.Binding.ControlTypes.MCML_node, "OceanColorpicker")
	self.bindingContext:UpdateDataToControls();
	
end
function OceanPage.ClearDataBind()
	local self = OceanPage;
	self.bindTarget = nil;
	self.bindingContext = nil;
end