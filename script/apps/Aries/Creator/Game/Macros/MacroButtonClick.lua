--[[
Title: Macro Button Click
Author(s): LiXizhi
Date: 2021/1/4
Desc: a macro for the clicking of a named button in GUI. 

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Macro.lua");
local Macro = commonlib.gettable("MyCompany.Aries.Game.Macro");
-------------------------------------------------------
]]
-------------------------------------
-- single Macro base
-------------------------------------
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")

--@param btnName: button name
--@param mouse_button: "left", "right", default to "left"
function Macros.ButtonClick(btnName, mouse_button)
	local obj = ParaUI.GetUIObject(btnName)
	if(obj and obj:IsValid()) then
		__onuievent__(obj.id, "onclick");
	end
end





