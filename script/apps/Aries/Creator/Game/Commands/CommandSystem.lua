--[[
Title: system command
Author(s): LiXizhi
Date: 2014/11/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandSystem.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["system"] = {
	name="system", 
	quick_ref="/system [settingchange|exit]", 
	desc=[[refresh system settings
/system settingchange
]] , 
	handler = function(cmd_name, cmd_text, cmd_params)
		local name;
		name, cmd_text = CmdParser.ParseString(cmd_text);

		if(not name or name=="settingchange") then
			GameLogic.GetEvents():DispatchEvent({type = "System.SettingChange", });
		elseif(name == "exit") then
			-- TODO:
		end
	end,
};

Commands["texture"] = {
	name="texture", 
	quick_ref="/texture [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]", 
	mode_deny = "",
	mode_allow = "",
	desc=[[set texture packs. default to 0
/texture 0   --默认材质
/texture 1   --混搭材质包
/texture 2   --折纸材质包
/texture 3   --折纸材质包2
/texture 4   --孙子兵法折纸风格
/texture 5   --奇幻混搭风材质包
/texture 6   --商业市区材质包
	]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local texture_type = tonumber(cmd_text:match("([%d%.]+)") or 1);
			if (texture_type < 0 or texture_type > 6) then
				return;
			end
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
			local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
			local package;
			if (texture_type == 0) then
				package = TextureModPage.GetLocalTexturePackDS()[1];
			elseif (texture_type == 6) then
				package = TextureModPage.GetOfficialTexturePackDS()[16];
			else
				package = TextureModPage.GetOfficialTexturePackDS()[texture_type];
			end
			if (package) then
				if (package:IsDownloaded()) then
					TextureModPage.OnApplyTexturePack(nil, nil, nil, package);
				else
					package:DownloadRemoteFile(function (bSuccess)
						if(bSuccess) then
							TextureModPage.OnApplyTexturePack(nil, nil, nil, package);
						else
							_guihelper.MessageBox(string.format(L"官方材质包【%s】下载失败",package.text));
						end	
					end);
				end
			end
		end
	end,
};

Commands["profiler"] = {
	name="profiler", 
	quick_ref="/profiler [-options] [-start|stop|duration_seconds] [filename]", 
	desc=[[start profiler (requires luajit 2.1 or above)
@param -options: default to "-4si4m1". 
@param duration_seconds: auto start and stop profile in these interval seconds. default to 5. 
@param filename: default to "temp/profile.txt". Each line is a function that takes most CPU ranked by percentage. 

/profiler    same as below: run for the next 5 seconds
/profiler -4si4m1    samples four stack levels deep in 4ms intervals and shows a split view of the CPU consuming functions and their callers with a 1% threshold.
/profiler -G
/profiler -5 temp/profile.txt
/profiler -10    profile for 10 seconds 
/profiler -start temp/profile.txt
/profiler -stop


-Options:
f — Stack dump: function name, otherwise module:line. This is the default mode.
F — Stack dump: ditto, but dump module:name.
l — Stack dump: module:line.
<number> — stack dump depth (callee ← caller). Default: 1.
-<number> — Inverse stack dump depth (caller → callee).
s — Split stack dump after first stack level. Implies depth ≥ 2 or depth ≤ -2.
p — Show full path for module names.
v — Show VM states.
z — Show zones.
r — Show raw sample counts. Default: show percentages.
a — Annotate excerpts from source code files.
A — Annotate complete source code files.
G — Produce raw output suitable for graphical tools.
m<number> — Minimum sample percentage to be shown. Default: 3%.
i<number> — Sampling interval in milliseconds. Default: 10ms.

]] , 
	handler = function(cmd_name, cmd_text, cmd_params)
		local options, start, stop, duration_seconds, filename;
		local option_name = "";
		while (option_name and cmd_text) do
			option_name, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option_name == "start") then
				start = true;
			elseif(option_name == "stop") then
				stop = true;
			elseif(option_name and option_name:match("^%d+$")) then
				duration_seconds = tonumber(option_name);
			elseif(option_name) then
				options = option_name;
			end
		end
		options = options or "4si4m1"
		duration_seconds = duration_seconds or 5
		filename = filename or "temp/profile.txt"

		local p = NPL.load("script/ide/Debugger/JITProfiler.lua")
		if(not p) then
			return
		end
		if(start) then
			p.start(options, filename)
		elseif(stop) then
			p.stop();
		elseif(duration_seconds) then
			p.start(options, filename)
			commonlib.TimerManager.SetTimeout(function()
				p.stop() 
			end, duration_seconds*1000)
		end
	end,
};