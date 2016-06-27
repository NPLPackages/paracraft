--[[
Title: Player Capabilities
Author(s): LiXizhi
Date: 2014/1/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerCapabilities.lua");
local PlayerCapabilities = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerCapabilities");
local capabilities = PlayerCapabilities:new();
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local PlayerCapabilities = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerCapabilities"));

-- @param x,y,z: initial real world position. 
-- @param radius: the half radius of the object. 
function PlayerCapabilities:ctor()
end

function PlayerCapabilities:Init()
	return self;
end

function PlayerCapabilities:IsCreativeMode()
	return GameMode:CanEditBlock();
end

function PlayerCapabilities:AllowEdit()
	return self.allowEdit;
end

function PlayerCapabilities:EnableEdit(bEnabled)
	self.allowEdit = bEnabled;
end

function PlayerCapabilities:LoadFromXMLNode(node)
	for _, subnode in ipairs(node) do 
		if(subnode.name == "abilities") then
			local attr = subnode.attr;
			if(attr) then
				self.flying = attr.flying == "true";
				self.canFly = attr.canFly == "true";
				self.canBuild = attr.canBuild == "true";
			end
			break;
		end
	end
end

function PlayerCapabilities:SaveToXMLNode(node)
	local attr = {};
	if(self.flying) then
		attr.flying = true;
	end
	if(self.canFly) then
		attr.canFly = true;
	end
	if(self.canBuild) then
		attr.canBuild = true;
	end
	local cnode = {name="abilities", attr=attr};
	node[#node+1] = cnode;
end