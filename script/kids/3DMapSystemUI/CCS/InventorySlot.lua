--[[
Title: character customization system UI inventory slot for 3D Map System
Author(s): WangTian
Date: 2007/10/29, refactored 2008.6.12 lxz
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/CCS/InventorySlot.lua");
local InventorySlot = Map3DSystem.UI.CCS.InventorySlot
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemUI/CCS/DB.lua");
local DB = commonlib.gettable("Map3DSystem.UI.CCS.DB");

local InventorySlot = commonlib.gettable("Map3DSystem.UI.CCS.InventorySlot");

--@param section: this is solely for debugging purposes. to make this class universal to all inventory slots
InventorySlot.Component = nil;

--@param section: set the current item slot of the inventory
function InventorySlot.SetInventorySlot(Section)
	if(Section == "Head") then
		InventorySlot.Component = DB.CS_HEAD;
	elseif(Section == "Neck") then
		InventorySlot.Component = DB.CS_NECK;
	elseif(Section == "Shoulder") then
		InventorySlot.Component = DB.CS_SHOULDER;
	elseif(Section == "Boots") then
		InventorySlot.Component = DB.CS_BOOTS;
	elseif(Section == "Belt") then
		InventorySlot.Component = DB.CS_BELT;
	elseif(Section == "Shirt") then
		InventorySlot.Component = DB.CS_SHIRT;
	elseif(Section == "Pants") then
		InventorySlot.Component = DB.CS_PANTS;
	elseif(Section == "Chest") then
		InventorySlot.Component = DB.CS_CHEST;
	elseif(Section == "Bracers") then
		InventorySlot.Component = DB.CS_BRACERS;
	elseif(Section == "Gloves") then
		InventorySlot.Component = DB.CS_GLOVES;
	elseif(Section == "HandRight") then
		InventorySlot.Component = DB.CS_HAND_RIGHT;
	elseif(Section == "HandLeft") then
		InventorySlot.Component = DB.CS_HAND_LEFT;
	elseif(Section == "Cape") then
		InventorySlot.Component = DB.CS_CAPE;
	elseif(Section == "Tabard") then
		InventorySlot.Component = DB.CS_TABARD;
	end
end


-- get the current item slot of the inventory
function InventorySlot.GetInventorySlot()
	if(InventorySlot.Component == DB.CS_HEAD) then
		return "Head";
	elseif(InventorySlot.Component == DB.CS_NECK) then
		return "Neck";
	elseif(InventorySlot.Component == DB.CS_SHOULDER) then
		return "Shoulder";
	elseif(InventorySlot.Component == DB.CS_BOOTS) then
		return "Boots";
	elseif(InventorySlot.Component == DB.CS_BELT) then
		return "Belt";
	elseif(InventorySlot.Component == DB.CS_SHIRT) then
		return "Shirt";
	elseif(InventorySlot.Component == DB.CS_PANTS) then
		return "Pants";
	elseif(InventorySlot.Component == DB.CS_CHEST) then
		return "Chest";
	elseif(InventorySlot.Component == DB.CS_BRACERS) then
		return "Bracers";
	elseif(InventorySlot.Component == DB.CS_GLOVES) then
		return "Gloves";
	elseif(InventorySlot.Component == DB.CS_HAND_RIGHT) then
		return "HandRight";
	elseif(InventorySlot.Component == DB.CS_HAND_LEFT) then
		return "HandLeft";
	elseif(InventorySlot.Component == DB.CS_CAPE) then
		return "Cape";
	elseif(InventorySlot.Component == DB.CS_TABARD) then
		return "Tabard";
	end
end

-- Function: set the inventory slot parameters for the specific item slot
function InventorySlot.MountInventorySlot(SubType, value, donot_refresh)
	--DB.SetFaceComponent(InventorySlot.Component, SubType, value, donot_refresh);
end