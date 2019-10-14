--[[
Title: Commands
Author(s): LiXizhi
Date: 2013/2/9
Desc: slash command 
use the lib:
------------------------------------------------------------
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


Commands["sky"] = {
	name="sky", 
	quick_ref="/sky [-tex filename] [-add filename] [-clear] [-none] [-sim] [-sun sun_size sun_glow] [-moon moon_size moon_glow] [-cloud thickness]  [sim|white|black|green|filename]", 
	desc=[[change sky model or its textures
-- changing to simulated sky
/sky sim
-- changing to a given model
/sky model/skybox/skybox6/skybox6.x  
-- setting sky's replaceable texture, file can be relative to world dir.
/sky -tex Texture/blocks/cake_top.png
-- use empty white texture
/sky -tex
-- sun size and glow size defaults to 500, 12
/sky -sun sun_size[10-1000] sun_glow
/sky -sun 500 12
-- moon size and glow size defaults to 500, 100
/sky -moon moon_size[10-1000] moon_glow
/sky -moon 500 100
-- cloud density
/sky -cloud density[0-1]
/sky -cloud 0.1
-- add a sub animated mesh to the sky entity. Mesh center should be 0,0,0. radius is 0.5.
/sky -add animated_sun.fbx
-- clear all child meshes
/sky -clear
-- do not show primary sky box. use submeshes only. 
/sky -none
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local option = "";
		local filename;
		while option do
			option, cmd_text = CmdParser.ParseOption(cmd_text)
			if(option == "sun") then
				local sun_size, sun_glow;
				sun_size, cmd_text = CmdParser.ParseInt(cmd_text);
				sun_glow, cmd_text = CmdParser.ParseInt(cmd_text);
				GameLogic.GetSkyEntity():SetSunSize(sun_size or 500, sun_glow or 12);
			elseif(option == "moon") then
				local moon_size, moon_glow;
				moon_size, cmd_text = CmdParser.ParseInt(cmd_text);
				moon_glow, cmd_text = CmdParser.ParseInt(cmd_text);
				GameLogic.GetSkyEntity():SetMoonSize(moon_size or 500, moon_glow or 100);
			elseif(option == "cloud") then
				local cloud;
				cloud, cmd_text = CmdParser.ParseInt(cmd_text);
				GameLogic.options:SetCloudThickness(cloud);
			elseif(option == "tex") then
				filename, cmd_text = CmdParser.ParseString(cmd_text);
				if(filename) then
					NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/LocalTextures.lua");
					local LocalTextures = commonlib.gettable("MyCompany.Aries.Game.Materials.LocalTextures");
					filename = LocalTextures:GetByFileName(commonlib.Encoding.Utf8ToDefault(filename));
					if(filename) then
						GameLogic.GetSkyEntity():SetSkyTexture(filename);
					end
				else
					GameLogic.GetSkyEntity():SetSkyTexture("Texture/whitedot.png");
				end
			elseif(option == "add") then
				filename, cmd_text = CmdParser.ParseString(cmd_text);
				local filepath = Files.GetWorldFilePath(filename);
				if(filepath) then
					GameLogic.GetSkyEntity():AddSubMesh(filepath);	
				else
					GameLogic.AddBBS("skycmd", format(L"文件不存在:%s", filename));
				end
			elseif(option == "clear") then
				GameLogic.GetSkyEntity():ClearSubMeshes();
			elseif(option == "sim") then
				GameLogic.GetSkyEntity():UseSimulatedSky();
			elseif(option == "none") then
				GameLogic.GetSkyEntity():UseNoneSky();
			end
		end

		filename, cmd_text = CmdParser.ParseString(cmd_text);

		if(filename == "sim") then
			GameLogic.GetSkyEntity():UseSimulatedSky();
		elseif(filename == "none") then
			GameLogic.GetSkyEntity():UseNoneSky();
		elseif(filename == "white" or filename=="green" or filename=="black") then
			GameLogic.GetSkyEntity():UseSkybox("");
			if(filename == "green") then
				CommandManager:Run("/fog -skycolor 0 1 0");
				CommandManager:Run("/fog -color 0 1 0");
			elseif(filename == "black") then
				CommandManager:Run("/fog -skycolor 0 0 0");
				CommandManager:Run("/fog -color 0 0 0");
			else
				CommandManager:Run("/fog -skycolor 1 1 1");
				CommandManager:Run("/fog -color 1 1 1");
			end
		elseif(filename) then
			local filepath;
			if(not GameLogic.GetSkyEntity():GetSkyTemplate(filename)) then
				filepath = Files.GetWorldFilePath(filename);
				if(not filepath) then
					if(System.options.IsMobilePlatform) then
						-- for mobile version
						LOG.std(nil, "warn", "SkyCommand", "skybox filename:%s is ignored in mobile version", filename);
						filepath = "model/blockworld/Sky/sky.x";
					else
						GameLogic.AddBBS("skycmd", format(L"文件不存在:%s", filename));
						return;
					end
				end
			end
			GameLogic.GetSkyEntity():UseSkybox(filepath or filename);
		end
	end,
};


Commands["fog"] = {
	name="fog", 
	quick_ref="/fog [-color|skycolor|fogstart|fogend] values", 
	desc= [[Change fog color and range  e.g. 
-- if no option specified it will set fogstart
/fog 100    only start fog after 100 meters and end by view_distance
/fog 0.6    if value is smaller than 1, it means 0.6*view_distance
-- change fog color to white, and disable auto fog color according to time
-- this command is only valid for non-simulated sky mesh. 
/fog -color 1 1 1
-- enable auto fog color according to time of day
/fog
-- change the sky's color to white. 
/fog -skycolor 1 1 1
-- fog start distance
/fog -fogstart 80
-- fog end distance
/fog -fogend 100
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text)
		if(not next(options) or options.fogstart) then
			-- no parameter specified. 
			local fog_start, cmd_text = CmdParser.ParseInt(cmd_text)
			if(fog_start) then
				GameLogic.options.auto_skycolor  = false;
				if(fog_start <= 1 and fog_start>=0) then
					fog_start = fog_start * GameLogic.options:GetRenderDist();
				end
				GameLogic.options:SetFogStart(fog_start);
			else
				GameLogic.options.auto_skycolor  = true;
				GameLogic.GetSim():OnTickDayLight(true);
			end
		elseif(options.color) then
			GameLogic.options.auto_skycolor  = false;
			local att = ParaScene.GetAttributeObject();
			local color = CmdParser.ParseNumberList(cmd_text, list, "|,%s");
			if(color and color[1] and color[2] and color[3]) then
				att:SetField("FogColor", color);
			end
		elseif(options.skycolor) then
			GameLogic.options.auto_skycolor  = false;
			local att = ParaScene.GetAttributeObjectSky();
			local color = CmdParser.ParseNumberList(cmd_text, list, "|,%s");
			if(color and color[1] and color[2] and color[3]) then
				att:SetField("SkyColor", color);
			end
		elseif(options.fogend) then
			GameLogic.options.auto_skycolor  = false;
			local fog_end, cmd_text = CmdParser.ParseInt(cmd_text)
			if(fog_end) then
				GameLogic.options:SetFogEnd(fog_end);
			end
		else
			GameLogic.options.auto_skycolor  = true;
			GameLogic.GetSim():OnTickDayLight(true);
		end
	end,
};


Commands["light"] = {
	name="light", 
	quick_ref="/light [0,2] [0,2] [0,2]", 
	desc="set light block color. if no parameter, 1,1,1 is used. " , 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local r,g,b = CmdParser.ParseColorRGB(cmd_text, 0, 2)
			if(r and g and b) then
				if(ParaTerrain.GetBlockAttributeObject) then
					ParaTerrain.GetBlockAttributeObject():SetField("BlockLightColor", {r,g,b})
				end
			end
		end
	end,
};

Commands["sun"] = {
	name="sun", 
	quick_ref="/sun [0,2] [0,2] [0,2]", 
	desc="set sun color. This will change the diffuse color of all objects.  if no parameter, 1,1,1 is used. " , 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local r,g,b = CmdParser.ParseColorRGB(cmd_text, 0, 2)
			if(r and g and b) then
				-- setting the sun color
				GameLogic.options.auto_skycolor  = false;
				local att = ParaScene.GetAttributeObjectSunLight();
				att:SetField("Diffuse", {r,g,b});
			end
		end
	end,
};

Commands["rain"] = {
	name="rain", 
	quick_ref="/rain [0-10]", 
	desc="change weather to raining. second parameter is intensity" , 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local strength = cmd_text:match("%d*");

		if(strength) then
			strength = tonumber(strength);
		end
		GameLogic.GetSkyEntity():SetRain(strength);
	end,
};


Commands["snow"] = {
	name="snow", 
	quick_ref="/snow [0-10]", 
	desc="change weather to snow. second parameter is intensity" , 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local strength = cmd_text:match("%d*");

		if(strength) then
			strength = tonumber(strength);
		end
		GameLogic.GetSkyEntity():SetSnow(strength);
	end,
};

Commands["day"] = {
	name="day", 
	quick_ref="/day [minutes]", 
	desc=[[how many mins in a day. specify nothing for infinitely long day
/day 20 set how many mins in a day.]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local day_length = cmd_text:match("%d+") or "100000000";
			if(day_length) then
				day_length = tonumber(day_length);
				if(day_length) then
					local old_time = ParaScene.GetTimeOfDaySTD()
					ParaScene.GetAttributeObjectSunLight():SetField("DayLength", day_length);
					ParaScene.SetTimeOfDaySTD(old_time);
				end
			end
		end
	end,
};

Commands["time"] = {
	name="time", 
	quick_ref="/time [-1,1] [now]", 
	desc=[[set current time of day. 0 or nil means noon, -0.5 is dawn, 0.5 is twilight. 1,-1 is midnight
@return: the current time in range [-1, 1]. 
Example:
/time 0		set time to mid noon
/tip $(/time now)   return current time
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local now;
			now, cmd_text = CmdParser.ParseText(cmd_text, "now");
			if(now) then
				return GameLogic.GetSim():GetTimeOfDaySTD();
			end

			local time_of_day = cmd_text:match("%-?[%d%.]+") or "0";
			if(time_of_day) then
				time_of_day = tonumber(time_of_day);
				if(time_of_day) then
					GameLogic.GetSim():SetTimeOfDayStd(time_of_day);
				end
			end
		end
	end,
};