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

local options = Map3DSystem.options;

--外部渠道参数的本地声明
local local_statement = {
	-- the command to execute when entering the world, similar to home point,and if repeated, the home point shall prevail
	-- ommands are separated by ";",e.g. world_enter_cmds = /paralife show;/shader 1
	world_enter_cmds = "",
	-- Whether to allow built-in browsers
	enable_npl_brower = true,
	-- Whether to lock the resolution to 1280x720
	is_resolution_locked = false,
}

local function _loadChannelOptions(optionPath)
	if ParaIO.DoesFileExist(optionPath) then 
		LOG.std(nil, "info", "_loadChannelOptions", "read ini file: %s",optionPath);
		local file = ParaIO.open(optionPath,"r");
		if(file:IsValid())then
			local line = file:readline();
			while(line) do
				local arr = commonlib.split(line,"=");
				if #arr==2 then
					local key = arr[1]:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "") --去掉字符串首尾的空格、引号
					local val = arr[2]:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "")
					
					if key~="" and val~="" and local_statement[key]~=nil then  --默认声明不可为nil
						LOG.std(nil, "info", "_loadChannelOptions", "load option: %s=%s",key,val);
						local _type = type(local_statement[key])
						if _type=="number" then
							options[key] = tonumber(val)
						elseif _type=="string" then
							options[key] = val
						elseif _type=="boolean" then
							options[key] = val=="true"
						else
							print(string.format("-----未声明的渠道参数%s=%s",key,val))
						end
					end
				end
				line = file:readline();
			end
			file:close();
		else
			LOG.std(nil, "info", "_loadChannelOptions", "can't open file:%s",optionPath);
		end
	end
end

--[[
	读取game_iotions参数,先查找config/option.ini，如果是特殊渠道，如chennelId==430，再查找一次config/option_430.ini
	配置文件格式是 每一行一个参数，以等号("=")隔开，同时必须在上方先声明过的
	如：
	world_enter_cmds = /paralife show;/shader 1
	enable_npl_brower = false
	is_resolution_locked = true
]]
function options.InitChannelOptions()
	if options._isChannelOptionsLoaded then
		return
	end
	options._isChannelOptionsLoaded = true

	for k,v in pairs(local_statement) do
		options[k] = v
	end

	local optionPath = ParaIO.GetWritablePath().."config/channel_option_dft.ini"
	_loadChannelOptions(optionPath)
	if System.options.channelId then --参数直接覆盖
		optionPath = ParaIO.GetWritablePath()..string.format("config/channel_option_%s.ini",System.options.channelId)
		_loadChannelOptions(optionPath)
	end

	options.enable_npl_brower = options.enable_npl_brower and System.os.GetPlatform()=="win32"
end