--[[
Title: The user database functions for paraworld
Author(s): LiXizhi
Date: 2006/1/26
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemData/user_db.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");

local L = CommonCtrl.Locale("IDE");

-- Map3DSystem: 
if(not Map3DSystem) then Map3DSystem = {}; end

-------------------------------------------------
-- Map3DSystem.User
-- Map3DSystem.User.userinfo
-------------------------------------------------
Map3DSystem.User = {
	Name = "",
	Password = "",
	userid = "",
	sessionkey = "",
	ChatDomain="pala5.com",
	Domain="pala5.com",
	IsAuthenticated = false,
	-- 3D map system "Pie" currency
	UserPie = 0;
	-- user level
	Level = 0;
	
	Role = "dummy",
	Roles = {
		["dummy"] = {},
		["guest"] = {Chat=true, ScreenShot=true,Teleport=true,},
		["administrator"] = {
			Create=true, 
			Edit=true, 
			Delete=true, 
			Save=true, 
			Teleport=true,
			Sky=true, 
			Ocean=true, 
			TerrainHeightmap=true, 
			TerrainTexture=true, 
			TimeOfDay=true, 
			Chat=true, 
			ScreenShot=true, 
			ShiftCharacter = true,
			CanFly=true,
		},
		-- can do everything as an administrator, except save world
		["poweruser"] = {
			Create=true, 
			Edit=true, 
			Delete=true, 
			--Save=true, 
			Teleport=true,
			Sky=true, 
			Ocean=true, 
			TerrainHeightmap=true, 
			TerrainTexture=true, 
			TimeOfDay=true, 
			Chat=true, 
			ScreenShot=true,
			ShiftCharacter = true,
			CanFly=true,
		},
		-- usually for friends on networked worlds, it disables terrain heightfield modification and shifting characters.
		["friend"] = {
			Create=true, 
			Edit=true, 
			Delete=true, 
			Sky=true, 
			TerrainTexture=true, 
			TimeOfDay=true, 
			Chat=true, 
			ScreenShot=true, 
			Teleport=true,
			ShiftCharacter = true,
			CanFly=true,
		},
	},
	-- the following are user info about the user activity
	userinfo ={
		-- whether the product is registered: this means that product has been activated locally and registered online
		IsProductRegistered = nil, 
		-- whether the user has successfully logged in to the community site at least once in the past
		IsCommunityMember = nil, 
		-- whether the user has taken screen shot and uploaded to our community at least once in the past.
		HasUploadedUserWork = nil, 
		-- whether to display a speical welcome window in any 3d world.
		HideWelcomeWorldWindow = nil, 
		-- whether to display a speical welcome window when the application start up.
		HideStartupWelcomeWindow = nil, 
	},
	-- players owned by this user. It stores all the player name and appearances as well as the currently selected player.
	-- in networked world, the user will login using the default player appearance in this table. This table is synchronized with the remote central server
	Players = {
		-- player appearance information, character slots [0, 9] totally 10 slots for character appearance selection
		-- Map3DSystem.User.Players.AppearanceInfo.CharacterSlot0=nil, Map3DSystem.User.Players.AppearanceInfo.CharacterSlot9=nil
		AppearanceInfo = {},
	},
	-- the current selected player index
	SelectedPlayerIndex = 1,
};
-- return true if user has right to a given action called name, otherwise return nil.
-- @param name: it may be "Create", "Edit", "Save", etc. More information see Map3DSystem.User.Roles.
function Map3DSystem.User.HasRight(name)
	return Map3DSystem.User.Roles[Map3DSystem.User.Role][name] or Map3DSystem.options.IsEditorMode
end

-- reset to initial signed out state.
function Map3DSystem.User.Reset()
	Map3DSystem.User.Name = "";
	Map3DSystem.User.Password = "";
	Map3DSystem.User.userid = "";
	Map3DSystem.User.sessionkey = "";
	Map3DSystem.User.IsAuthenticated = false;
end

-- return true if user has rights, otherwise return nil and display a messagebox telling the user why.
-- @param name: it may be "Create", "Edit", "Save", etc. More information see Map3DSystem.User.Roles.
function Map3DSystem.User.CheckRight(name)
	if(Map3DSystem.User.HasRight(name)) then
		return true;
	else
		_guihelper.MessageBox(L"You do not have permission to do this action in this world\n");
		commonlib.log("You do not have permission to do this action %s in this world\n", tostring(name));
	end
end

-- set an existing role for the current user. it returns nil if failed. true if succeeded.
-- @param name: some predefined roles are "guest", "administrator", "friend", "poweruser"
function Map3DSystem.User.SetRole(name)
	local res;
	if(Map3DSystem.User.Roles[name]~=nil) then
		Map3DSystem.User.Role = name;
		res = true;
	end
	return res;
end

function Map3DSystem.User.ReadUserInfo()
	local userinfo = commonlib.LoadTableFromFile("config/userinfo.txt")
	if(userinfo~=nil) then
		Map3DSystem.User.userinfo = userinfo;
	end
end

-- read user info when the application loads
Map3DSystem.User.ReadUserInfo();

function Map3DSystem.User.SaveUserInfo()
	commonlib.SaveTableToFile(Map3DSystem.User.userinfo, "config/userinfo.txt")
end

-- save username and password to local file
function Map3DSystem.User.SaveCredential(username, password)
	-- write credential to file
	local file = ParaIO.open("config/npl_credential.txt", "w");
	file:WriteString(ParaMisc.SimpleEncode(username).."\r\n");
	file:WriteString(ParaMisc.SimpleEncode(password).."\r\n");
	file:close();
end

-- return username and password from the local file
function Map3DSystem.User.LoadCredential()
	-- read credential from file
	local file = ParaIO.open("config/npl_credential.txt", "r");
	local username, password = "", "";
	if(file:IsValid()) then
		username = ParaMisc.SimpleDecode(tostring(file:readline()));
		password = ParaMisc.SimpleDecode(tostring(file:readline()));
		file:close();
	end	
	return username, password;
end

------------------------
-- load user info
------------------------
-- use user name from saved credential file
-- Map3DSystem.User.Name, Map3DSystem.User.Password = Map3DSystem.User.LoadCredential();

---------------------------------
-- current player db table
---------------------------------
if(not Map3DSystem.player) then Map3DSystem.player = {}; end
Map3DSystem.Player = Map3DSystem.player; -- alias

-- read user name from credential file
--Map3DSystem.player.name = Map3DSystem.User.Name;
Map3DSystem.player.level = 0;
-- index to the current selected character range [0, 9]
Map3DSystem.player.CurrentSelectedCharacterIndex = 0;
