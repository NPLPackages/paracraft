--[[
Title: The load world function for paraworld
Author(s): LiXizhi(code&logic), WangTian
Date: 2006/1/26
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/loadworld.lua");
Map3DSystem.UI.LoadWorld.LoadWorldImmediate("worlds/empty")
------------------------------------------------------------
]]
local L = CommonCtrl.Locale("IDE");

local LoadWorld = commonlib.gettable("Map3DSystem.UI.LoadWorld")

--[[ load a world immediately without doing any error checking or report. This is usually called by ParaIDE from the Load world menu. 
@param worldpath: the directory containing the world config file, such as "sample","worlds/demo" 
or it can also be a [worldname].zip file that contains the world directory. 
@param bPerserveUI: if true, UI are not cleared. default to nil
@param bHideProgressUI: if true, progress UI is hidden. default to nil
@param OnProgressCallBack: nil or a function of function(percent) end, where percent is between [0,100]
]]
function Map3DSystem.UI.LoadWorld.LoadWorldImmediate(worldpath, bPerserveUI, bHideProgressUI, OnProgressCallBack)
	if(worldpath) then
		worldpath = string.gsub(worldpath, "[/\\]+$", "")
	end	
	if(string.find(worldpath, ".*%.zip$")~=nil or string.find(worldpath, ".*%.pkg$")~=nil) then
		-- open zip archive with relative path
		if(Map3DSystem.World.worldzipfile and Map3DSystem.World.worldzipfile~= worldpath) then
			ParaAsset.CloseArchive(Map3DSystem.World.worldzipfile); -- close last world archive
		end
		Map3DSystem.World.worldzipfile = worldpath;
		
		ParaAsset.OpenArchive(worldpath, true);

		ParaIO.SetDiskFilePriority(-1);
		local search_result = ParaIO.SearchFiles("","*.", worldpath, 0, 10, 0);
		local nCount = search_result:GetNumOfResult();
		if(nCount>0) then
			-- just use the first directory in the world zip file as the world name.
			local WorldName = search_result:GetItem(0);
			WorldName = string.gsub(WorldName, "[/\\]$", "");
			worldpath = string.gsub(worldpath, "([^/\\]+)%.%w%w%w$", WorldName); -- get rid of the zip file extension for display 
		else
			-- make it the directory path
			worldpath = string.gsub(worldpath, "(.*)%.%w%w%w$", "%1"); -- get rid of the zip file extension for display 		
		end
		if(not ParaIO.DoesFileExist(worldpath, false)) then
			ParaIO.SetDiskFilePriority(0);
		else
			LOG.std(nil, "warn", "loadworld", "opening zip file while disk file already exist, use zip priority now");
		end
		Map3DSystem.World.readonly = true;
		
		NPL.load("(gl)script/ide/sandbox.lua");
		ParaSandBox.ApplyToWorld(nil);
		ParaSandBox.Reset();

		-- DISABLED: create and apply a sandbox for read only world, such as those downloaded from the network. 
		--local sandbox = ParaSandBox:GetSandBox("script/kids/pw_sandbox_file.lua");
		--sandbox:Reset();
		--ParaSandBox.ApplyToWorld(sandbox);
		
	else
		if(Map3DSystem.World.worldzipfile) then
			ParaAsset.CloseArchive(Map3DSystem.World.worldzipfile); 
		end	
		Map3DSystem.World.worldzipfile = nil;
		Map3DSystem.World.readonly = nil;	
		ParaIO.SetDiskFilePriority(0);
		
		-- do not use a sandbox for writable world.
		NPL.load("(gl)script/ide/sandbox.lua");
		ParaSandBox.ApplyToWorld(nil);
		ParaSandBox.Reset();
	end
	
	Map3DSystem.world.name = worldpath;
	
	Map3DSystem.world:UseDefaultFileMapping();
	
	if(ParaIO.DoesAssetFileExist(Map3DSystem.world.sConfigFile, true)) then
		if(Map3DSystem.UI.LoadWorld.LoadWorld(bPerserveUI, bHideProgressUI, OnProgressCallBack) == true) then
			-- make adiministrator by default, one needs to set a different role after this function return.
			Map3DSystem.User.SetRole("administrator");
			return true;
		else
			return worldpath..L" failed loading the world."
		end
	else
		LOG.std(nil, "error", "LoadWorld", "unable to find file: %s", Map3DSystem.world.sConfigFile or "");
		return worldpath..L" world does not exist"
	end	
end

-- private: clear the scene and load the world using the settings in the Map3DSystem, return false if failed.
-- @param bPerserveUI: if true, UI are not cleared and progress bar are not disabled. default to nil
-- @param bHideProgressUI: if true, progress UI is hidden. default to nil
-- @param OnProgressCallBack: nil or a function of function(percent) end, where percent is between [0,100]
function Map3DSystem.UI.LoadWorld.LoadWorld(bPerserveUI, bHideProgressUI, OnProgressCallBack)
	-- clear the scene
	Map3DSystem.reset(bPerserveUI);
	
	if(Map3DSystem.World.sConfigFile ~= "") then
		if(OnProgressCallBack) then
			OnProgressCallBack(0)
		end
		-- disable the game 
		ParaScene.EnableScene(false);
		if(not bHideProgressUI) then
			NPL.load("(gl)script/kids/3DMapSystemUI/InGame/LoaderUI.lua");
			Map3DSystem.UI.LoaderUI.Start(100);
			Map3DSystem.UI.LoaderUI.SetProgress(20);
		end	
		if(OnProgressCallBack) then
			OnProgressCallBack(20)
		end
		
		-- TODO: security alert, this is not in sandbox.  call the preload script for the given world
		local sOnLoadScript = string.gsub(Map3DSystem.World.sConfigFile, "[^/\\]+$", "preload.lua");
		if(ParaIO.DoesAssetFileExist(sOnLoadScript, true))then
			NPL.load("(gl)"..sOnLoadScript, true);
		end
		
		-- create world
		ParaScene.CreateWorld("", 32000, Map3DSystem.World.sConfigFile); 
		if(not bHideProgressUI) then
			Map3DSystem.UI.LoaderUI.SetProgress(30);
		end	
		if(OnProgressCallBack) then
			OnProgressCallBack(30)
		end
		
		-- load from database
		Map3DSystem.world:LoadWorldFromDB();
		if(not bHideProgressUI) then
			Map3DSystem.UI.LoaderUI.SetProgress(100);
		end	
		if(OnProgressCallBack) then
			OnProgressCallBack(100)
		end
		
		-- clear autotips elsewhere
		if(autotips) then
			autotips.Clear()
		end	
	
		-- we have built the scene, now we can enable the game
		ParaScene.EnableScene(true);
		if(not bHideProgressUI) then
			Map3DSystem.UI.LoaderUI.End();
		end	
		Map3DSystem.PushState("game");
		
		return true;
	else
		return false;
	end
end
