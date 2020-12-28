--[[
Title: minimap UI window
Author(s): LiXizhi
Date: 2020/8/9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.lua");
local ParaWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd");
ParaWorldMinimapWnd:Show();
ParaWorldMinimapWnd:Close();
ParaWorldMinimapWnd:RefreshMap()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapSurface.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local ParaWorldMain = commonlib.gettable("Paracraft.Controls.ParaWorldMain");
local ParaWorldMinimapSurface = commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurface");
local Window = commonlib.gettable("System.Windows.Window");
local ParaWorldMinimapWnd = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldMinimapWnd"));

-- page only for surface window. Not the realtime window
local page;
local pageWnd;

function ParaWorldMinimapWnd:Show()
	if(not self.window) then
		ParaWorldMinimapWnd.nameMap = nil;
		
		local window = Window:new();
		window:EnableSelfPaint(true);
		window:SetAutoClearBackground(false);
		self.window = window;
		self.window:SetCanHaveFocus(false);

		self.window2 = Window:new();
		self.window2:SetCanHaveFocus(false);

		GameLogic.GetFilters():add_filter("OnEnterParaWorldGrid", ParaWorldMinimapWnd.OnEnterParaWorldGrid);
	end

	self.window:Show({
		name="ParaWorldMinimapWnd", 
		url="script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.html?isSurface=true",
		alignment="_rt", left=-202, top=10, width = 192, height = 220, zorder = -12
	});

	self.window2:Show({
		name="ParaWorldMinimapWnd2", 
		url="script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapWnd.html?isSurface=false",
		alignment="_rt", left=-202, top=10, width = 192, height = 248, zorder = -11
	});
end

function ParaWorldMinimapWnd.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldMinimapWnd.OnInitWnd()
	pageWnd = document:GetPageCtrl();
end

-- static function: refresh the map
-- @param delayTime: seconds to delay before refreshing. default to 0, which means refresh immediately
function ParaWorldMinimapWnd:RefreshMap(delayTime)
	delayTime = delayTime or 0;
	if(delayTime == 0) then
		if(page) then
			local ctl = page:FindControl("surface");
			if(ctl) then
				-- rebuild map
				ctl:Invalidate();
			end
		end
	else
		if(not ParaWorldMinimapWnd.refreshTimer) then
			ParaWorldMinimapWnd.refreshTimer = commonlib.Timer:new({callbackFunc = function(timer)
				ParaWorldMinimapWnd:RefreshMap(0)
			end})
		end
		ParaWorldMinimapWnd.refreshTimer:Change(math.floor(delayTime * 1000));
	end
end

function ParaWorldMinimapWnd.CloseWindow()
	local self = ParaWorldMinimapWnd
	if(self.window) then
		self.window:CloseWindow(true)
		self.window = nil;

		self.window2:CloseWindow(true)
		self.window2 = nil;
		page = nil;
		pageWnd = nil;
	end
end

function ParaWorldMinimapWnd:Close()
	ParaWorldMinimapWnd.CloseWindow()
end

function ParaWorldMinimapWnd.GetWorldName()
    return WorldCommon.GetWorldTag("name");
end

function ParaWorldMinimapWnd.OnClickSpawnpoint()
	GameLogic.RunCommand("/home")

	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.mini_map.spawn_point");
end

function ParaWorldMinimapWnd.OnLocalWorldInfo()
	--_guihelper.MessageBox(L"入驻并行世界的功能将在9.11日开放。 快去建设自己的家园吧, 将你的家园安放在大世界周围的地块中");
	if (ParaWorldLoginAdapter.ParaWorldId) then
		local ParaWorldSites = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldSites.lua");
		ParaWorldSites.ShowPage();
	else
		local generatorName = WorldCommon.GetWorldTag("world_generator");
		if (generatorName == "paraworld") then
			--_guihelper.MessageBox(L"入驻并行世界的功能将在9.17日开放。 快去建设自己的家园吧, 将你的家园安放在大世界周围的地块中");
			local ParaWorldApply = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldApply.lua");
			ParaWorldApply.ShowPage();
		elseif (generatorName == "paraworldMini") then
			_guihelper.MessageBox(L"请到并行世界中选择要入驻的大世界，在并行世界列表中可以点击进入并行世界！");
		end
	end

	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.mini_map.local_worldinfo");
end

function ParaWorldMinimapWnd.OnClickParaWorldList()
	if (not GameLogic.GetFilters():apply_filters('is_signed_in')) then
		GameLogic.GetFilters():apply_filters('show_login_page');
		return;
	end
	--_guihelper.MessageBox(L"并行世界列表将在9.11日开放。在新建世界时，选择并行世界，创建属于自己的多人联网并行世界，未来可以邀请好友入驻到你的并行世界中")
	local ParaWorldList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldList.lua");
	ParaWorldList.ShowPage();

	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.mini_map.paraworld_list");
end

function ParaWorldMinimapWnd.OnClickMapName()
	if (ParaWorldMinimapWnd.nameMap and ParaWorldMinimapWnd.userId) then
		local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
		page.ShowUserInfoPage({userId = ParaWorldMinimapWnd.userId});
	end
end

-- @param params: {projectName, x, y}
function ParaWorldMinimapWnd.OnEnterParaWorldGrid(params)
	local name = params.projectName;
	if (params.x < 7 and params.x > 4 and params.y < 7 and params.y > 4) then
		name = ParaWorldMinimapWnd.GetWorldName();
	end
	ParaWorldMinimapWnd.SetMapName(name, params.userId);
	return params;
end

function ParaWorldMinimapWnd.SetMapName(name, userId)
	if(pageWnd) then
		ParaWorldMinimapWnd.nameMap = name;
		ParaWorldMinimapWnd.userId = userId;
		pageWnd:SetValue("mapName", name or L"地图")
	end
end

function ParaWorldMinimapWnd.OnClickEnableSound()
	if (ParaAudio.GetVolume()>0) then
		ParaAudio.SetVolume(0);
	else
		ParaAudio.SetVolume(1);
	end
	if (pageWnd) then
		pageWnd:Refresh(0);
	end
end

function ParaWorldMinimapWnd.OnClickEvnTime()
	local ParaWorldEnvTime = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldEnvTime.lua");
	ParaWorldEnvTime.ShowPage();
end
