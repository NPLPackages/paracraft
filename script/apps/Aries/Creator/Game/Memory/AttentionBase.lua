--[[
Title: Attention base class
Author(s): LiXizhi
Date: 2017/6/3
Desc: attention is a meta object in the vision context. It is not the object itself, 
but contains a snapshot of recent events of a single object. 
This class is the base class for all kinds of concepts that can have attention in the vision. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/AttentionBase.lua");
local AttentionBase = commonlib.gettable("MyCompany.Aries.Game.Memory.AttentionBase");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local AttentionBase = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Memory.AttentionBase"));
AttentionBase:Property("Name", "AttentionBase");

-- how much attention this object has in the vision context. 
-- the higher the more attention the object get. This value also decays when no memory clip matches it in recent vision context
AttentionBase:Property({"power", 0});
-- maximum power that an object can get. 
AttentionBase:Property({"max_power", 100});
-- power value to add when activated
AttentionBase:Property({"activation_power", 7});

function AttentionBase:ctor()
end

function AttentionBase:HasAttention()
	return self.power >= 0;
end

function AttentionBase:Activate()
	self:AddPower(self.activation_power);
end


function AttentionBase:AddPower(power)
	self.power = math.min(self.max_power, self.power + power);
end

function AttentionBase:SetPower(power)
	self.power = math.min(self.max_power, power);
end

-- grayscale-to-red-green-blue-color 
-- This produces to the "cold-to-hot" color ramp.
-- @param v: any value v in range vmin, vmax.
-- @param vmin, vmax:  range of v
-- return r,g,b in 0,1 ranges
function AttentionBase:ConvertFloatToColor(v, vmin, vmax)
	local r, g, b = 1.0, 1.0, 1.0; -- white
	local dv;
	if(v < vmin) then
		v = vmin;
	end
	if(v > vmax) then
		v = vmax;
	end
	dv = vmax - vmin;

	if(v <(vmin + 0.25 * dv)) then
		r = 0;
		g = 4*(v - vmin) / dv;
	elseif(v <(vmin + 0.5 * dv))then
		r = 0;
		b = 1 + 4*(vmin + 0.25 * dv - v) / dv;
	elseif(v <(vmin + 0.75 * dv)) then
		r = 4*(v - vmin - 0.5 * dv) / dv;
		b = 0;
	else
		g = 1 + 4*(vmin + 0.75 * dv - v) / dv;
		b = 0;
	end
	return r, g, b;
end

-- @return DWORD of RGB
function AttentionBase:GetPowerColor()
	local r, g, b = self:ConvertFloatToColor(self.power, 0, self.max_power);
	return math.floor(r * 0xff0000 + g * 0xff00 + b + 0xff000000);
end


-- virtual function
function AttentionBase:Draw(painter, visionContext)
end