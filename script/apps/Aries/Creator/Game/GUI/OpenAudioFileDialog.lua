--[[
Title: Open File Dialog
Author(s): LiXizhi
Date: 2015/9/20
Desc: Display a dialog with text that let user to enter filename in current world directory. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAudioFileDialog.lua");
local OpenAudioFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAudioFileDialog");
OpenAudioFileDialog.ShowPage("Please enter text", function(result)
	echo(result);
end, default_text, title, filters)

OpenAudioFileDialog.ShowPage("Please enter text", function(result)
	echo(result);
end, default_text, title, filters, nil, function(filename) 
	echo(filename)
end)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local OpenAudioFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAudioFileDialog");
-- whether in save mode. 
OpenAudioFileDialog.IsSaveMode = false;

local page;
function OpenAudioFileDialog.OnInit()
	page = document:GetPageCtrl();
end

-- @param filterName: "model", "bmax", "audio", "texture", "xml", "script"
function OpenAudioFileDialog.GetFilters(filterName)
	return {
		{L"全部文件(*.mp3,*.ogg,*.wav)",  "*.mp3;*.ogg;*.wav;*.mid"},
		{L"mp3(*.mp3)",  "*.mp3"},
		{L"ogg(*.ogg)",  "*.ogg"},
		{L"wav(*.wav)",  "*.wav"},
	};
end

-- @param default_text: default text to be displayed. 
-- @param filters: "model", "bmax", "audio", "texture", "xml", nil for any file, or filters table
-- @param editButton: this can be nil or a function(filename) end or {text="edit", callback=function(filename) end}
-- the callback function can return a new filename to be displayed. 
function OpenAudioFileDialog.ShowPage(text, OnClose, default_text, title, IsSaveMode, editButton)
	OpenAudioFileDialog.result = nil;
	OpenAudioFileDialog.text = text;
	OpenAudioFileDialog.title = title;
	OpenAudioFileDialog.type = filters

	OpenAudioFileDialog.filters = OpenAudioFileDialog.GetFilters(filters);
	OpenAudioFileDialog.editButton = editButton;
	OpenAudioFileDialog.IsSaveMode = IsSaveMode == true;
	OpenAudioFileDialog.category_index = 1
	OpenAudioFileDialog.InitOfficialAudio()
	OpenAudioFileDialog.UpdateExistingFiles();

	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/OpenAudioFileDialog.html", 
			name = "OpenAudioFileDialog.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			isTopLevel = true,
			---app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -230,
				y = -220,
				width = 460,
				height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	if(default_text) then
		params._page:SetUIValue("text", commonlib.Encoding.DefaultToUtf8(default_text));
	end
	params._page.OnClose = function()
		if(OnClose) then
			OnClose(OpenAudioFileDialog.result);
		end
	end
	
	params._page.OnDropFiles = function(filelist)
		if filelist then
			local _, firstFile = next(filelist);
			
			if(firstFile and page) then
				local fileItem = Files.ResolveFilePath(firstFile);
				if(fileItem and fileItem.relativeToWorldPath) then
					local filename = fileItem.relativeToWorldPath;
					params._page:SetValue("text", commonlib.Encoding.DefaultToUtf8(filename));
				end
			end
			
			return true;
		else
			return false;
		end
	end
end


function OpenAudioFileDialog.OnOK()
	if(page) then
		OpenAudioFileDialog.OnCloseWithResult(commonlib.Encoding.Utf8ToDefault(page:GetValue("text")))
	end
end

function OpenAudioFileDialog.OnCloseWithResult(result)
	if(page) then
		OpenAudioFileDialog.result = result
		page:CloseWindow();
	end
end

function OpenAudioFileDialog.OnClose()
	if(page) then
		page:CloseWindow();
	end
end

function OpenAudioFileDialog.IsSelectedFromExistingFiles()
	return OpenAudioFileDialog.lastSelectedFile == OpenAudioFileDialog.result;
end

function OpenAudioFileDialog.GetExistingFiles()
	if OpenAudioFileDialog.category_index == 1 then
		return OpenAudioFileDialog.dsExistingFiles or {};
	else
		return OpenAudioFileDialog.OfficialAudioList or {};
	end
	
end

function OpenAudioFileDialog.GetSearchDirectory()
	return ParaWorld.GetWorldDirectory()
end

function OpenAudioFileDialog.InitOfficialAudio()
	if nil == OpenAudioFileDialog.OfficialAudioList then
		local result = {
			{show_name="黑暗森林", filename="Audio/Haqi/AriesRegionBGMusics/ambForest.ogg"},
			{show_name="黑暗森林海", filename="Audio/Haqi/AriesRegionBGMusics/ambDarkForestSea.ogg"},
			{show_name="黑暗平原", filename="Audio/Haqi/AriesRegionBGMusics/ambDarkPlain.ogg"},
			{show_name="荒漠", filename="Audio/Haqi/AriesRegionBGMusics/ambDesert.ogg"},
			{show_name="森林1", filename="Audio/Haqi/AriesRegionBGMusics/ambForest.ogg"},
			{show_name="草原", filename="Audio/Haqi/AriesRegionBGMusics/ambGrassland.ogg"},
			{show_name="海洋", filename="Audio/Haqi/AriesRegionBGMusics/ambOcean.ogg"},
			{show_name="嘉年华1", filename="Audio/Haqi/AriesRegionBGMusics/Area_Carnival.ogg"},
			{show_name="圣诞节", filename="Audio/Haqi/AriesRegionBGMusics/Area_Christmas.ogg"},
			{show_name="火洞1", filename="Audio/Haqi/AriesRegionBGMusics/Area_FireCavern.ogg"},
			{show_name="森林2", filename="Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg"},
			{show_name="新年", filename="Audio/Haqi/AriesRegionBGMusics/Area_NewYear.ogg"},
			{show_name="下雪", filename="Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg"},
			{show_name="阳光海滩1", filename="Audio/Haqi/AriesRegionBGMusics/Area_SunnyBeach.ogg"},
			{show_name="城镇", filename="Audio/Haqi/AriesRegionBGMusics/Area_Town.ogg"},
			{show_name="音乐盒-来自舞者", filename="Audio/Haqi/Homeland/MusicBox_FromDancer.ogg"},
			{show_name="并行世界", filename="Audio/Haqi/keepwork/common/bigworld_bgm.ogg"},
			{show_name="开场引导音", filename="Audio/Haqi/keepwork/common/guide_bgm.ogg"},
			{show_name="登录音效", filename="Audio/Haqi/keepwork/common/login_bgm.ogg"},
			{show_name="小游戏音效", filename="Audio/Haqi/keepwork/common/minigame_bgm.ogg"},
			{show_name="单机音效", filename="Audio/Haqi/keepwork/common/offline_bgm.ogg"},
			{show_name="行星环绕音效", filename="Audio/Haqi/keepwork/common/planet_bgm.ogg"},
			{show_name="音频主题", filename="Audio/Haqi/New/cAudioTheme1.ogg"},
			{show_name="游戏背景乐1", filename="Audio/Haqi/OldFiles/game_bg1.ogg"},
			{show_name="游戏背景乐2", filename="Audio/Haqi/OldFiles/game_bg2.ogg"},
			{show_name="游戏背景乐3", filename="Audio/Haqi/OldFiles/game_bg3.ogg"},
			{show_name="马里奥", filename="Audio/Haqi/OldFiles/Mario.ogg"},
			{show_name="马里奥低音", filename="Audio/Haqi/OldFiles/MarioLow.ogg"},
			{show_name="MIDI", filename="Audio/Haqi/OldFiles/MIDI01.ogg"},
			{show_name="任务完成", filename="Audio/Haqi/OldFiles/MissionComplete.ogg"},
			{show_name="音乐盒1", filename="Audio/Haqi/OldFiles/MusicBox1.ogg"},
			{show_name="音乐盒2", filename="Audio/Haqi/OldFiles/MusicBox2.ogg"},
			{show_name="音乐盒3", filename="Audio/Haqi/OldFiles/MusicBox3.ogg"},
			{show_name="创建植物", filename="Audio/Haqi/OldFiles/plant_create.ogg"},
			{show_name="水马", filename="Audio/Haqi/OldFiles/Region_AquaHorse.ogg"},
			{show_name="蜜蜂", filename="Audio/Haqi/OldFiles/Region_Bee.ogg"},
			{show_name="嘉年华2", filename="Audio/Haqi/OldFiles/Region_Carnival.ogg"},
			{show_name="龙森林", filename="Audio/Haqi/OldFiles/Region_DragonForest.ogg"},
			{show_name="火洞2", filename="Audio/Haqi/OldFiles/Region_FireCavern.ogg"},
			{show_name="跳跳农场", filename="Audio/Haqi/OldFiles/Region_JumpJumpFarm.ogg"},
			{show_name="春天生活", filename="Audio/Haqi/OldFiles/Region_LifeSpring.ogg"},
			{show_name="魔法森林", filename="Audio/Haqi/OldFiles/Region_MagicForest.ogg"},
			{show_name="阳光海滩2", filename="Audio/Haqi/OldFiles/Region_SunnyBeach.ogg"},
			{show_name="城镇广场", filename="Audio/Haqi/OldFiles/Region_TownSquare.ogg"},
			{show_name="多彩舞曲08", filename="Audio/Haqi/New/RICH08.ogg"},
			{show_name="多彩舞曲16", filename="Audio/Haqi/New/RICH16.ogg"},
			{show_name="多彩舞曲17", filename="Audio/Haqi/New/RICH17.ogg"},
			{show_name="多彩舞曲18", filename="Audio/Haqi/New/RICH18.ogg"},
			{show_name="多彩舞曲19", filename="Audio/Haqi/New/RICH19.ogg"},
			{show_name="多彩舞曲20", filename="Audio/Haqi/New/RICH20.ogg"},
			{show_name="多彩舞曲21", filename="Audio/Haqi/New/RICH21.ogg"},
			{show_name="科技舞曲", filename="Audio/Haqi/New/Techno_1.ogg"},
		}

		local files = {}
		for i = 1, #result do
			files[#files+1] = {name="file", attr=result[i]};
		end

		OpenAudioFileDialog.OfficialAudioList = files
	end
end

function OpenAudioFileDialog.UpdateExistingFiles()
	NPL.load("(gl)script/ide/Files.lua");
	local rootPath = OpenAudioFileDialog.GetSearchDirectory();

	local filter, filterFunc;
	local searchLevel = 2;
	if(OpenAudioFileDialog.filters) then
		filter = OpenAudioFileDialog.filters[OpenAudioFileDialog.curFilterIndex or 1];
		if(filter) then
			searchLevel = filter.searchLevel or searchLevel
			if(filter.filterFunc) then
				filterFunc = filter.filterFunc;
			else
				local filterText = filter[2];
				if(filterText) then
					-- "*.fbx;*.x;*.bmax;*.xml"
					local exts = {};
					local excludes;
					for ext in filterText:gmatch("%*%.([^;]+)") do
						exts[#exts + 1] = "%."..ext.."$";
					end
					if(filter.exclude) then
						excludes = excludes or {};
						for ext in filter.exclude:gmatch("%*%.([^;]+)") do
							excludes[#excludes + 1] = "%."..ext.."$";
						end
					end
				
					-- skip these system files and all files under blockWorld.lastsave/
					local skippedFiles = {
						["LocalNPC.xml"] = true,
						["entity.xml"] = true,
						["players/0.entity.xml"] = true,
						["revision.xml"] = true,
						["tag.xml"] = true,
					}

					filterFunc = function(item)
						if(not skippedFiles[item.filename] and not item.filename:match("^blockWorld")) then
							if(excludes) then
								for i=1, #excludes do
									if(item.filename:match(excludes[i])) then
										return;
									end
								end
							end
							for i=1, #exts do
								if(item.filename:match(exts[i])) then
									return true;
								end
							end
						end
					end
				end
			end
		end
	end
	local files = {};
	OpenAudioFileDialog.dsExistingFiles = files;
	local result = commonlib.Files.Find({}, rootPath, searchLevel, 500, filterFunc);
	for i = 1, #result do
		files[#files+1] = {name="file", attr=result[i]};
	end
	
	if(System.World.worldzipfile) then
		local zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(System.World.worldzipfile);
		local zipParentDir = zip_archive:GetField("RootDirectory", "");
		if(zipParentDir~="") then
			if(rootPath:sub(1, #zipParentDir) == zipParentDir) then
				rootPath = rootPath:sub(#zipParentDir+1, -1)
				local result = commonlib.Files.Find({}, rootPath, searchLevel, 500, ":.", System.World.worldzipfile);
				for i = 1, #result do
					if(type(filterFunc) == "function" and filterFunc(result[i])) then
						result[i].filename = commonlib.Encoding.Utf8ToDefault(result[i].filename);
						files[#files+1] = {name="file", attr=result[i]};
					end
				end
			end
		end
	end
	table.sort(files, function(a, b)
		return (a.attr.writedate or 0) > (b.attr.writedate or 0);
	end);
end

function OpenAudioFileDialog.OnOpenAudioFileDialog()
	NPL.load("(gl)script/ide/OpenAudioFileDialog.lua");

	local filename = CommonCtrl.OpenFileDialog.ShowDialog_Win32(OpenAudioFileDialog.filters, 
		OpenAudioFileDialog.title,
		OpenAudioFileDialog.GetSearchDirectory(), 
		OpenAudioFileDialog.IsSaveMode);
		
	if(filename and page) then
		local fileItem = Files.ResolveFilePath(filename);
		if(fileItem) then
			if(fileItem.relativeToWorldPath) then
				local filename = fileItem.relativeToWorldPath;
				page:SetValue("text", commonlib.Encoding.DefaultToUtf8(filename));
			elseif(fileItem.relativeToRootPath) then
				local filename = fileItem.relativeToRootPath;
				page:SetValue("text", commonlib.Encoding.DefaultToUtf8(filename));
			else
				filename = filename:match("[^/\\]+$")
				page:SetValue("text", commonlib.Encoding.DefaultToUtf8(filename));
			end
		end
	end
end

function OpenAudioFileDialog.GetText()
	return OpenAudioFileDialog.text or L"请输入:";
end

function OpenAudioFileDialog.OnClickEdit()
	local filename = commonlib.Encoding.Utf8ToDefault(page:GetValue("text"));
	local callback;
	if(type(OpenAudioFileDialog.editButton) == "function") then
		callback = OpenAudioFileDialog.editButton;
	elseif(type(OpenAudioFileDialog.editButton) == "table") then
		callback = OpenAudioFileDialog.editButton.callback;
	end
	if(callback) then
		local new_filename = callback(filename);
		if(new_filename and new_filename~=filename) then
			page:SetValue("text", commonlib.Encoding.DefaultToUtf8(new_filename));
		end
	end
end

function OpenAudioFileDialog.OnChangeCategory(index)
	OpenAudioFileDialog.category_index = index
	OpenAudioFileDialog.RefreshPage()
end

function OpenAudioFileDialog.RefreshPage()
	if page then
		page:Refresh(0)

		-- page:CallMethod("tvwExistingFiles", "SetDataSource", OpenAudioFileDialog.GetExistingFiles());
		-- page:CallMethod("tvwExistingFiles", "DataBind", true);
	end
end

function OpenAudioFileDialog.GetTreeNodeText(item_data)
	local text = ""
    if OpenAudioFileDialog.category_index == 1 then
		text = string.format("%s (%dKB) %s", commonlib.Encoding.DefaultToUtf8(item_data.filename), math.ceil(item_data.filesize/1000), item_data.writedate)
	else
		text = item_data.show_name
    end

    return text 
end