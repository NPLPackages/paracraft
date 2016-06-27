--[[
Title: BaseSelector
Author(s): LiXizhi
Date: 2014/7/6
Desc: base class for selector. like ScreenRectSelector
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/BaseSelector.lua");
local BaseSelector = commonlib.gettable("MyCompany.Aries.Game.GUI.Selectors.BaseSelector");
-------------------------------------------------------
]]
local BaseSelector = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.GUI.Selectors.BaseSelector"));

function BaseSelector:ctor()
end

function BaseSelector:Init()
	return self;
end

-- virtual function:
function BaseSelector:BeginSelect(callbackFunc)
end

-- virtual function:
-- return the mode: "selected" "none" nil
function BaseSelector:OnUpdate()
	return;
end

