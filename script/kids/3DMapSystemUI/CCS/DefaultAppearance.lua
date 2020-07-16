--[[
Title: Character Customization System default appearance
Author(s): WangTian
Date: 2008/3/12
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/CCS/DefaultAppearance.lua");
-------------------------------------------------------
Desc: mount a nude CCS character with default appearance

]]
local DefaultAppearance = commonlib.gettable("Map3DSystem.UI.CCS.DefaultAppearance")
local CCS = commonlib.gettable("Map3DSystem.UI.CCS")
local DB = commonlib.gettable("Map3DSystem.DB")
local LOG = LOG;
-- mount a nude CCS character with default appearance
-- @param obj: ParaObject object
function Map3DSystem.UI.CCS.DefaultAppearance.MountDefaultAppearance(obj)
	if(obj == nil or obj:IsValid() == false or obj:IsCharacter() == false) then
		LOG.std("", "debug", "CCS", "character obj expected got non-character or nil in CCS.DefaultAppearance.MountDefaultAppearance() function call");
		return;
	end
	
	-- get the default appearance information
	local filename = obj:GetPrimaryAsset():GetKeyName();
	
	local item = DB.GetItemByModelFilePath(filename, "Normal Character");
	if(not item or not item.Reserved5) then
		LOG.std("", "debug", "CCS", "no default appearance info for character: "..filename);
		return;
	end
	local sInfo = item.Reserved5;
	
	-- TODO: provide CCS infomation setting through non obj_params param
	
	-- apply character CCS information
	CCS.ApplyCCSInfoString(obj, sInfo);
end

