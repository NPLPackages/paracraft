--[[
Title: character customization system UI face component for 3D Map System
Author(s): WangTian
Date: 2007/10/29
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/CCS/CartoonFaceComponent.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemUI/CCS/DB.lua");
local DB = Map3DSystem.UI.CCS.DB

local CartoonFaceComponent = commonlib.gettable("Map3DSystem.UI.CCS.CartoonFaceComponent")

CartoonFaceComponent.Component = nil;


--@param section: set the current section of the face component
function CartoonFaceComponent.SetFaceSection(Section)
	if(Section == "Face") then
		CartoonFaceComponent.Component = DB.CFS_FACE;
	elseif(Section == "Wrinkle") then
		CartoonFaceComponent.Component = DB.CFS_WRINKLE;
	elseif(Section == "Eye") then
		CartoonFaceComponent.Component = DB.CFS_EYE;
	elseif(Section == "Eyebrow") then
		CartoonFaceComponent.Component = DB.CFS_EYEBROW;
	elseif(Section == "Mouth") then
		CartoonFaceComponent.Component = DB.CFS_MOUTH;
	elseif(Section == "Nose") then
		CartoonFaceComponent.Component = DB.CFS_NOSE;
	elseif(Section == "Marks") then
		CartoonFaceComponent.Component = DB.CFS_MARKS;
	elseif(Section == "CharFace") then
		CartoonFaceComponent.Component = 100;
	end
end


-- get the current section of the face component
function CartoonFaceComponent.GetFaceComponentSection()
	if(CartoonFaceComponent.Component == DB.CFS_FACE) then
		return "Face";
	elseif(CartoonFaceComponent.Component == DB.CFS_WRINKLE) then
		return "Wrinkle";
	elseif(CartoonFaceComponent.Component == DB.CFS_EYE) then
		return "Eye";
	elseif(CartoonFaceComponent.Component == DB.CFS_EYEBROW) then
		return "Eyebrow";
	elseif(CartoonFaceComponent.Component == DB.CFS_MOUTH) then
		return "Mouth";
	elseif(CartoonFaceComponent.Component == DB.CFS_NOSE) then
		return "Nose";
	elseif(CartoonFaceComponent.Component == DB.CFS_MARKS) then
		return "Marks";
	elseif(CartoonFaceComponent.Component == 100) then
		return "CharFace";
	end
end

-- Function: set the face component parameters for the specific section
function CartoonFaceComponent.SetFaceComponent(SubType, value, donot_refresh)
	DB.SetFaceComponent(CartoonFaceComponent.Component, SubType, value, donot_refresh);
end