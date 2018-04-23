--[[
Title: The options of 3DMapSystem
Author(s): LiXizhi, WangTian
Date: 2009/1/1
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemData/options.lua");
Map3DSystem.options.CharClickDistSq
Map3DSystem.options.XrefClickDist
------------------------------------------------------------
]]

-- Map3DSystem: 
if(not Map3DSystem) then Map3DSystem = {}; end

-------------------------------------------------
-- Map3DSystem.options
-------------------------------------------------
Map3DSystem.options = {
	-- this is for how long to show the character marker and within which we can right click to interact with a character. 
	CharClickDist = 4,
	CharClickDistSq = 16,
	-- within which we can talk to a given NPC, this is usually the same as CharClickDist, in order to show the marker on NPC. 
	NpcTalkDist = 4,
	NpcTalkDistSq = 16,
	
	-- this is for how long to show the Xref marker and within which we can click to interact with it. 
	XrefClickDist = 2,
	XrefClickDistSq = 4,
	
	-- true to double click on the ground to move the character. otherwise it is single click to move the character
	DoubleClickMoveChar = false,
	
	-- the command to call when viewing a given uid, this affects the behavior of pe:name mcml tag
	-- NOTE: ViewProfileCommand is manually set to "Profile.Aries.ShowFullProfile" in main_loop.lua
	ViewProfileCommand = "Profile.ViewProfile", 
	
	-- the command to call when viewing one's own uid, this affects the behavior of pe:name mcml tag
	EditProfileCommand = "Profile.EditProfile",
	
	-- the command to call to switch to a given app. 
	SwitchAppCommand = "File.SwitchApp",
	
	-- the name part of a gateway JID to use. if this is specified, all other gateway settings are ignored. 
	-- this is usually used for debugging a given gateway at development time. 
	-- At production time, always disable this 
	ForceGateway = nil,
	
	-- whether this is the game engine's editor mode. Usually application will allow full-ranged editing when editor mode is enabled.
	-- TODO: a game engine license may need to be purchased in order to preserve changes in editor mode. 
	IsEditorMode = false,

	-- max triangle count to allow when render player is allowed
	MaxCharTriangles_show = 30000,
	-- max triangle count to allow when render player is disabled. 
	MaxCharTriangles_hide = 10000,

	-- ignore player asset in attribute.db when loading world
	ignorePlayerAsset = false,
};
