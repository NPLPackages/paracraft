--[[
Title: Commands
Author(s): LiXizhi
Date: 2013/2/9
Desc: slash command 
use the lib:
------------------------------------------------------------
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/EnterGamePage.lua");
NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
	
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");



Commands["makeasset"] = {
	name="makeasset", 
	quick_ref="/makeasset", 
	desc="show the asset maker", 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Assets/CreateAssetBagPage.lua");
		local CreateAssetBagPage = commonlib.gettable("MyCompany.Aries.Creator.CreateAssetBagPage")
		CreateAssetBagPage.ShowPage();
	end,
};


Commands["echo"] = {
	name="echo", 
	quick_ref="/echo any text message", 
	desc="" , 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		LOG.std(nil, "info", "echo cmd", cmd_text);
		GameLogic.AppendChat(cmd_text)
	end,
};

Commands["msg"] = {
	name="msg", 
	quick_ref="/msg any text message", 
	desc="show message in a message box to the user" , 
	handler = function(cmd_name, cmd_text, cmd_params)
		LOG.std(nil, "info", "msg cmd", cmd_text);
		_guihelper.MessageBox(commonlib.Encoding.EncodeHTMLInnerText(cmd_text));
	end,
};

Commands["tip"] = {
	name="tip", 
	quick_ref="/tip [-color #ff0000] [-duration 5000] [-name] [text]", 
	desc=[[show a screen message to a channel name with a given string
@param -color: text color, default to black
@param -duration: in milliseconds. default to 10000 or 10 seconds
e.g.
/tip hello world
/tip -color #ff0000 -duration 1000  red text with 1 second
/tip -name1 hello			show text in name1 channel
/tip -name1					clear name1
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		LOG.std(nil, "info", "tip", cmd_text);
		
		local name, color, duration, text;
		local option_name = "";
		while (option_name and cmd_text) do
			option_name, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option_name == "color") then
				color, cmd_text = CmdParser.ParseColor(cmd_text);
			elseif(option_name == "duration") then
				duration, cmd_text = CmdParser.ParseInt(cmd_text);
			elseif(option_name) then
				name = option_name;
			end
		end
		text = cmd_text;
		
		name = name or "default";
		local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
		if(text == "" or not text) then
			BroadcastHelper.Clear(name);
		else
			BroadcastHelper.PushLabel({id=name, label = text, max_duration=duration or 10000, color = color or "0 0 0", scaling=1, bold=true, shadow=true,});
		end
	end,
};

Commands["dostring"] = {
	name="dostring", 
	quick_ref="/dostring string", 
	desc=[[load and do string in sandbox environment
do string in sandbox api environment
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameRules.lua");
		local GameRules = commonlib.gettable("MyCompany.Aries.Game.GameRules");
		GameRules:DoString(cmd_text);
	end,
};

Commands["fps"] = {
	name="fps", 
	quick_ref="/fps [true|false|1|0]", 
	desc=[[use fps camera
toggle first person camera
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
		local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
		-- BroadcastHelper.PushLabel({id="GameLogic", label = "第一人称FPS模式开启", max_duration=20000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
		CameraController.ToggleCamera(cmd_text == "true" or cmd_text=="1" or cmd_text=="");
	end,
};

Commands["where"] = {
	name="where", 
	quick_ref="/where [offset_y]", 
	desc=[[get current position and tile position and copy to clipboard
query info. 
e.g. "/where -1" query the block below one block. 
the block position is copied to clipboard
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
		if(Desktop.SetCameraMode) then
			local offset_y;
			if(cmd_text) then
				offset_y = cmd_text:match("%-?%d+");
				offset_y = tonumber(offset_y or 0);
			end

			local cx, cy, cz = ParaScene.GetPlayer():GetPosition();
			local tile_x, tile_z = BlockEngine:GetRegionPos(cx,cz);
			local bx,by,bz = BlockEngine:block(cx, cy+0.1, cz);
			by = by + offset_y;
			local block = BlockEngine:GetBlockTemplateByIdx(bx,by,bz);
			local block_info;
			if(block) then
				block_info = format("%s %d", block.name or tostring(block.id), ParaTerrain.GetBlockUserDataByIdx(bx,by,bz));
			end
			local s = format("tile (%d, %d) block(%d, %d, %d) %s", tile_x, tile_z, bx,by,bz, block_info or "");
			LOG.std(nil, "info", "where", s)
			BroadcastHelper.PushLabel({id="GameLogic", label = s, max_duration=20000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
			local clipboardtext = format("%d %d %d", bx,by,bz);
			ParaMisc.CopyTextToClipboard(clipboardtext);
		end
	end,
};

Commands["info"] = {
	name="info", 
	quick_ref="/info", 
	desc="toggle info window (F3)" , 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InfoWindow.lua");
		local InfoWindow = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWindow");
		InfoWindow.ShowPage();		
	end,
};


Commands["quest"] = {
	name="quest", 
	mode_deny = "",
	mode_allow = "",
	quick_ref="/quest [quest_id]", 
	desc=[[start or complete the current step in the quest
complete the current quest step. run multiple times. 
"/quest id" start given quest. 
"/quest" finish current quest
"/quest reset" clear all quests
"/quest ?" query the current step
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.lua");
			local BuildQuest = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
			local quest = BuildQuest.GetCurrentQuest();
			if(quest) then
				if(cmd_text == "?" or cmd_text == "step") then
					if(quest.bom) then
						local step_count = quest.bom:GetFinishedCount() or 0;
						BroadcastHelper.PushLabel({id="GameLogic", label = format("quest step = %d", step_count), max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
					end
				else
					quest:OnDoNextStep();
				end
			else
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestProvider.lua");
				local BuildQuestProvider =  commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
				
				if(cmd_text == "reset") then
					NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
					local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");
					local profile = UserProfile.GetUser();
					profile:ResetBuildProgress();
				else
					local task = BuildQuestProvider.GetTaskByID(cmd_text);
					if(task) then
						MyCompany.Aries.Game.Tasks.BuildQuest:new({task=task}):Run();
					end
				end
			end
		end
	end,
};

local item_name_map = {["exp"]="Exp", ["coin"]="Coin", ["water"]="Water",["stamina"]="Stamina",}

Commands["add"] = {
	name="add", 
	quick_ref="/add [name] [value]", 
	desc=[[add name, value pair to local server. e.g.
/add Coin 1
/add Stamina -1
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not System.options.is_mcworld) then
			return;
		end
		if(cmd_text) then
			local name, value = cmd_text:match("^(%S+)%s+(%S+)");

			if(name and value) then
				name = item_name_map[name];
				NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
				local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");

				local profile = UserProfile.GetUser();
				if(profile and type(profile["Add"..name]) == "function") then
					value = tonumber(value);
					if(value) then
						profile["Add"..name](profile, value);
					end
				end
			end
		end
	end,
};


Commands["get"] = {
	name="get", 
	mode_deny = "",
	mode_allow = "",
	quick_ref="/get [name]", 
	desc=[[
get name, value pair from local server. e.g.
/get Coin
/get Stamina
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not System.options.is_mcworld) then
			return;
		end
		if(cmd_text) then
			local name = cmd_text:match("^(%S+)");

			if(name) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
				local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");

				local profile = UserProfile.GetUser();
				if(profile and profile[name] ~= nil) then
					NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
					local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
					ChatChannel.AppendChat({
						ChannelIndex=ChatChannel.EnumChannels.NearBy, 
						words=format("%s = %s", name,  tostring(profile[name])),
					});
				end
			end
		end
	end,
};

Commands["stat"] = {
	name="stat", 
	quick_ref="/stat [op] [name] [value]", 
	desc=[[stat get blocks_created
get/set statistics. e.g.
/stat get blocks_created
/stat add blocks_created 1
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not System.options.is_mcworld) then
			return;
		end
		if(cmd_text) then
			local op, name, value = cmd_text:match("^(%S+)%s+(%S+)%s+(%S+)");
			if(not value) then
				op, name, value = cmd_text:match("^(%S+)%s+(%S+)");
			else
				value = tonumber(value) or value;
			end

			NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
			local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");
			local profile = UserProfile.GetUser();
			if(profile and name) then
				local stat = profile:GetStat(name);
				if(stat) then
					if(op == "add") then
						stat:AddValue(value);
					elseif(op == "get") then
						NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
						local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
						ChatChannel.AppendChat({
							ChannelIndex=ChatChannel.EnumChannels.NearBy, 
							words=format("%s = %s", name,  tostring(stat:GetValue(value))),
						});
					end
				end
			end
		end
	end,
};

Commands["useplayerpivoty"] = {
	name="useplayerpivoty", 
	quick_ref="/useplayerpivoty", 
	desc="secret command" , 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
		MyCompany.Aries.Game.Tasks.SelectBlocks.UsePlayerPivotY = not MyCompany.Aries.Game.Tasks.SelectBlocks.UsePlayerPivotY;
	end,
};

Commands["renderdist"] = {
	name="renderdist", 
	quick_ref="/renderdist [-super] [10-200]", 
	desc=[[render distance between 10 and maxrenderdist. 
The upper limit is set by command /maxrenderdist 
/renderdist 96
/renderdist -super 2000   using multiframe rendering for unlimited distance
]], 
	mode_deny = "",
	mode_allow = "",
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local options = {};
			options, cmd_text = CmdParser.ParseOptions(cmd_text);
			local dist = tonumber(cmd_text)

			if(dist) then
				if(options.super) then
					GameLogic.options:SetSuperRenderDist(dist);
					if(dist and dist > GameLogic.options:GetRenderDist() and dist>64) then
						GameLogic.options:SetFogEnd(dist - 64);
					end
				else
					GameLogic.options:SetRenderDist(dist);
				end
			end
		end
	end,
};

Commands["maxrenderdist"] = {
	name="maxrenderdist", 
	quick_ref="/maxrenderdist [64-1024]", 
	desc=[[max renderdist allowed. this will greatly skill framerate if set too large. 
/maxrenderdist 512
]], 
	mode_deny = "",
	mode_allow = "",
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local dist = tonumber(cmd_text)
			GameLogic.options:SetMaxViewDist(dist);
		end
	end,
};

Commands["uiscaling"] = {
	name="uiscaling", 
	quick_ref="/uiscaling [0-2]", 
	desc=[[UI scaling. 0 is the original unscaled scaling is used. Value is usually in [1,2].  where 1 means the 960*640, which is the smallest UI size allowed. 
/uiscaling 1
]], 
	mode_deny = "",
	mode_allow = "",
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local scaling = tonumber(cmd_text) or 0;
			if(scaling >=-1 and scaling<=10) then
				GameLogic.options:SetUIScaling(scaling);
			end
		end
	end,
};

Commands["map"] = {
	name="map", 
	quick_ref="/map", 
	desc="map a given block in hand" , 
	mode_deny = "",
	mode_allow = "",
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not System.options.is_mcworld) then
			return;
		end
		local bShow = true;
		if(cmd_text == "hide") then
			bShow = false;
		end
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockMinimap.lua");
		local BlockMinimap = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockMinimap");
		BlockMinimap.ShowPage(bShow, true);
	end,
};

Commands["mode"] = {
	name="mode", 
	quick_ref="/mode [game|edit|tutorial|school|strictgame]", 
	mode_deny = "",
	mode_allow = "",
	desc=[[locking game mode to the given value. 
Once locked, user will not be able to toggle unless with command line. 
@param game: in game mode, one can use /addrule command to define world rules
@param edit: in edit mode, everything is editable. 
@param tutorial: tutorial mode is same as edit mode, except that mouse picking 
is only valid if there is a ending block(id=155) below. 
@param school: playing online games are banned in school mode. 
e.g.
/mode game     :lock to game mode
/mode edit     :lock to edit mode
/mode          :unlock and toggle between game/edit mode. 
/mode tutorial 
/mode school 7 : make school mode for 7 days
/mode strictgame : no commands, no cheating. Only activated when game is readonly.
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(not System.options.is_mcworld) then
			return;
		end
		local mode;
		mode, cmd_text = CmdParser.ParseString(cmd_text);
		if(mode == "edit") then
			mode = "editor";
		elseif(mode == "play") then
			mode = "game";
		end

		if(mode == "school") then
			local days;
			days, cmd_text = CmdParser.ParseInt(cmd_text);
			GameLogic.options:SetSchoolMode(days or 7);
		else
			GameLogic.options:SetLockedGameMode(mode);
			if( GameLogic.GameMode:GetMode() ~= mode) then
				MyCompany.Aries.Creator.Game.Desktop.OnActivateDesktop(mode);
			end	
		end
	end,
};

Commands["torchcolor"] = {
	name="torchcolor", 
	quick_ref="/torchcolor [r] [g] [b]", 
	desc=[[set torch light color
/torchcolor 1.2 1 1
/torchcolor 1.2 0.2 0.2
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local r,g,b;
		r, cmd_text = CmdParser.ParseInt(cmd_text);
		g, cmd_text = CmdParser.ParseInt(cmd_text);
		b, cmd_text = CmdParser.ParseInt(cmd_text);
		r = r or 1;
		g = g or r or 1;
		b = b or r or 1;
		GameLogic.options:SetTorchColor(r,g,b);
	end,
};

Commands["cheat"] = {
	name="cheat", 
	quick_ref="/cheat [on|off]", 
	mode_deny = "",
	mode_allow = "",
	desc=[[whether to turn on or off cheating
/cheat    
/cheat off
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local bCheatingOn;
		bCheatingOn, cmd_text = CmdParser.ParseBool(cmd_text);
		if(bCheatingOn == nil) then
			bCheatingOn = true;
		end
		GameLogic.options:SetIsCheating(bCheatingOn);
		BroadcastHelper.PushLabel({label = "cheating mode is "..if_else(GameLogic.options:IsCheating(), "on", "off"), max_duration=5000, color = "0 0 0", scaling=1, bold=true, shadow=true,});
	end,
};

Commands["clicktocontinue"] = {
	name="clicktocontinue", 
	quick_ref="/clicktocontinue [on|off]", 
	mode_deny = "",
	mode_allow = "",
	desc=[[whether to turn on or off click to continue
/clicktocontinue    
/clicktocontinue off
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local bClickToContinue;
		bClickToContinue, cmd_text = CmdParser.ParseBool(cmd_text);
		if(bClickToContinue == nil) then
			bClickToContinue = true;
		end
		GameLogic.options:SetClickToContinue(bClickToContinue);
	end,
};

Commands["memlimit"] = {
	name="memlimit", 
	quick_ref="/memlimit [-v] [-s] [size_in_MB]", 
	mode_deny = "",
	mode_allow = "",
	desc=[[change the memory limit of the block vertex buffer
@param -v: set the visible chunk size
@param -s: silent mode
/memlimit 500   : change memory limit to 500mb
/memlimit -v 500   : change visible chunk limit to 500mb
/memlimit -v -s 500   : silent mode
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local max_mem;
		local options = {};
		options, cmd_text = CmdParser.ParseOptions(cmd_text);

		max_mem, cmd_text = CmdParser.ParseInt(cmd_text);
		if(max_mem and max_mem>=10 and max_mem <= 4096) then
			local max_mem_bytes = max_mem*1024*1024;
			-- convert to byte
			local attr = ParaTerrain.GetBlockAttributeObject();
			local isSilentMode = options["s"];
			if(options["v"]) then
				attr:SetField("MaxVisibleVertexBufferBytes", max_mem_bytes);
				if(attr:GetField("VertexBufferSizeLimit", 0) < max_mem_bytes) then
					attr:SetField("VertexBufferSizeLimit", max_mem_bytes);
					if(not isSilentMode) then
						GameLogic.AddBBS(nil, format(L"memory and visible chunk limit changed: %d mb", max_mem));
					end
				else
					if(not isSilentMode) then
						GameLogic.AddBBS(nil, format(L"visible chunk limit changed: %d mb", max_mem));
					end
				end
			else
				attr:SetField("VertexBufferSizeLimit", max_mem_bytes);
				if(not isSilentMode) then
					GameLogic.AddBBS(nil, format(L"memory limit changed: %d mb", max_mem));
				end
			end
		end
	end,
};

Commands["clearcache"] = {
	name="clearcache", 
	quick_ref="/clearcache [web|worlds|all]", 
	mode_deny = "",
	mode_allow = "",
	desc=[[clear locally cached files. 
/clearcache     clear all    
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		-- asset files
		ParaAsset.ClearTextureCache();
		-- world http files
		NPL.load("(gl)script/apps/Aries/Creator/Game/Common/HttpFiles.lua");
		local HttpFiles = commonlib.gettable("MyCompany.Aries.Game.Common.HttpFiles");
		HttpFiles.ClearDiskCache();

		GameLogic.AddBBS(nil, "Downloaded Web Cache Cleared");
	end,
};

Commands["lod"] = {
	name="lod", 
	quick_ref="/lod [on|off]", 
	desc=[[Turn global level of detail for meshes on and off. Default it on. 
/lod off     : turn off lod
/lod on      : turn on lod
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local bLOD;
		bLOD, cmd_text = CmdParser.ParseBool(cmd_text);
		if(bLOD == nil) then
			bLOD = true;
		end
		GameLogic.options:EnableLOD(bLOD);
	end,
};

Commands["fullscreen"] = {
	name="fullscreen", 
	quick_ref="/fullscreen [on|off]", 
	desc=[[full screen mode on or off, only used in windows platform
/fullscreen off     
/fullscreen
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local bFullScreen;
		bFullScreen, cmd_text = CmdParser.ParseBool(cmd_text);
		if(bFullScreen == nil) then
			bFullScreen = true;
		end
		GameLogic.options:SetFullScreenMode(bFullScreen);
	end,
};

Commands["copytoclipboard"] = {
	name="copytoclipboard", 
	quick_ref="/copytoclipboard [text]", 
	desc=[[copy the given text to clipboard
/copytoclipboard hello
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(type(cmd_text) == "string") then
			ParaMisc.CopyTextToClipboard(cmd_text)
		end
	end,
};

Commands["stop"] = {
	name="stop", 
	quick_ref="/stop", 
	desc=[[stop all running code blocks (only for edit mode). Hot key is Ctrl+P.
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(GameLogic.GameMode:IsEditor()) then
			-- stop all code blocks
			local entities = GameLogic.EntityManager.FindEntities({category="b", type="EntityCode"});
			if(entities and #entities>0) then
				local count = 0
				for _, entity in ipairs(entities) do
					if(entity:IsCodeLoaded()) then
						entity:GetCodeBlock():Stop();
						count = count + 1
					end
				end
				GameLogic.AddBBS(nil, format("%d/%d code block is stopped", count, #entities));
			end
		end
	end,
};

Commands["lock"] = {
	name="lock", 
	quick_ref="/lock [duration] [message_text]", 
	desc=[[lock the user's computer for some seconds. 
The user can not click, close or switch window. This is usually used by a teacher host to get students' attention
@param duration: default to 10 seconds. 0 to unlock
e.g. 
/runat @all /lock 10  Look at your teacher
/lock
/lock 60
/lock 10  Look at your teacher
/lock 0 unlock
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local duration;
		duration, cmd_text = CmdParser.ParseNumber(cmd_text);		
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/LockDesktop.lua");
		local LockDesktop = commonlib.gettable("MyCompany.Aries.Game.Tasks.LockDesktop");
		if(duration == 0) then
			-- unlock
			LockDesktop.ShowPage(false, duration, cmd_text);
		else
			-- lock
			LockDesktop.ShowPage(true, duration, cmd_text);
		end
	end,
};
