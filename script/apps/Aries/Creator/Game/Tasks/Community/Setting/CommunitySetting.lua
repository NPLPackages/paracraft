--[[
    Author: <pbb>
    Date: 2024/05/15
    Description: This script is used to create a community setting page.
    useLib:
        local CommunitySetting = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Setting/CommunitySetting.lua")
        CommunitySetting.ShowPage()
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
NPL.load("(gl)script/apps/Aries/Scene/main.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua");
local Scene = commonlib.gettable("MyCompany.Aries.Scene");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local Screen = commonlib.gettable("System.Windows.Screen");

local base_texture_path = "Texture/Aries/Creator/keepwork/"
local tabData = {
    {value = L"显示",name ="show",icon=base_texture_path.."community_32bits.png#562 214 20 20", icon1 = base_texture_path.."community_32bits.png#562 178 20 20"},
    {value = L"声音",name ="sound",icon=base_texture_path.."community_32bits.png#778 214 20 20", icon1 = base_texture_path.."community_32bits.png#742 214 20 20"},
    {value = L"操作",name ="operate",icon=base_texture_path.."community_32bits.png#674 38 20 20", icon1 = base_texture_path.."community_32bits.png#662 74 20 20"},
    {value = L"其他",name ="other",icon=base_texture_path.."community_32bits.png#698 74 20 20", icon1 = base_texture_path.."community_32bits.png#702 2 20 20"},
}
local page
local CommunitySetting = NPL.export()
CommunitySetting.category_ds_index = -1

CommunitySetting.mouse_select_list = {
	["DeleteBlock"] = "left",
	["CreateBlock"] = "right",
	["ChooseBlock"] = "middle",
}

CommunitySetting.setting_ds = {};

local function UpdateCheckBox(name, bChecked)
	local useDefaultStyle = GameLogic.GetFilters():apply_filters('CommunitySetting.CheckBoxBackground', page, name, bChecked);
	if(page) then
		bChecked = bChecked == true or bChecked == "true";
		if (useDefaultStyle or useDefaultStyle == nil) then
			local switchA = base_texture_path .. "community_32bits.png;460 68 50 26"
			local switchB = base_texture_path .. "community_32bits.png;393 68 50 26"

			page:CallMethod(
				name,
				"SetUIBackground",
				bChecked and switchA or switchB
			);
		end
	end
end

local function UpdateSliderBarValue(name,value)
	if(page) then
		page:SetValue(name, value);
	end
end


function CommunitySetting.OnInit()
    page = document:GetPageCtrl()
	page.OnClose = CommunitySetting.OnClose;
	CommunitySetting.setting_ds = {};
	CommunitySetting.InitPageParams()
end

function CommunitySetting.OnClose()
	CommunitySetting.category_ds_index = 1
	Screen:Disconnect("sizeChanged", CommunitySetting, CommunitySetting.OnResize, "UniqueConnection")
end

function CommunitySetting.ShowPage()
	local view_width = 0
	local view_height = 0
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Community/Setting/CommunitySetting.html",
			name = "CommunitySetting.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			zorder = 2,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isTopLevel = true,
			directPosition = true,
				align = "_fi",
				x = -view_width/2,
				y = -view_height/2,
				width = view_width,
				height = view_height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	CommunitySetting.InitSoundDevice()
	CommunitySetting.OnChangeTabview(1)
end


function CommunitySetting.CloseView()
	CommunitySetting.category_ds_index = -1
end

function CommunitySetting.RefreshPage(time)
    if page then
        page:Refresh(time or 0)
		if (CommunitySetting.category_ds_index == 2) then
			CommunitySetting.InitSoundDevice()
		end
    end
end

function CommunitySetting.IsVisible()
	return page:IsVisible()
end

function CommunitySetting.GetCategoryDSIndex()
	return CommunitySetting.category_ds_index
end

function CommunitySetting.GetMenuData()
	return tabData
end

function CommunitySetting.OnChangeTabview(index)
	local tabId = tonumber(index)
	if tabId and tabId > 0 and tabId <= #tabData then
		CommunitySetting.ChangeTab(tabId)
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.setting_page.click_tab", {useNoId=true},nil,true);
	end
end

function CommunitySetting.ChangeTab(tabId)
	if CommunitySetting.category_ds_index ~= tabId then
		CommunitySetting.category_ds_index = tabId
		CommunitySetting.RefreshPage()
	end
end

function CommunitySetting.OnClickEnableSound()
	local cur_state = CommunitySetting.setting_ds["open_sound"];
	local next_state = not cur_state;
	CommunitySetting.setting_ds["open_sound"] = next_state;
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.setting_page.click_sound_enable", {useNoId=true},nil,true);
	if(page)then
		if(next_state) then
			local key = "Paracraft_System_Sound_Volume"
			local sound_volume = Game.PlayerController:LoadLocalData(key,1,true);
			if sound_volume <= 0 then
				sound_volume = 1
			end
			ParaAudio.SetVolume(sound_volume);
		else
			ParaAudio.SetVolume(0);
		end
		CommunitySetting.RefreshPage()
	end
	local MapArea = commonlib.gettable("MyCompany.Aries.Desktop.MapArea");
	if(MapArea.EnableMusic) then
		MapArea.EnableMusic(next_state);
	end
	local key = "Paracraft_System_Sound_State";
	GameLogic.GetPlayerController():SaveLocalData(key,next_state,true);
end

function CommunitySetting.InitSoundDevice()
	if page then
		print("init sound device============",CommunitySetting.currentAudioDevice)
		page:SetValue("AudioDevice", CommunitySetting.currentAudioDevice);
	end
	
	local cur_state = CommunitySetting.setting_ds["open_sound"];
	UpdateCheckBox("btn_EnableSound", cur_state)
end

function CommunitySetting.onClickShowDevice()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.setting_page.click_show_device", {useNoId=true},nil,true);
	local nodeDevice = ParaUI.GetUIObject("device_container")
	if nodeDevice and nodeDevice:IsValid() then
		nodeDevice.visible = not nodeDevice.visible
	end
end

function CommunitySetting.onDeviceClick(name,value)
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.setting_page.click_select_device", {useNoId=true},nil,true);
	local index = tonumber(value)
	if index and index > 0 then
		local devices = CommunitySetting.GetAudioDevices()
		local curdevice = devices[index].value
		if (curdevice ~= CommunitySetting.currentAudioDevice) then
			AudioEngine.ResetAudioDevice(curdevice)
			CommunitySetting.currentAudioDevice = curdevice
			CommunitySetting.InitSoundDevice()
		end
	end
end

function CommunitySetting.OnClickResetAudioDevice()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.setting_page.click_reset_device", {useNoId=true},nil,true);
	AudioEngine.ResetAudioDevice();
	CommunitySetting.currentAudioDevice = nil;
	CommunitySetting.RefreshPage()
end

function CommunitySetting.GetAudioDevices()
	local deviceList = {};
	local devices = ParaEngine.GetAttributeObject():GetField("AudioDeviceName", "");
	if (devices and devices ~= "") then
		local names = commonlib.split(devices, ";");
		for i = 1, #names do
			deviceList[#deviceList + 1] = {text = commonlib.Encoding.DefaultToUtf8(names[i]), value = names[i]};
		end
	end
	if (not CommunitySetting.currentAudioDevice and #deviceList > 0) then
		CommunitySetting.currentAudioDevice = deviceList[1].value;
	end
	return deviceList;
end

function CommunitySetting.InitPageParams()
	if(page==nil) then
		return
	end
	local ds = CommunitySetting.setting_ds;
	-- load the current settings. 
	local att = ParaEngine.GetAttributeObject();
	-- 反转鼠标
	local mouse_inverse = att:GetField("IsMouseInverse", false);
	UpdateCheckBox("btn_MouseInverse", mouse_inverse);
	ds["mouse_inverse"] = mouse_inverse;

	-- 全屏
	local is_full_screen = att:GetField("IsWindowMaximized", false);
	UpdateCheckBox("btn_FullScreenMode", is_full_screen)
	print("init is_full_screen", is_full_screen)
	ds["is_full_screen"] = is_full_screen;

	-- 分辨率
	local screen_resolution =  string.format("%d × %d", att:GetDynamicField("ScreenWidth", 1020), att:GetDynamicField("ScreenHeight", 680))
	page:SetNodeValue("ScreenResolution", screen_resolution) -- 分辨率	
	ds["screen_resolution"] = screen_resolution;
	
	-- 音乐开关
	local open_sound = if_else(ParaAudio.GetVolume()>0,true,false)
	UpdateCheckBox("btn_EnableSound", open_sound)
	ds["open_sound"] = open_sound;

	-- 音量大小
	local sound_volume = Game.PlayerController:LoadLocalData("Paracraft_System_Sound_Volume",1,true);
	ds["sound_volume"] = sound_volume;

	--触屏模式
	local touchEnable = Game.PlayerController:LoadLocalData("Paracraft_System_Touch_Model",nil,true);
	UpdateCheckBox("btn_TouchToggle", touchEnable);
	ds["touch_model"] = touchEnable;
	
	-- 鼠标设置
	local mouse_select_list = Game.PlayerController:LoadRemoteData("SystemSettingsPage.mouse_select_list", nil)
	if mouse_select_list then
		CommunitySetting.mouse_select_list = mouse_select_list
	end
	
	local is_on = CommunitySetting.mouse_select_list["DeleteBlock"] == "right"
	page:SetNodeValue("ChangeMouseLeftRight", is_on);
end


--鼠标设置
function CommunitySetting.OnChangeMouseSetting(name, value)
	if CommunitySetting.mouse_select_list[name] == nil then
		return
	end
	
	local old_value = CommunitySetting.mouse_select_list[name]
	CommunitySetting.mouse_select_list[name] = value
	
	local value_to_key_list = {}
	for k, v in pairs(CommunitySetting.mouse_select_list) do
		if v == value and k ~= name then
			CommunitySetting.mouse_select_list[k] = old_value
		end

		value_to_key_list[CommunitySetting.mouse_select_list[k]] = k
	end

	CommunitySetting.RefreshPage()
	
	GameLogic.GetPlayerController():SaveRemoteData("SystemSettingsPage.mouse_select_list", CommunitySetting.mouse_select_list);
	GameLogic.options:SetMouseSettingList(value_to_key_list)
end

function CommunitySetting.GetMouseSetting(name)
	if name == nil then
		return ""
	end

	return CommunitySetting.mouse_select_list[name] or ""
end

function CommunitySetting.OnClickEnableMouseChange(value)
	page:SetNodeValue("ChangeMouseLeftRight", value);
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.setting_page.click_change_mouse_setting", {useNoId=true},nil,true);
	local change_event = value and "right" or "left"
	CommunitySetting.OnChangeMouseSetting("DeleteBlock", change_event)
end

function CommunitySetting.OnClickEnableMouseInverse()
	local cur_state = CommunitySetting.setting_ds["mouse_inverse"];
	local next_state = not cur_state;
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.setting_page.click_change_mouse_reverse", {useNoId=true},nil,true);
	UpdateCheckBox("btn_MouseInverse", next_state);
	ParaEngine.GetAttributeObject():SetField("IsMouseInverse", next_state);
	--ParaTerrain.GetBlockAttributeObject():SetField("UseWaterReflection", not value)
	CommunitySetting.setting_ds["mouse_inverse"] = next_state;
	local key = "Paracraft_System_Mouse_Inverse";
	GameLogic.GetPlayerController():SaveLocalData(key,next_state,true);
end

function CommunitySetting.OnToggleTouchModel(name)
	local cur_state = CommunitySetting.setting_ds["touch_model"];
	local next_state = not cur_state;
	if next_state then
		GameLogic.RunCommand("/show mobilepad")
	else
		GameLogic.RunCommand("/hide mobilepad")
	end
	UpdateCheckBox(name, next_state);
	CommunitySetting.setting_ds["touch_model"] = next_state;
	local key = "Paracraft_System_Touch_Model";
	GameLogic.GetPlayerController():SaveLocalData(key,next_state,true);
	local category_ds_index = CommunitySetting.category_ds_index
	CommunitySetting.OnCancel()
	CommunitySetting.category_ds_index = category_ds_index 
	commonlib.TimerManager.SetTimeout(function()
		CommunitySetting.ShowPage()
	end,100)
end

function CommunitySetting.OnCancel()
	if page then
		page:CloseWindow();
	end
end

--全屏设置
function CommunitySetting.IsFullScreenMode()
	local IsWindowMaximized = ParaEngine.GetAttributeObject():GetField("IsWindowMaximized", false)
	print("IsWindowMaximized==============", IsWindowMaximized)
	return IsWindowMaximized
end

function CommunitySetting.OnClickEnableFullScreenMode()
	local attr = ParaEngine.GetAttributeObject()
	local ds = CommunitySetting.setting_ds;
	local is_full_screen = not ds["is_full_screen"];

	UpdateCheckBox("btn_FullScreenMode", is_full_screen);
	ds["is_full_screen"] = is_full_screen;
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.setting_page.click_full_screen_mode", {useNoId=true},nil,true);
	CommunitySetting.needRefreshWithResize = true;
	attr:SetField("IsWindowMaximized",is_full_screen)
end

function CommunitySetting.OnChangeResolution()
	CommunitySetting.OnOK()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.setting_page.click_change_resolution", {useNoId=true},nil,true);
end

function CommunitySetting.OnOK()
	local bNeedUpdateScreen;
	local att = ParaEngine.GetAttributeObject();
	local ds = CommunitySetting.setting_ds;

	if(not System.options.IsWebBrowser) then
		value = page:GetValue("ScreenResolution");
		local x,y = string.match(value or "", "(%d+)%D+(%d+)");
		if(x~=nil and y~=nil) then
			x = tonumber(x)
			y = tonumber(y)
			if(x~=nil and y~=nil) then
				local size = {x, y};
				local oldsize = att:GetField("ScreenResolution", {1020,680});
				if(oldsize[1] ~=x or oldsize[2]~= y) then
					bNeedUpdateScreen = true;
				end
				if(System.options.IsWebBrowser) then
					commonlib.app_ipc.ActivateHostApp("change_resolution", nil, size[1], size[2]);
				else	
					att:SetField("ScreenResolution", size);
				end	
			end
		end
	end

	if(bNeedUpdateScreen) then
		_guihelper.MessageBox(L"您的显示设备即将改变:如果您的显卡不支持, 需要您重新登录。是否继续?", function ()
			local oldStereoMode = nil
			if GameLogic.options:IsSingleEyeOdsStereo() then
				oldStereoMode = GameLogic.options.stereoMode
				CommunitySetting.OnChangeStereoMode(nil, "0")
			end
			ParaEngine.GetAttributeObject():CallField("UpdateScreenMode");
			-- we will save to "config.new.txt", so the next time the game engine is started, it will ask the user to preserve or not. 
			ParaEngine.WriteConfigFile("config/config.new.txt");
			commonlib.TimerManager.SetTimeout(function()
				local att = ParaEngine.GetAttributeObject();
				local oldsize = att:GetField("ScreenResolution", {1280,720});
				if oldStereoMode and oldsize[2] - oldsize[1]/2>200 then
					CommunitySetting.OnChangeStereoMode(nil, oldStereoMode)
				end
			end,200)
		end)
	else
		ParaEngine.WriteConfigFile("config/config.new.txt");
	end
	page:CloseWindow();
	
end

function CommunitySetting.OnClearCache()
	GameLogic.RunCommand("/clearcache");
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.setting_page.click_clear_cache", {useNoId=true},nil,true);
end

function CommunitySetting.OnClearMemory()
	GameLogic.RunCommand("/clearmemory")
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.setting_page.click_clear_memory", {useNoId=true},nil,true);
end

function CommunitySetting.OnOpenBackupFolder()
	if GameLogic.world_revision then
		GameLogic.world_revision:OnOpenRevisionDir();
	else
		local backup_dir = ParaIO.GetWritablePath() .. "worlds/DesignHouse/backups/"
		local folder = backup_dir:gsub("[^/\\]*$", "");
		Map3DSystem.App.Commands.Call("File.WinExplorer", folder);
	end
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.setting_page.click_open_backup_folder", {useNoId=true},nil,true);
end
