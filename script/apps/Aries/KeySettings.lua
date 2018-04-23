--[[
Title: code behind for KeySettings
Author(s): WD
Date: 2011/11/24

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/KeySettings.lua");
MyCompany.Aries.Desktop.KeySettings.ShowPage();
--]]
NPL.load("(gl)script/ide/timer.lua");
local KeySettings = commonlib.gettable("MyCompany.Aries.Desktop.KeySettings");

local KEY_SETTINGS_DEFAULT_FILE = "config/Aries/Others/key_settings_default.csv";
local KEY_SETTINGS_FILE = "config/Aries/Others/key_settings.csv";

 
 local table_insert = table.insert;
 local str_match = string.match;
 local echo = commonlib.echo;
 local toupper = string.upper
 local MSG = _guihelper.MessageBox;

 KeySettings.Shortcuts = {};
 KeySettings.DisplayItems = {};
 KeySettings.ischanged = false;
 KeySettings.ExcludeKeys = {"W","A","S","D","Q","E","SPACE"};

 --[[
 local key_to_cmd_map = {
	["c"] = "ProfilePane.ShowPage",--人物
	["z"] = "PetPage.ShowPage",--坐骑
	["p"] = "CombatPetPane.ShowPage",--宠物
	["b"] = "CharacterBagPage.ShowPage",--背包
	["v"] = "CombatCardTeen",--技能
	["l"] = "QuestPane.ShowPage",--任务
	["t"] = "LobbyClientServicePage.ShowPage",--组队
	["f"] = "FriendsPage.ShowPage",--好友
	["j"] = "FamilyMembersPage.ShowPage",--家族
	["h"] = "AutoTip",--帮助
	["m"] = "Aries.LocalMapMCML",--地图
	["toggleplayers"] = "ToggleRenderOtherPlayer",
}
 ]]


 --[[
forward,前行,W
backward,后退,S
rotate_left,左看,D
rotate_right,右看,A
trans_left,左移,Q
trans_right,右移,E
jump,跳跃,SPACE
bag,背包,B
character,角色,C
vehicle,坐骑,Z
pet,宠物,P
skill,技能,V
mission,任务,L
team,组队,T
friend,好友,F
family,家族,J
map,地图,M
 ]]
 KeySettings.key_mapping = 
 {
	bag = {func="CharacterBagPage.ShowPage",shortcuts="B"},
	character ={func = "ProfilePane.ShowPage",shortcuts="C"},
	--vehicle = {func="PetPage.ShowPage",shortcuts="Z"},
	pet = {func="CombatFollowPetPane.ShowPage",shortcuts="P"},
	skill = {func="CombatCardTeen",shortcuts="V"},
	mission = {func="QuestPane.ShowPage",shortcuts="L"},
	team = {func="LobbyClientServicePage.ShowPage",shortcuts="T"},
	friend = {func="FriendsPage.ShowPage",shortcuts="O"},
	family ={func="FamilyMembersPage.ShowPage",shortcuts="J"},
	map ={func="Aries.LocalMapMCML",shortcuts="M"},

 }

 function KeySettings.GetFunc(shortcuts)
	--if(not shortcuts)then return end
	local k,v,func;
	for k,v in pairs(KeySettings.key_mapping)do
		if(v.shortcuts == toupper(shortcuts))then
			func = v.func;
			break;
		end
	end
	return func;
 end
 --load settings and translate to mapping table.
 function KeySettings.LoadSettings()
	KeySettings:LoadCfg();
	local current_settings = KeySettings.DisplayItems;
	local key_mapping = KeySettings.key_mapping;
	local i,v,k,v1;
	for i,v in ipairs(current_settings)do
		for k,v1 in pairs(key_mapping)do
			if(v.key == k)then
				if(v1.shortcuts  ~= v.shortcuts)then
					v1.shortcuts  = v.shortcuts;
				end
				break;
			end
		end
	end
 end

function KeySettings:Init()
	self.page = document.GetPageCtrl();
end
 
function KeySettings.ShowPage()
	local width,height = 350,470;
	KeySettings:LoadCfg();
	

	local params = {
        url = "script/apps/Aries/Desktop/KeySettings.html", 
        app_key = MyCompany.Aries.app.app_key, 
        name = "KeySettings.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
		enable_esc_key = true,
        allowDrag = true,
		isTopLevel = false,
        directPosition = true,
        align = "_ct",
		x = -width * .5,
		y = -height * .5,
        width = width,
        height = height,}
    System.App.Commands.Call("File.MCMLWindowFrame", params);
	if(params._page)then
		params._page.OnClose = KeySettings.Clean;
	end
	
	KeySettings.timer = KeySettings.timer or commonlib.Timer:new({callbackFunc = function(timer) 
			local keys = {};
			local key,v;

			for key,v in pairs(DIK_SCANCODE) do
				if(ParaUI.IsKeyPressed(v))then
					keys[key] = v;	
				end
			end

			KeySettings:ConversionKey(keys);
			
			end});

	KeySettings.timer:Change(100,300);

end

function KeySettings:CreateSettingsFile(check)
	local fileObj = ParaIO.open(KEY_SETTINGS_FILE, "w");

	if(fileObj and fileObj:IsValid()) then
		fileObj:close();
	end
end

function KeySettings:LoadCfg()
	
	if(not self.isCfgLoaded)then 
		local file1 = ParaIO.open(KEY_SETTINGS_DEFAULT_FILE, "r");
		self.Shortcuts = {};

		if(file1 and file1:IsValid())then
			local strValue = file1:readline();

			while(strValue)do
				local str;
				local item = {};
				for str in string.gfind(strValue, "([^,]+)") do
					table_insert(item,str);
				end

				if(item[1] and item[2] and item[3])then
					table_insert(self.Shortcuts,{key = item[1],text = item[2],shortcuts = item[3],is_selected=false,});
				else
					echo("pls check settings file.");
				end
			
				strValue = file1:readline();
			end
			file1:close();
		end
	
		self.isCfgLoaded = true;
	end
	--echo(self.Shortcuts);

	local file;
	self.ChangedShortcuts = {};
	--if user config file notexist,then create it.
	if(ParaIO.DoesFileExist(KEY_SETTINGS_FILE,false) == false) then
		file = ParaIO.open(KEY_SETTINGS_FILE, "w");
		if(file and file:IsValid()) then
			file:WriteBytes(3,{239,187,191});
			file:close();
		end

	else
			--load key settings of user preference
			file = ParaIO.open(KEY_SETTINGS_FILE, "r");
			if(file and file:IsValid())then
				local strValue = file:readline();
	
				while(strValue)do
					if(strValue ~= "")then
						local key,shortcuts,str;
						local item = {};
						for str in string.gfind(strValue, "([^,]+)") do
							table_insert(item,str);
						end

						if(item[1] and item[2])then
							table_insert(self.ChangedShortcuts,{key = item[1],shortcuts = item[2]});
						else
							echo("check file " .. KEY_SETTINGS_FILE);
						end
					end

					strValue = file:readline();
				end
				file:close();
			end
	end

	--echo(self.ChangedShortcuts);
	self.DisplayItems = commonlib.deepcopy(self.Shortcuts);

	local i,v,i1,v1;

	for i,v in ipairs(self.ChangedShortcuts )do
		for i1,v1 in ipairs(self.DisplayItems)do
			if(v.key == v1.key and v.shortcuts)then
				v1.shortcuts = v.shortcuts;
				break;
			end
		end
	end
	--echo(self.DisplayItems);
end

function KeySettings.Clean()
	KeySettings.ischanged = false;
	KeySettings.LoadSettings();
	KeySettings.is_toggled = nil;
	KeySettings.timer:Change();
end

function KeySettings:Refresh(delta)
	if(self.page)then
		self.page:Refresh(delta or 0.1);
	end
end

function KeySettings.CloseWindow()
	if(KeySettings.page)then
		KeySettings.page:CloseWindow();
	end
end

function KeySettings:OnClickItem(arg)
	local i,v;
	for i,v in ipairs(self.DisplayItems)do
		if(v.key == arg)then
			v.is_selected = true;
			
		else
			v.is_selected = false;
		end
	end
	self.is_toggled = self.is_toggled or true;
	KeySettings.UpdateDataSource();
end

function KeySettings:ConversionKey(keys)
	if(not keys)then return end
	if(not self.is_toggled)then return end

	local s = "";

	local ctrl_pressed;
	local alt_pressed;
	local shift_pressed;
	local char = "";
	local key,v;
	for key,v in pairs(keys) do
		if(v == DIK_SCANCODE.DIK_LCONTROL or v == DIK_SCANCODE.DIK_RCONTROL)then
			ctrl_pressed = true;
		elseif(v == DIK_SCANCODE.DIK_LMENU or v == DIK_SCANCODE.DIK_RMENU)then
			alt_pressed = true;
		elseif(v == DIK_SCANCODE.DIK_LSHIFT or v == DIK_SCANCODE.DIK_RSHIFT)then
			shift_pressed = true;
		else
			local __,__,__,_char = string.find(key,"(.+)_(.+)");
			char = _char;
		end
	end
	if(ctrl_pressed)then
		s  = s .."Ctrl+";
	end
	if(alt_pressed)then
		s  = s .."Alt+";
	end
	if(shift_pressed)then
		s  = s .."Shift+";
	end
	if(char)then
		s  = s ..char;
	end
	
	local i1,v1;
	for i1,v1 in ipairs(self.DisplayItems)do
		if(s == v1.shortcuts and not KeySettings.IsExcludeKeys(v1.shortcuts))then
			MSG("按键已经被使用,请设置其他键.");
			return;
		end
	end

	for i1,v1 in ipairs(self.DisplayItems)do
		if(v1.is_selected and s ~= "" and v1.shortcuts ~= s and not KeySettings.IsExcludeKeys(v1.shortcuts))then
			v1.shortcuts = s ;
			KeySettings.ischanged = true;
			KeySettings.UpdateDataSource();
			break;
		end
	end

	local len = #keys;
	if(len > 1)then
		return true;
	end
end

function KeySettings.IsExcludeKeys(key)
	local i,v;
	for i,v in ipairs(KeySettings.ExcludeKeys)do
		if(v == key)then
			return true;
		end
	end
	return false;
end

function KeySettings:IsVisible()
	if(self.page and self.page:IsVisible()) then
		return true;
	end
end
--save modify history
function KeySettings.ConfirmModify()
	if(not KeySettings.ischanged)then return end
	local fileObj = ParaIO.open(KEY_SETTINGS_FILE, "w");

	if(fileObj and fileObj:IsValid()) then
		local i,v,i1,v1
		local content = "";
		for i,v in ipairs(KeySettings.DisplayItems )do
			for i1,v1 in ipairs(KeySettings.Shortcuts)do
				if(v.key == v1.key and v.shortcuts ~= v1.shortcuts)then
					content = content .. string.format("%s,%s\n",v.key,v.shortcuts);
					break;
				end
			end
		end

		local length = string.len(content);

		fileObj:write(content,length);
		
		fileObj:close();
	end
end

--restore default config
function KeySettings.RestoreDefault()
	KeySettings:CreateSettingsFile();
	KeySettings:LoadCfg();
	KeySettings.UpdateDataSource();
end

function KeySettings.UpdateDataSource()
	KeySettings.page:CallMethod("pegvwShortcuts","SetDataSource",KeySettings.DisplayItems);
	KeySettings.page:CallMethod("pegvwShortcuts","DataBind")
end

function KeySettings:GetDataSource(index)

	if(index == nil) then
		return #self.DisplayItems;
	else
		return self.DisplayItems[index];
	end
end