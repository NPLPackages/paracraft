--[[
Title: Actor entity animated by code block
Author(s): LiXizhi
Date: 2018/5/31
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/EntityCodeActor.lua");
local EntityCodeActor = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCodeActor")
local entity = MyCompany.Aries.Game.EntityManager.EntityCodeActor:new({x,y,z,radius});
entity:Attach();
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNPC"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCodeActor"));

-- class name
Entity.class_name = "CodeActor";
Entity:Signal("clicked", function(mouse_button) end)

-- register class
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

function Entity:ctor()
	self:SetPersistent(false);
	self:SetDummy(true);
	self:SetCanRandomMove(false);
	self:SetStaticBlocker(true);
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	return node;
end

-- right click to show item
function Entity:OnClick(x, y, z, mouse_button)
	self:clicked(mouse_button);
	return true;
end

-- called every frame
function Entity:FrameMove(deltaTime)
	EntityManager.EntityMovable.FrameMove(self, deltaTime);
end

-- called after focus is set
function Entity:OnFocusIn()
	self.has_focus = true;
	local obj = self:GetInnerObject();
	if(obj) then
		if(obj.ToCharacter) then
			obj:ToCharacter():SetFocus();
		end
	end
	self:focusIn();
end

-- called before focus is lost
function Entity:OnFocusOut()
	self.has_focus = nil;
	self:focusOut();
end