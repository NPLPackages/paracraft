--[[
Title: Scene Viewport 
Author(s): LiXizhi
Date: 2021/1/28
Desc: singleton class of static method for the shared scene viewport
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/SceneViewport.lua");
local SceneViewport = commonlib.gettable("MyCompany.Aries.Game.Common.SceneViewport")
parent = SceneViewport.GetUIObject();
SceneViewport.SetVirtualMarginTop(top)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");

local SceneViewport = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.SceneViewport"))

-- when system menu is show, this value could be different. 
SceneViewport.virtualMarginTop = 0;

function SceneViewport:ctor()
	self.nIndex = self.nIndex or 1;
end

-- get the real scene viewport object
function SceneViewport.Get()
	return ViewportManager:GetSceneViewport();	
end

function SceneViewport.GetUIObject()
	if(SceneViewport.uiobject_id) then
		local _this = ParaUI.GetUIObject(SceneViewport.uiobject_id);
		if(_this:IsValid()) then
			return _this;
		end
	end
	local viewport = SceneViewport.Get()
	local _parent = viewport:GetUIObject(true);
	if(_parent) then
		local name = "scene_"
		local _this = _parent:GetChild(name)
		if(not _this:IsValid()) then
			_this = ParaUI.CreateUIObject("container", name, "_fi", 0,0, 0, 0);
			_this.background = ""
			_this:SetField("ClickThrough", true);
			_parent:AddChild(_this);
			SceneViewport.uiobject_id = _this.id;
		end
		return _this;
	end
end

-- virtual margin does not affect the real scene viewport
function SceneViewport.SetVirtualMarginTop(top)
	if(SceneViewport.virtualMarginTop ~= top) then
		SceneViewport.virtualMarginTop = top;
		local obj = SceneViewport.GetUIObject()
		if(obj) then
			obj:Reposition("_fi", 0, top, 0, 0)
		end
	end
end