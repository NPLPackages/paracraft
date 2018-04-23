--[[
Title: World manager
Author(s): WangTian
Date: 2008/4/9
Desc: 
World manager manages all the world packages on the client
Currently the /worlds folder is organized in the following structure:
/worlds __ /worlds/MyWorlds __ /worlds/MyWorlds/Offline <- all user created worlds offline
		|					|_ /worlds/MyWorlds/Online <- deployed worlds, sync with the paraworld server
		|_ /worlds/Templates__ /worlds/Templates/Empty <- Empty world template
		|					|_ /worlds/Templates/Recent <- Recently used world template, items limit
		|					|_ /worlds/Templates/Downloads <- All downloaded templates
		|					|_ /worlds/Templates/Favorites <- My favorite templates
		|_ /worlds/Visited <- visited other user's or offical worlds
		
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/WorldManager.lua");
Map3DSystem.App.worlds.WorldManager....(_app);
------------------------------------------------------------
]]

if(not Map3DSystem.App.worlds.WorldManager) then Map3DSystem.App.worlds.WorldManager = {}; end

-- init the world manager at startup
function Map3DSystem.App.worlds.WorldManager.Init()
	Map3DSystem.App.worlds.WorldManager.GenerateNewWorldWizardTemplatePage("Templates/Empty/");
	Map3DSystem.App.worlds.WorldManager.GenerateNewWorldWizardTemplatePage("Templates/Recent/");
	Map3DSystem.App.worlds.WorldManager.GenerateNewWorldWizardTemplatePage("Templates/Downloads/");
	Map3DSystem.App.worlds.WorldManager.GenerateNewWorldWizardTemplatePage("Templates/Favorites/");
	Map3DSystem.App.worlds.WorldManager.GenerateNewWorldWizardTemplatePage("MyWorlds/");
	log("World manager inited\n");
end

-- init the world manager at startup
-- generate the new world wizard template page
-- @param folder: the directory path that containing the world folders or zip files
--			the template page file will be put in the same folder
function Map3DSystem.App.worlds.WorldManager.GenerateNewWorldWizardTemplatePage(folder)
	
	-- generate the MCML template page file
	
	local sInitDir = Map3DSystem.worlddir..folder;
	
	local s_pe_a = "";
	local s_open_archive = "";
	
	local nMaxNumFiles = 100;
	
	local firstWorldName = "";
	
	-- search all folders
	local search_result = ParaIO.SearchFiles(sInitDir, "*.", "", 0, nMaxNumFiles, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount - 1 do
		
		local sWorldName = search_result:GetItem(i);
		--Map3DSystem.worlddir..folder..sWorldName;
		s_pe_a = s_pe_a..Map3DSystem.App.worlds.WorldManager.SingleTemplate_pe_a(folder, sWorldName);
		
		if(firstWorldName == "") then
			firstWorldName = sWorldName;
		end
	end
	search_result:Release();
	
	-- search all zip packages
	local search_result = ParaIO.SearchFiles(sInitDir, "*.zip", "", 0, nMaxNumFiles, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount - 1 do
		
		local sZipFileName = search_result:GetItem(i);
		local sWorldName = string.gsub(sZipFileName, ".zip", "");
		--Map3DSystem.worlddir..folder..sWorldName;
		s_pe_a = s_pe_a..Map3DSystem.App.worlds.WorldManager.SingleTemplate_pe_a(folder, sWorldName);
		
		if(firstWorldName == "") then
			firstWorldName = sWorldName;
		end
		
		-----------------------------------------------------------------------
		-- TRICK: a little trick here the lua file function is not working
		-- TODO: remove this automaticly zip open to the onload function
		-- automaticly open the zip file on init
		ParaAsset.OpenArchive(Map3DSystem.worlddir..folder..sZipFileName, true);
		-----------------------------------------------------------------------
		
		s_open_archive = s_open_archive..string.format(
[[	ParaAsset.OpenArchive("%s", true);
]], Map3DSystem.worlddir..folder..sZipFileName);
	
	end
	search_result:Release();
	
	
	
	local sTemplateHTMLFileName = Map3DSystem.worlddir..folder.."NewWorldWizardTemplatePage.html";
	local sTemplateLuaFileName = Map3DSystem.worlddir..folder.."NewWorldWizardTemplatePage.lua";
	
	local sFuncName = ParaGlobal.GenerateUniqueID();
	sFuncName = string.gsub(sFuncName, "-", "");
	sFuncName = "f"..sFuncName;
	
	local sPage = "";
	sPage = sPage..string.format([[
<!--%s-->

<pe:mcml onload="%s">
  <!--load the NewWorldWizardPage.lua script for callback functions-->
  <script type="text/npl" src="%s"/>
  <pe:editor style="margin:0px;padding:0px;">
  <div class="box" style="margin:0px;padding:0px;width:280px;height:430px;float:left;">
    <pe:treeview name="NewWorldWizardTemplateView" style="height:430;" ShowIcon="false">
    <div>
]], sTemplateHTMLFileName, sFuncName, sTemplateLuaFileName, ParaGlobal.GenerateUniqueID());
	
	sPage = sPage..s_pe_a;
	
	sPage = sPage..string.format([[
	</div>
	</pe:treeview>
  </div>
  <div class="box" style="margin:0px;padding:0px;width:170px;height:430px;float:left;">
    <iframe src="%s" style="margin:0px;padding:0px;height:350px;width:100px;float:left;" name="WorldInfoIFrame"/>
  </div>
  </pe:editor>
  <div class="box" style="margin:0px;padding:0px;width:450px;height:40px;float:left;">
    <pe:editor>
    World Name: <input name="worldname" type="text" style="width:250px;height:30px"/>
    <input type="submit" class="defaultbutton" name="Create" value="Create World!" style="width:96px;height:26px" onclick="Map3DSystem.mcml.PageCtrl.Pages.NewWorldWizardPage.OnClickCreateWorld"/>
    </pe:editor>
  </div>
</pe:mcml>]], Map3DSystem.worlddir..folder..firstWorldName.."/WorldInfo.html");
	
	--sPage = ParaMisc.EncodingConvert("", "HTML", sPage);
	
	local file = ParaIO.open(sTemplateHTMLFileName, "w");
	if(file:IsValid()) then
		file:WriteString(sPage);
		file:close();
	end
	
	local sLuaFile = "";
	
	sLuaFile = sLuaFile..string.format(
[[function %s()
]], sFuncName);
	
	sLuaFile = sLuaFile..s_open_archive;
	
	sLuaFile = sLuaFile.."end";
	
	--sLuaFile = ParaMisc.EncodingConvert("HTML", "", sLuaFile);
	
	local file = ParaIO.open(sTemplateLuaFileName, "w");
	if(file:IsValid()) then
		file:WriteString(sLuaFile);
		file:close();
	end
end

-- NOTE: internal use only
-- this function will generate a single pe:a tag node string
-- @param sFolder: the parent folder of world file(s)
--		e.x. "Templates/Favorites/"
-- @param sWorldName: the name of the world itself, can be zip file name or world folder
--		e.x. "Wonderland.zip", "PEPortal"
-- @return: the tag string
function Map3DSystem.App.worlds.WorldManager.SingleTemplate_pe_a(sFolder, sWorldName)
	local sWorldName = string.gsub(sWorldName, ".zip", ""); -- remove the zip extension if any
	local sLine = "";
	sLine = string.format(
[[      <pe:a href="%s/WorldInfo.html" name="%s" onclick="Map3DSystem.mcml.PageCtrl.Pages.NewWorldWizardPage.OnClickTemplate" target="WorldInfoIFrame">
]]
	, Map3DSystem.worlddir..sFolder..sWorldName, sFolder..sWorldName);
	sLine = sLine..
[[        <div style="width:64;height:88px;float:left;">
]];
	sLine = sLine..string.format(
[[          <img style="width:64px;height:64px;" src="%s/PreviewSmall.png"/>
]]
, sWorldName);
	sLine = sLine..string.format(
[[          <pe:editor-button name="%s" text="%s" style="width:64px;height:24px;background:;"/>
]]
, sWorldName, sWorldName);
	sLine = sLine..
[[        </div>
      </pe:a>
]];
    
    return sLine;
end