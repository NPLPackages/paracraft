--[[
Title: ParacraftLearningRoomDailyPage
Author(s): leio
Date: 2020/5/15
Desc:  
the daily page for learning paracraft
Use Lib:
-------------------------------------------------------
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
ParacraftLearningRoomDailyPage.DoCheckin();
--]]
local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local TeachingQuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.lua");

local ParacraftLearningRoomDailyPage = NPL.export()

local page;
ParacraftLearningRoomDailyPage.exid = 10001;
ParacraftLearningRoomDailyPage.gsid = 30102;
ParacraftLearningRoomDailyPage.max_cnt = 32;
ParacraftLearningRoomDailyPage.copies = 0;
ParacraftLearningRoomDailyPage.Current_Item_DS = {
}
function ParacraftLearningRoomDailyPage.OnInit()
	page = document:GetPageCtrl();
end
function ParacraftLearningRoomDailyPage.FillDays()
    local gsid = ParacraftLearningRoomDailyPage.gsid;
	local template = KeepWorkItemManager.GetItemTemplate(gsid);
	if(not template)then
		return
	end
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(gsid)

	ParacraftLearningRoomDailyPage.max_cnt = template.max or 0;
	ParacraftLearningRoomDailyPage.copies = copies or 0;

	ParacraftLearningRoomDailyPage.Current_Item_DS = {};

	for k = 1,ParacraftLearningRoomDailyPage.max_cnt do
		table.insert(ParacraftLearningRoomDailyPage.Current_Item_DS, {});
	end
end
function ParacraftLearningRoomDailyPage.OnInit()
	page = document:GetPageCtrl();
end

function ParacraftLearningRoomDailyPage.ShowPage()
	ParacraftLearningRoomDailyPage.FillDays()
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.html",
			name = "ParacraftLearningRoomDailyPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 100,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -600/2,
				y = -500/2,
				width = 600,
				height = 500,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end
function ParacraftLearningRoomDailyPage.ClosePage()
	if(page)then
		page:CloseWindow();
	end
end
function ParacraftLearningRoomDailyPage.DoCheckin(callback)
    if(not KeepWorkItemManager.GetToken())then
			_guihelper.MessageBox(L"请先登录！");
		return
	end

	local show_page = function()
        ParacraftLearningRoomDailyPage.ShowPage();

--		KeepWorkItemManager.GetFilter():remove_all_filters("loaded_all");
--		if(ParacraftLearningRoomDailyPage.HasCheckedToday())then
--			ParacraftLearningRoomDailyPage.ShowPage();
--		else
--			ParacraftLearningRoomDailyPage.FillDays();
--			local index = ParacraftLearningRoomDailyPage.GetNextDay();
--			LOG.std(nil, "debug", "ParacraftLearningRoomDailyPage.DoCheckin", index);
--			local exid = ParacraftLearningRoomDailyPage.exid;
--			KeepWorkItemManager.DoExtendedCost(exid, function()
--				ParacraftLearningRoomDailyPage.SaveToLocal();
--				_guihelper.MessageBox(L"签到成功。关闭窗口后将自动播放今日学习视频。", function(res)
--					ParacraftLearningRoomDailyPage.OnOpenWeb(index)
--				end, _guihelper.MessageBoxButtons.OK);    
--			end, function()
--				ParacraftLearningRoomDailyPage.ShowPage();
--			end)
--
--			
--		end
	end
	if(not KeepWorkItemManager.IsLoaded())then
		KeepWorkItemManager.GetFilter():add_filter("loaded_all", show_page);
		return
	end
	show_page();
end
function ParacraftLearningRoomDailyPage.OnCheckinToday()
    local index = ParacraftLearningRoomDailyPage.GetNextDay();
	LOG.std(nil, "debug", "ParacraftLearningRoomDailyPage.OnCheckinToday", index);
	ParacraftLearningRoomDailyPage.ClosePage();
	local exid = ParacraftLearningRoomDailyPage.exid;
	KeepWorkItemManager.DoExtendedCost(exid, function()
		ParacraftLearningRoomDailyPage.SaveToLocal();
		_guihelper.MessageBox(L"今日签到成功，自动获得4个知识豆。关闭窗口后将自动播放今日学习视频。", function(res)
			ParacraftLearningRoomDailyPage.OnOpenWeb(index)
		end, _guihelper.MessageBoxButtons.OK);    
	end, function()
		_guihelper.MessageBox(L"签到失败！");
	end)
end
function ParacraftLearningRoomDailyPage.IsVip()
	local gsid = 10;
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(gsid)
	return (copies and copies > 0);
end
function ParacraftLearningRoomDailyPage.GetNextDay()
	local copies = ParacraftLearningRoomDailyPage.copies or 0;
	if(not ParacraftLearningRoomDailyPage.HasCheckedToday())then
		copies = copies + 1;
	end
	return copies;
end
function ParacraftLearningRoomDailyPage.IsNextDay(index)
	return index == ParacraftLearningRoomDailyPage.GetNextDay();
end
function ParacraftLearningRoomDailyPage.IsFuture(index)
	if(index > ParacraftLearningRoomDailyPage.GetNextDay() )then
		return true;
	end
end
function ParacraftLearningRoomDailyPage.HasCheckedToday()
    -- for red tip, hide tip before data loaded
    if(not KeepWorkItemManager.IsLoaded())then
		return true
	end
	local date = ParaGlobal.GetDateFormat("yyyy-M-d");
	local key = string.format("LearningRoom_HasCheckedToday_%s", date);
	local gsid = ParacraftLearningRoomDailyPage.gsid;
	local clientData = KeepWorkItemManager.GetClientData(gsid) or {};
	return clientData[key];
end
function ParacraftLearningRoomDailyPage.SaveToLocal()
	local date = ParaGlobal.GetDateFormat("yyyy-M-d");
	local key = string.format("LearningRoom_HasCheckedToday_%s", date);
	local gsid = ParacraftLearningRoomDailyPage.gsid;
	local clientData = KeepWorkItemManager.GetClientData(gsid) or {};
	clientData[key] = true;
    for k, v in pairs(clientData) do
        if(k ~= key)then
	        clientData[k] = nil; -- clear other days
        end
    end
	KeepWorkItemManager.SetClientData(gsid, clientData)
end
function ParacraftLearningRoomDailyPage.OnOpenWeb(index,bCheckVip)
	index = tonumber(index)
	if(bCheckVip and not ParacraftLearningRoomDailyPage.IsVip())then
		if(ParacraftLearningRoomDailyPage.IsFuture(index))then
			return
		end
	end
    if(index < 1)then
        index = 1;
    end
	LOG.std(nil, "debug", "ParacraftLearningRoomDailyPage.OnOpenWeb", index);
	local url = string.format("https://keepwork.com/official/tips/s1/1_%d",index);
	NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Show(url, "", false, true, nil, function(state)
		if(state == "ONCLOSE")then
            NplBrowserManager:CreateOrGet("DailyCheckBrowser"):GotoEmpty();
		end
	end);
end
function ParacraftLearningRoomDailyPage.OnLearningLand()
	if(not KeepWorkItemManager.GetToken())then
		_guihelper.MessageBox(L"请先登录！");
		return
	end

	local learning = function()
		KeepWorkItemManager.GetFilter():remove_all_filters("loaded_all");
		local template = KeepWorkItemManager.GetItemTemplate(TeachingQuestPage.totalTaskGsid);
		if (template) then
			if (TeachingQuestPage.MainWorldId == nil) then
				-- TeachingQuestPage.MainWorldId = template.extension;
				TeachingQuestPage.MainWorldId = tostring(template.desc);
			end
			local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
			UserConsole:HandleWorldId(TeachingQuestPage.MainWorldId, "force");
		end
	end
	if(not KeepWorkItemManager.IsLoaded())then
		KeepWorkItemManager.GetFilter():add_filter("loaded_all", learning);
		return
	end

	learning();
end
function ParacraftLearningRoomDailyPage.OnVIP()
	ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/vip", "", 1); 
end