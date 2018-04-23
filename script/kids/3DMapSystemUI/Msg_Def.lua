--[[
Title: All messages used in game
Author(s): LiXizhi
Date: 2007.10.16
Design pattern Note: 
	we have changed from fully event driven to a new pattern of a mixture of event driven and message driven.
The merit of message driven is that it allows different applications in the map systems to exchange or send messages with one another. 
See Msg_*.* and Chat/ChatWnd.lua and script/ide/os.lua
	In the map application case, another application, say the chat application, can send a message to the map application to zoom to a certain 
location on the map. There will be lots of such interactions going on between map application and the rest of UI and system module, 
and we use messages for such important actions. For purely local messages, one can use the old event callback interface. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Msg_Def.lua");
Map3DSystem.InitMessageSystem()
------------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_obj.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_env.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_profile.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_game.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_movie.lua");

-------------------------------------------------------------
-- message related
-------------------------------------------------------------

-- init message system: call this function at start up to init the message system
function Map3DSystem.InitMessageSystem()
	Map3DSystem.SceneApp = CommonCtrl.os.CreateGetApp("scene");
	Map3DSystem.ObjectWnd = Map3DSystem.SceneApp:RegisterWindow("object", nil, Map3DSystem.OnObjectMessage);
	Map3DSystem.EnvWnd = Map3DSystem.SceneApp:RegisterWindow("env", nil, Map3DSystem.OnEnvMessage);
	Map3DSystem.ProfileWnd = Map3DSystem.SceneApp:RegisterWindow("profile", nil, Map3DSystem.OnProfileMessage);
	Map3DSystem.GameWnd = Map3DSystem.SceneApp:RegisterWindow("game", nil, Map3DSystem.OnGameMessage);
	Map3DSystem.MovieWnd = Map3DSystem.SceneApp:RegisterWindow("movie", nil, Map3DSystem.OnMovieMessage);
	
	-- create an "input" application, mouse and key board windows for other applications to hook to. 
	Map3DSystem.input = CommonCtrl.os.CreateGetApp("input");
	Map3DSystem.input:RegisterWindow("mouse_down", nil, nil);
	Map3DSystem.input:RegisterWindow("mouse_move", nil, nil);
	Map3DSystem.input:RegisterWindow("mouse_up", nil, nil);
	Map3DSystem.input:RegisterWindow("key_down", nil, nil);
	Map3DSystem.input:RegisterWindow("onsize", nil, nil);
end

local i=0;
local function AutoEnum()
	i=i+1;
	return i;
end
local function LastEnum(index)
	if(index~=nil) then
		i=index;
	end
	return i;
end

-- game messages
if(not Map3DSystem.msg) then Map3DSystem.msg = {
	---------------------------------------------------
	-- object related message
	---------------------------------------------------
	--[[ begin move in clipboard {obj_params={object parameters}, obj, 
		DisableMouseMove=boolean, -- whether mouse move event shall move the object
	}]]
	OBJ_BEGIN = LastEnum(99),
	OBJ_BeginMoveObject = LastEnum(100),
	-- begin copy in clipboard {{obj_params={object parameters}, obj, }
	OBJ_CopyObject=AutoEnum(),
	-- end move in clipboard {}
	OBJ_EndMoveObject=AutoEnum(),
	-- cancel move or copy in clipboard  {}
	OBJ_CancelMoveCopyObject=AutoEnum(),
	--[[ during move and copy operation, the 3D cursor object at mouse location.
	msg = {
		x,y,z,
		rotY_delta=float, 
		quat={x,y,z,w}, - absolute quaternion
		scale = float, -- absolute scale
		scale_delta=float
		reset=boolean, -- reset all rotation and scale
	}]]
	OBJ_MoveCursorObject=AutoEnum(),
	--[[ show a top level window to edit the object at the mouse cursor
	msg = {
		target=string, -- "cursorObj" 
		mouse_x, mouse_y=float,float, -- where to show 
		onclose = function(bIsCancel) or string, -- function to call when edit window closes.
	}]]
	OBJ_PopupEditObject=AutoEnum(),
	-- {}
	OBJ_PasteObject=AutoEnum(),
	
	--[[ create a new object in the scene
	msg = {
		obj_params={object parameters}, obj,  -- either obj_params or obj need to be valid. It denotes the object in action
		forcelocal=boolean, -- if true, no matter it is client or server or standalone, standalone is assumed. 
		silentmode=boolean, --  if true, no sound or visual effect is played. 
		progress=nil or [0,1], -- the construction progress of the mesh when created. 
		SkipHistory= nil or true, -- whether msg will be saved to history for recording or undo. 
		author = nil or player name, -- the play name who issued the message. 
	}]]
	OBJ_CreateObject=AutoEnum(),
	-- {obj_params={object parameters}, obj, forcelocal=boolean, } 
	OBJ_DeleteObject=AutoEnum(),
	--[[ apply rotation, translation, scale and reset modfication to an object or character. 
		All SRT and reset can be nil. Some provides both absolute and relative method
	msg = {
		obj_params={object parameters}, obj, 
		forcelocal=boolean, 
		pos={x,y,z}, -- absolute position
		pos_delta_camera = {dx,dy,dz},  -- delta position relative to the camera position
		rot_delta={dx, dy, dz}, - delta rotation around x,y,z axis
		quat={x,y,z,w}, - absolute quaternion
		scale_delta = float, -- relative scale. it is multiplied with the current scale
		scale = float, -- absolute scale
		reset=boolean, -- reset all rotation and scale
		-- following are character only
		asset_file = string, -- base character asset file path. 
		CCSInfoStr = string, -- all-in-one string about character appearances
		characterslot_info = table, -- for per item modification
		facial_info = table, -- for per item modification
		cartoonface_info = table, -- for per item modification
	}]] 
	OBJ_ModifyObject=AutoEnum(),
	
	-- {obj_params={object parameters}, obj } select a given object in the scene
	OBJ_SelectObject=AutoEnum(),
	-- {obj_params={object parameters}, obj } de-select a object
	OBJ_DeselectObject=AutoEnum(),
	-- {obj_params={object parameters}, obj } save a character attribute to local database
	OBJ_SaveCharacter=AutoEnum(),
	
	--[[ switch to an object in the scene
	msg = {
		fromObjectParam = {object parameters}, -- from object
		toObjectParam = {object parameters}, -- to object
	}]]
	OBJ_SwitchObject = AutoEnum(),
	--[[ pick a given type of object using a filter, and use a callback function when user clicks. a second call of this will overwrite the first call.
	msg = {
		filter = "anyobject", -- filter name, or a number string with bitwise field.
		callbackFunc = function(params) return true; end, -- a callback function that is called when user clicks. if this function return nil, it will stop picking. otherwise, it will continue picking more. 
	}]]
	OBJ_PickObject = AutoEnum(),
	
	OBJ_END = AutoEnum(),
	---------------------------------------------------
	-- terrain, ocean, sky (environment) related message
	---------------------------------------------------
	ENV_BEGIN = AutoEnum(),
	--[[ terrain texture paint brush
		msg = { brush = {
			-- texture file name or index into current texture list; the texture id, such as 1,2,3,4,5,6, or it could be the filename
			filename,
			-- position of the center of the brush in world coordinate
			x,y,z,
			-- radius
			radius = 2,
			-- brush filter factor
			factor = 0.5,
			-- erase or paint
			bErase = false,
		}, --[in|out]
	}]]
	TERRAIN_SET_PaintBrush=AutoEnum(),
	TERRAIN_GET_PaintBrush=AutoEnum(),
	--msg={texList = {[1]={filename = "Texture/tileset/generic/StoneRoad.dds"},[2]={}}}
	TERRAIN_SET_TextureList=AutoEnum(),
	TERRAIN_GET_TextureList=AutoEnum(),
	
	--[[ terrain heightmap or elevation brush
		msg = { brush = {
			type = "Flatten", "AddHeightField", "GaussianHill","Roughen_Smooth", "RadialScale"
			-- position of the center of the brush in world coordinate
			x,y,z,
			radius = 20,
			radius_factor = 0.5,
			smooth_factor = 0.5,
			heightScale = 3.0,
			sq_filter_size = 4,
			sq_filter_weight = 0.5,
			gaussian_deviation = 0.1,
			bRoughen = boolean
			filename = string, height field file name
		},
	}]]
	TERRAIN_SET_HeightFieldBrush=AutoEnum(),
	TERRAIN_GET_HeightFieldBrush=AutoEnum(),
	
	--[[ msg = {
		brush = nil or {}, 
		forcelocal=boolean, 
	}]]
	TERRAIN_Paint=AutoEnum(),
	
	--[[ msg = {
		brush = nil or {}, 
		forcelocal=boolean, 
	}]]
	TERRAIN_HeightField=AutoEnum(),
	
	--[[msg = {
		height = float, -- if nil, nothing happens, if it is a double value, it is the height
		bEnable = boolean, -- if nil, nothing happens.
		-- ocean color in the range [0,1]. they can be nil. 
		r=float,
		g=float,
		b=float,
	}]]
	OCEAN_SET_WATER=AutoEnum(),
	
	--[[msg = {
		-- asset file name
		skybox = string, 
		skybox_name = string, 
		--sky color 
		sky_r=float,
		sky_g=float,
		sky_b=float,
		--fog color 
		fog_r=float,
		fog_g=float,
		fog_b=float,
		-- time of day
		timeofday = float [-1,1]
	}]]
	SKY_SET_Sky=AutoEnum(),
	
	ENV_END = AutoEnum(),
	---------------------------------------------------
	-- User profile messages
	---------------------------------------------------
	--[[ add bonus point to the user
	msg = {
		operation = "add"
		value = number
	}]]
	USER_AddPoint=AutoEnum(),
	--[[ get user profile
	msg = {
		profile = nil, output table
	}]]
	USER_GetProfile=AutoEnum(),
	
	
	---------------------------------------------------
	-- Main bar message
	---------------------------------------------------
	
	--[[ show or hide the main bar
	msg = {
		bShow = true or false, nil toggle current setting
	}]]
	MAINBAR_Show = AutoEnum(),
	--[[ switch to navigation mode
	msg = {
		bNavMode = true or false
		-- true: switch to navmode, false switch back to edit mode
	}]]
	MAINBAR_NavMode = AutoEnum(),
	--[[ switch to main bar status
	NOTE: if you are not sure which status should call, leave sStatus empty string or nil
	msg = {
		sStatus = status name, {"none", "character", "model", "BCSXRef"}
	}]]
	MAINBAR_SwitchStatus = AutoEnum(),
	--[[ play animation to icon with "bounce" common animation
	msg = {
		isLooping = true or false,
		isAnimate = true or false,
		iconID
	}]]
	MAINBAR_BounceIcon = AutoEnum(),
	
	---------------------------------------------------
	-- Main panel message
	---------------------------------------------------
	
	--[[ show or hide the panel
	msg = {
		posX = x position of the main panel
	}]]
	MAINPANEL_SetPosX = AutoEnum(),
	
	--[[ main bar icon onclick
	msg = {
		index = index of the main bar icon
	}]]
	MAINPANEL_ClickIcon = AutoEnum(),
	
	--[[ show or hide the panel
	msg = {
		bAutoHiding = true or false, nil toggle current setting
	}]]
	MAINPANEL_AutoHide = AutoEnum(),
	
	--[[ show default panel according to the selected object
	]]
	MAINPANEL_ShowDefault = AutoEnum(),
	
	---------------------------------------------------
	-- Creation sub-panel message
	---------------------------------------------------
	
	--[[ show the creation box with icons
	}]]
	MAINPANEL_Creation_CategoryWnd_ShowIcons = AutoEnum(),
	--[[ show the creation box with category tree view
	}]]
	MAINPANEL_Creation_CategoryWnd_ShowTreeView = AutoEnum(),
	--[[ hide the creation box
	}]]
	MAINPANEL_Creation_CategoryWnd_Hide = AutoEnum(),
	
	--[[ show or hide the main menu
	msg = {
		bShow = true or false, nil toggle current setting
		mode = "compact" or "full", choose between full and compact modes
	}]]
	MAINPANEL_Creation_MainMenu_Show = AutoEnum(),
	
	
	--[[ show or hide the creation, modify, property, sky, water, terrain panel
	msg = {
		bShow = true or false, nil toggle current setting
	}]]
	MAINPANEL_Creation_Show = AutoEnum(),
	MAINPANEL_Modify_Show = AutoEnum(),
	MAINPANEL_Property_Show = AutoEnum(),
	MAINPANEL_Sky_Show = AutoEnum(),
	MAINPANEL_Water_Show = AutoEnum(),
	MAINPANEL_Terrain_Show = AutoEnum(),
	
	---------------------------------------------------
	-- Creator related message
	-- Added: 2008-5-26: 
	---------------------------------------------------
	CREATOR_RECV_BCSMSG = AutoEnum(),
	
	-- Added: 2008-12-29: for ZhangYu's create anything on xref
	CREATOR_RECV_ANYTHING = AutoEnum(),
	
	---------------------------------------------------
	-- IM chat related message
	---------------------------------------------------
	CHAT_QuickChatWindow = AutoEnum(),
	CHAT_JC = AutoEnum(),
	
	---------------------------------------------------
	-- map related message
	---------------------------------------------------
	
	---------------------------------------------------
	-- Character animation related message
	---------------------------------------------------
	--[[ character animation
	msg = {
		obj_params = character param
		animationName = 
	}]]
	ANIMATION_Character = AutoEnum(),
	
	---------------------------------------------------
	-- game related message
	---------------------------------------------------
	GAME_BEGIN = AutoEnum(),
	-- a game client or server status message. 
	-- msg = {text=string}
	GAME_LOG = AutoEnum(),
	-- change to a new type of game cursor
	-- msg = {
	--		-- known cursor name (such as nil, "char", "model", "xref") or cursor file path. hot spot in cursor image in pixel.
	--		cursor=nil, cursorfile=nil, hot_x=nil, hot_y=nil,
	-- }
	GAME_CURSOR = AutoEnum(),
	-- join a Jabber-GSL server with a given JID, this is a command message.  
	GAME_JOIN_JGSL = AutoEnum(),
	-- called whenever this computer successfully signed in to a remote server. Input contains server JID
	-- one can hook to this message to get informed. 
	-- msg = {serverJID=JID}
	GAME_JGSL_SIGNEDIN = AutoEnum(),
	-- called whenever this computer signed out of a remote server or just can not connect to the server due to time out. . Input contains server JID.
	-- one can hook to this message to get informed. 
	-- msg = {serverJID=JID}
	GAME_JGSL_SIGNEDOUT = AutoEnum(),
	-- called whenever connection to a remote server computer timed out. 
	-- it may due to server unavailable or server just shut down. If the server is connected previously, GAME_JGSL_SIGNEDOUT will entails. 
	-- one can hook to this message to get informed. 
	GAME_JGSL_CONNECTION_TIMEOUT = AutoEnum(),
	-- called whenever some user come in to this world. one can hook to this message to get informed. 
	-- msg = {userJID=JID, uid}
	GAME_JGSL_USER_COME = AutoEnum(),
	-- called whenever some user leaves this world. one can hook to this message to get informed. 
	-- msg = {userJID=JID}
	GAME_JGSL_USER_LEAVE = AutoEnum(),
	-- called whenever an error occurs whening connecting with a remote server. 
	GAME_JGSL_SERVER_ERROR = AutoEnum(),
	
	-- teleport the current character to a given location. User must have the right to do so. 
	-- msg = {x=number, y=number, z=number}, if x,y,z is not specified, it will pick a 3d position using the current mouse position. if only y is not specified, it will use the terrain height. 
	GAME_TELEPORT_PLAYER = AutoEnum(),
	
	GAME_END = AutoEnum(),
	---------------------------------------------------
	-- movie related message: actor, clips, cameras, and whole movie management
	---------------------------------------------------
	MOVIE_BEGIN = AutoEnum(),
	-- pause a movie actor, the actor may be recording or playing before paused
	-- msg = {obj=obj, obj_params=obj_params}
	MOVIE_ACTOR_Pause = AutoEnum(),
	-- begin recording the action of an actor from its current time cursor
	-- msg = {obj=obj, obj_params=obj_params}
	MOVIE_ACTOR_Record = AutoEnum(),
	-- play from the beginning of the movie, using relative positioning for the actor
	-- msg = {obj=obj, obj_params=obj_params}
	MOVIE_ACTOR_ReplayRelative = AutoEnum(),
	-- play from the beginning of the movie, using absolute positioning for the actor
	-- msg = {obj=obj, obj_params=obj_params}
	MOVIE_ACTOR_Replay = AutoEnum(),
	-- stop: which is pause and rewind.
	-- msg = {obj=obj, obj_params=obj_params}
	MOVIE_ACTOR_Stop = AutoEnum(),
	-- save the movie sequence of a given actor to a specified file. {}
	-- msg = {obj=obj, obj_params=obj_params, filename=where to save, silent = true, }
	MOVIE_ACTOR_Save = AutoEnum(),
	-- load the movie sequence of a given actor to a specified file. 
	-- msg = {obj=obj, obj_params=obj_params, filename=where to load, afterloadmsgtype = Map3DSystem.msg.MOVIE_ACTOR_Pause, }
	MOVIE_ACTOR_Load = AutoEnum(),
	MOVE_END = AutoEnum(),
	---------------------------------------------------
	-- scene related message: saving world
	---------------------------------------------------
	-- save the current world. if  bQuickSave is true, only modified is saved. if not, all scene objects within 500 meters are saved
	-- msg = {bQuickSave=true}
	SCENE_BEGIN = AutoEnum(),
	SCENE_SAVE = AutoEnum(),
	SCENE_END = AutoEnum(),
}; end

-- send a message to scene:object window handler
-- e.g. Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_CancelMoveObject})
function Map3DSystem.SendMessage_obj(msg)
	msg.wndName = "object";
	Map3DSystem.SceneApp:SendMessage(msg);
end

-- send a message to environment window: environment window handler
-- e.g. Map3DSystem.SendMessage_env({type = Map3DSystem.msg.ENV_XXX})
function Map3DSystem.SendMessage_env(msg)
	msg.wndName = "env";
	Map3DSystem.SceneApp:SendMessage(msg);
end

-- send a message to user profile: profile window handler
-- e.g. Map3DSystem.SendMessage_profile({type = Map3DSystem.msg.USER_AddPoint, value=10})
function Map3DSystem.SendMessage_profile(msg)
	msg.wndName = "profile";
	Map3DSystem.SceneApp:SendMessage(msg);
end

-- send a message to game window: game window handler
-- e.g. Map3DSystem.SendMessage_game({type = Map3DSystem.msg.GAME_LOG, text="abc"})
function Map3DSystem.SendMessage_game(msg)
	msg.wndName = "game";
	Map3DSystem.SceneApp:SendMessage(msg);
end

-- send a message to movie window: movie window handler
-- e.g. Map3DSystem.SendMessage_movie({type = Map3DSystem.msg.MOVIE_ACTOR_Pause, obj=obj, obj_params=obj_params})
function Map3DSystem.SendMessage_movie(msg)
	msg.wndName = "movie";
	Map3DSystem.SceneApp:SendMessage(msg);
end